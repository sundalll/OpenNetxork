import SwiftUI

public class MusicViewModel: ObservableObject {
    @Published public var tracks: [Track] = []
    @Published public var albums: [Album] = []
    @Published public var playlists: [Playlist] = []
    @Published public var isLoading: Bool = false

    public init() {
        loadTracks()
    }

    public func loadTracks() {
        self.isLoading = true
        Task {
            do {
                let fetchedTracks: [Track] = try await NetworkManager.shared.request(endpoint: "music.php")
                await MainActor.run {
                    self.tracks = fetchedTracks
                    self.isLoading = false
                }
            } catch {
                await MainActor.run { self.isLoading = false }
            }
        }
    }

    public func uploadNewTrack(title: String, artist: String, album: String, audioUrl: String, coverUrl: String) async -> Bool {
        let body: [String: Any] = [
            "title": title,
            "artist": artist,
            "album_name": album,
            "audio_url": audioUrl,
            "cover_url": coverUrl
        ]

        do {
            let response: APIResponse<Track> = try await NetworkManager.shared.request(endpoint: "music_upload.php", method: "POST", jsonBody: body)
            if response.success, let newTrack = response.data {
                await MainActor.run {
                    self.tracks.insert(newTrack, at: 0)
                }
                return true
            }
            return false
        } catch {
            return false
        }
    }

    public func toggleLike(track: Track) {
        if let idx = tracks.firstIndex(where: { $0.id == track.id }) {
            tracks[idx].isLiked.toggle()
        }
    }

    public func createPlaylist(name: String, description: String) {
        let newPlaylist = Playlist(id: Int.random(in: 100...999), name: name, description: description)
        playlists.insert(newPlaylist, at: 0)
    }
}

public struct LyricsView: View {
    public let track: Track
    @Environment(\.presentationMode) var presentationMode
    
    public init(track: Track) {
        self.track = track
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            Capsule()
                .fill(Color.gray.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 12)

            Text("Текст песни")
                .font(.system(size: 18, weight: .bold))

            Text(track.title)
                .font(.system(size: 14))
                .foregroundColor(.secondary)

            Divider()

            ScrollView {
                Text(track.lyrics ?? "Текст для этой песни не добавлен.")
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .lineSpacing(10)
                    .multilineTextAlignment(.center)
                    .padding(24)
            }

            Spacer()
        }
        .background(Color(UIColor.systemBackground).ignoresSafeArea())
    }
}

public struct UploadTrackView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: MusicViewModel

    @State private var title: String = ""
    @State private var artist: String = ""
    @State private var album: String = ""
    @State private var audioUrl: String = ""
    @State private var coverUrl: String = ""
    @State private var showAudioPicker: Bool = false
    @State private var showCoverPicker: Bool = false
    @State private var coverImage: UIImage? = nil
    @State private var isUploadingAudio: Bool = false
    @State private var isUploadingCover: Bool = false
    @State private var isSubmitting: Bool = false

    public init(viewModel: MusicViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Информация о треке")) {
                    TextField("Название трека", text: $title)
                    TextField("Исполнитель / Автор", text: $artist)
                    TextField("Альбом (необязательно)", text: $album)
                }

                Section(header: Text("Файл музыки (выбор с телефона)")) {
                    HStack {
                        Button(action: { showAudioPicker = true }) {
                            HStack {
                                Image(systemName: "music.note")
                                Text(audioUrl.isEmpty ? "Выбрать аудиофайл с телефона" : "Аудиофайл загружен ✓")
                                    .font(.system(size: 14, weight: .bold))
                            }
                        }
                        if isUploadingAudio { ProgressView() }
                    }

                    if !audioUrl.isEmpty {
                        Text("Файл: \(audioUrl)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Section(header: Text("Обложка трека (с телефона)")) {
                    HStack {
                        Button(action: { showCoverPicker = true }) {
                            HStack {
                                Image(systemName: "photo.on.rectangle")
                                Text(coverUrl.isEmpty ? "Выбрать обложку с телефона" : "Обложка загружена ✓")
                                    .font(.system(size: 14, weight: .bold))
                            }
                        }
                        if isUploadingCover { ProgressView() }
                    }
                }
            }
            .navigationBarTitle("Загрузить трек", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Отмена") { presentationMode.wrappedValue.dismiss() },
                trailing: Button("Сохранить") {
                    Task {
                        isSubmitting = true
                        let success = await viewModel.uploadNewTrack(title: title, artist: artist, album: album, audioUrl: audioUrl, coverUrl: coverUrl)
                        isSubmitting = false
                        if success {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
                .font(.system(size: 16, weight: .bold))
                .disabled(title.isEmpty || artist.isEmpty || audioUrl.isEmpty || isSubmitting)
            )
            .sheet(isPresented: $showAudioPicker) {
                DocumentPicker { fileURL in
                    Task {
                        isUploadingAudio = true
                        if let url = try? await NetworkManager.shared.uploadFile(fileURL: fileURL) {
                            audioUrl = url
                        }
                        isUploadingAudio = false
                    }
                }
            }
            .sheet(isPresented: $showCoverPicker) {
                ImagePicker(selectedImage: $coverImage) { img in
                    Task {
                        isUploadingCover = true
                        if let url = try? await NetworkManager.shared.uploadImage(uiImage: img) {
                            coverUrl = url
                        }
                        isUploadingCover = false
                    }
                }
            }
        }
    }
}

public struct MusicView: View {
    @StateObject private var viewModel = MusicViewModel()
    @ObservedObject private var playerManager = AudioPlayerManager.shared
    @State private var selectedSegment: Int = 0
    @State private var showUploadModal: Bool = false
    @State private var showCreatePlaylistModal: Bool = false
    @State private var newPlaylistName: String = ""
    @State private var newPlaylistDesc: String = ""
    @State private var searchText: String = ""

    var filteredTracks: [Track] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return viewModel.tracks
        } else {
            let query = searchText.lowercased()
            return viewModel.tracks.filter {
                $0.title.lowercased().contains(query) || $0.artist.lowercased().contains(query)
            }
        }
    }

    public init() {}

    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Поиск трека или исполнителя...", text: $searchText)
                        .autocapitalization(.none)
                }
                .padding(10)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal, 16)
                .padding(.top, 8)

                Picker("", selection: $selectedSegment) {
                    Text("Все треки").tag(0)
                    Text("Альбомы").tag(1)
                    Text("Плейлисты").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                if selectedSegment == 0 {
                    List {
                        Section(header: HStack {
                            Text("Музыка (MP3, WAV, FLAC)")
                            Spacer()
                            Button("+ Загрузить трек") {
                                showUploadModal = true
                            }
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.blue)
                        }) {
                            if filteredTracks.isEmpty {
                                Text(searchText.isEmpty ? "Пока нет загруженных треков. Нажмите '+ Загрузить трек', чтобы добавить первый трек!" : "Ничего не найдено по запросу '\(searchText)'")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 14))
                                    .padding(.vertical, 12)
                            } else {
                                ForEach(filteredTracks) { track in
                                    HStack(spacing: 12) {
                                        if let coverUrl = track.coverUrl, let url = URL(string: coverUrl) {
                                            if #available(iOS 15.0, *) {
                                                AsyncImage(url: url) { img in
                                                    img.resizable().scaledToFill()
                                                } placeholder: {
                                                    Color.gray.opacity(0.3)
                                                }
                                                .frame(width: 48, height: 48)
                                                .cornerRadius(8)
                                            } else {
                                                Image(systemName: "music.note")
                                                    .frame(width: 48, height: 48)
                                                    .background(Color.blue.opacity(0.2))
                                                    .cornerRadius(8)
                                            }
                                        } else {
                                            Image(systemName: "music.note")
                                                .frame(width: 48, height: 48)
                                                .background(Color.blue.opacity(0.2))
                                                .cornerRadius(8)
                                        }

                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(track.title)
                                                .font(.system(size: 15, weight: .semibold))
                                            Text(track.artist)
                                                .font(.system(size: 13))
                                                .foregroundColor(.secondary)
                                        }

                                        Spacer()

                                        Text(track.durationFormatted)
                                            .font(.system(size: 13))
                                            .foregroundColor(.secondary)

                                        Button(action: {
                                            viewModel.toggleLike(track: track)
                                        }) {
                                            Image(systemName: track.isLiked ? "heart.fill" : "heart")
                                                .foregroundColor(track.isLiked ? .red : .gray)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        playerManager.play(track: track)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                } else if selectedSegment == 1 {
                    List {
                        Section(header: Text("Музыкальные Альбомы")) {
                            if viewModel.albums.isEmpty {
                                Text("Альбомы отсутствуют. Загрузите треки с указанием альбома!")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 14))
                                    .padding(.vertical, 12)
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                } else if selectedSegment == 2 {
                    List {
                        Section(header: HStack {
                            Text("Мои Плейлисты")
                            Spacer()
                            Button("+ Создать") {
                                showCreatePlaylistModal = true
                            }
                            .font(.system(size: 13, weight: .bold))
                        }) {
                            ForEach(viewModel.playlists) { playlist in
                                HStack(spacing: 14) {
                                    Image(systemName: "music.note.list")
                                        .font(.system(size: 24))
                                        .foregroundColor(.blue)
                                        .frame(width: 52, height: 52)
                                        .background(Color.blue.opacity(0.15))
                                        .cornerRadius(10)

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(playlist.name)
                                            .font(.system(size: 16, weight: .bold))
                                        Text(playlist.description)
                                            .font(.system(size: 13))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationBarTitle("Музыка")
            .sheet(isPresented: $showUploadModal) {
                UploadTrackView(viewModel: viewModel)
            }
        }
    }
}
