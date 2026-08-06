import SwiftUI

public class MusicViewModel: ObservableObject {
    @Published public var tracks: [Track] = []
    @Published public var albums: [Album] = []
    @Published public var playlists: [Playlist] = []
    @Published public var favoriteTracks: [Track] = []
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
                    self.extractAlbums()
                    self.isLoading = false
                }
            } catch {
                await MainActor.run { self.isLoading = false }
            }
        }
    }

    private func extractAlbums() {
        var albumDict: [String: [Track]] = [:]
        for track in tracks {
            if let albumName = track.albumName, !albumName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                albumDict[albumName, default: []].append(track)
            }
        }

        self.albums = albumDict.enumerated().map { (index, item) in
            Album(
                id: index + 1,
                title: item.key,
                artist: item.value.first?.artist ?? "Исполнитель",
                coverUrl: item.value.first?.coverUrl,
                releaseYear: "2026",
                tracks: item.value
            )
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
                    self.extractAlbums()
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
            if tracks[idx].isLiked {
                if !favoriteTracks.contains(where: { $0.id == track.id }) {
                    favoriteTracks.append(tracks[idx])
                }
            } else {
                favoriteTracks.removeAll(where: { $0.id == track.id })
            }
        }
    }

    public func createPlaylist(name: String, description: String, coverUrl: String?, isPublic: Bool) {
        let randomSlug = String((0..<10).map { _ in "abcdefghijklmnopqrstuvwxyz0123456789".randomElement()! })
        let shareUrl = isPublic ? "https://myrlika.bond/pl/\(randomSlug)" : nil

        let newPlaylist = Playlist(
            id: Int.random(in: 1000...9999),
            name: name,
            description: description,
            coverUrl: coverUrl,
            isPublic: isPublic,
            shareUrl: shareUrl,
            tracks: []
        )
        playlists.insert(newPlaylist, at: 0)
    }

    public func addTrackToPlaylist(track: Track, playlistId: Int) {
        if let idx = playlists.firstIndex(where: { $0.id == playlistId }) {
            if !playlists[idx].tracks.contains(where: { $0.id == track.id }) {
                playlists[idx].tracks.append(track)
            }
        }
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
                        if success { presentationMode.wrappedValue.dismiss() }
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

public struct AddToPlaylistModalView: View {
    @Environment(\.presentationMode) var presentationMode
    public let track: Track
    @ObservedObject var viewModel: MusicViewModel

    public init(track: Track, viewModel: MusicViewModel) {
        self.track = track
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationView {
            List {
                if viewModel.playlists.isEmpty {
                    Text("У вас пока нет созданных плейлистов. Создайте плейлист во вкладке 'Плейлисты'!")
                        .foregroundColor(.secondary)
                        .padding(.vertical, 20)
                } else {
                    ForEach(viewModel.playlists) { playlist in
                        Button(action: {
                            viewModel.addTrackToPlaylist(track: track, playlistId: playlist.id)
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "music.note.list")
                                    .font(.system(size: 20))
                                    .foregroundColor(.blue)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(playlist.name)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.primary)
                                    Text("\(playlist.tracks.count) треков • \(playlist.isPublic ? "Публичный 🌐" : "Приватный 🔒")")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationBarTitle("Добавить в плейлист", displayMode: .inline)
            .navigationBarItems(trailing: Button("Закрыть") { presentationMode.wrappedValue.dismiss() })
        }
    }
}

public struct MusicPlayerView: View {
    public let track: Track
    @ObservedObject var playerManager = AudioPlayerManager.shared
    @Environment(\.presentationMode) var presentationMode
    @State private var showLyrics: Bool = false
    
    public init(track: Track) {
        self.track = track
    }

    public var body: some View {
        VStack(spacing: 24) {
            Capsule()
                .fill(Color.gray.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 12)

            Spacer()

            if let coverUrl = track.coverUrl, let url = URL(string: coverUrl) {
                if #available(iOS 15.0, *) {
                    AsyncImage(url: url) { img in
                        img.resizable().scaledToFill()
                    } placeholder: {
                        Rectangle().fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 260, height: 260)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 8)
                } else {
                    Image(systemName: "music.note")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                        .frame(width: 260, height: 260)
                        .background(Color.blue.opacity(0.15))
                        .cornerRadius(20)
                }
            } else {
                Image(systemName: "music.note")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                    .frame(width: 260, height: 260)
                    .background(Color.blue.opacity(0.15))
                    .cornerRadius(20)
            }

            VStack(spacing: 6) {
                Text(track.title)
                    .font(.system(size: 22, weight: .bold))
                    .multilineTextAlignment(.center)
                
                Text(track.artist)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                
                if let album = track.albumName {
                    Text("Альбом: \(album)")
                        .font(.system(size: 13))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 24)

            // Progress Slider
            VStack(spacing: 6) {
                Slider(value: Binding(
                    get: { playerManager.currentTime },
                    set: { newValue in playerManager.seek(to: newValue) }
                ), in: 0...(playerManager.duration > 0 ? playerManager.duration : Double(max(1, track.durationSeconds))))
                .accentColor(.blue)
                
                HStack {
                    Text(formatTime(playerManager.currentTime))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(track.durationFormatted)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 32)

            // Controls & Lyrics
            HStack(spacing: 36) {
                Button(action: {
                    showLyrics = true
                }) {
                    Image(systemName: "quote.bubble.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.blue)
                }

                Button(action: {}) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 26))
                        .foregroundColor(.primary)
                }

                Button(action: {
                    playerManager.togglePlayPause()
                }) {
                    Image(systemName: playerManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.blue)
                }

                Button(action: {}) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 26))
                        .foregroundColor(.primary)
                }

                Button(action: {}) {
                    Image(systemName: track.isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 22))
                        .foregroundColor(track.isLiked ? .red : .primary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .background(Color(UIColor.systemBackground).ignoresSafeArea())
        .sheet(isPresented: $showLyrics) {
            LyricsView(track: track)
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        let totalSeconds = Int(seconds)
        let mins = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

public struct MusicView: View {
    @StateObject private var viewModel = MusicViewModel()
    @ObservedObject private var playerManager = AudioPlayerManager.shared
    @State private var selectedSegment: Int = 0
    @State private var showUploadModal: Bool = false
    @State private var showCreatePlaylistModal: Bool = false
    @State private var selectedTrackForPlaylist: Track? = nil

    // Playlist form states
    @State private var newPlaylistName: String = ""
    @State private var newPlaylistDesc: String = ""
    @State private var newPlaylistCoverUrl: String = ""
    @State private var newPlaylistIsPublic: Bool = true
    @State private var showPlaylistCoverPicker: Bool = false
    @State private var playlistCoverImage: UIImage? = nil
    @State private var isUploadingPlaylistCover: Bool = false
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

                                        Button(action: {
                                            selectedTrackForPlaylist = track
                                        }) {
                                            Image(systemName: "plus.square.fill.on.square.fill")
                                                .foregroundColor(.blue)
                                        }
                                        .buttonStyle(PlainButtonStyle())

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
                                Text("Альбомы отсутствуют. Загрузите треки с указанием названия альбома!")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 14))
                                    .padding(.vertical, 12)
                            } else {
                                ForEach(viewModel.albums) { album in
                                    HStack(spacing: 14) {
                                        Image(systemName: "opticaldisc")
                                            .font(.system(size: 28))
                                            .foregroundColor(.purple)
                                            .frame(width: 52, height: 52)
                                            .background(Color.purple.opacity(0.15))
                                            .cornerRadius(10)

                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(album.title)
                                                .font(.system(size: 16, weight: .bold))
                                            Text("\(album.artist) • \(album.tracks.count) треков")
                                                .font(.system(size: 13))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                } else if selectedSegment == 2 {
                    VStack(spacing: 0) {
                        HStack {
                            Text("Мои Плейлисты")
                                .font(.system(size: 16, weight: .bold))
                            Spacer()
                            Button(action: {
                                showCreatePlaylistModal = true
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Создать плейлист")
                                }
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color.blue)
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)

                        List {
                            if viewModel.playlists.isEmpty {
                                Text("У вас пока нет созданных плейлистов. Нажмите 'Создать плейлист' вышe!")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 14))
                                    .padding(.vertical, 20)
                            } else {
                                ForEach(viewModel.playlists) { playlist in
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack(spacing: 14) {
                                            if let coverUrl = playlist.coverUrl, let url = URL(string: coverUrl) {
                                                if #available(iOS 15.0, *) {
                                                    AsyncImage(url: url) { img in
                                                        img.resizable().scaledToFill()
                                                    } placeholder: {
                                                        Color.gray.opacity(0.3)
                                                    }
                                                    .frame(width: 56, height: 56)
                                                    .cornerRadius(10)
                                                } else {
                                                    Image(systemName: "music.note.list")
                                                        .frame(width: 56, height: 56)
                                                        .background(Color.blue.opacity(0.15))
                                                        .cornerRadius(10)
                                                }
                                            } else {
                                                Image(systemName: "music.note.list")
                                                    .font(.system(size: 24))
                                                    .foregroundColor(.blue)
                                                    .frame(width: 56, height: 56)
                                                    .background(Color.blue.opacity(0.15))
                                                    .cornerRadius(10)
                                            }

                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(playlist.name)
                                                    .font(.system(size: 16, weight: .bold))
                                                Text(playlist.description)
                                                    .font(.system(size: 13))
                                                    .foregroundColor(.secondary)
                                                
                                                HStack(spacing: 8) {
                                                    Text(playlist.isPublic ? "🌐 Публичный" : "🔒 Приватный")
                                                        .font(.system(size: 11, weight: .semibold))
                                                        .foregroundColor(playlist.isPublic ? .green : .orange)

                                                    Text("• \(playlist.tracks.count) треков")
                                                        .font(.system(size: 11))
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                        }

                                        if let shareUrl = playlist.shareUrl, playlist.isPublic {
                                            HStack {
                                                Text("Ссылка: \(shareUrl)")
                                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                                    .foregroundColor(.blue)
                                                    .lineLimit(1)
                                                Spacer()
                                                Button("Копировать") {
                                                    UIPasteboard.general.string = shareUrl
                                                }
                                                .font(.system(size: 11, weight: .bold))
                                            }
                                            .padding(6)
                                            .background(Color.blue.opacity(0.08))
                                            .cornerRadius(6)
                                        }
                                    }
                                    .padding(.vertical, 6)
                                }
                            }
                        }
                        .listStyle(InsetGroupedListStyle())
                    }
                }
            }
            .navigationBarTitle("Музыка")
            .sheet(isPresented: $showUploadModal) {
                UploadTrackView(viewModel: viewModel)
            }
            .sheet(item: $selectedTrackForPlaylist) { track in
                AddToPlaylistModalView(track: track, viewModel: viewModel)
            }
            .sheet(isPresented: $showCreatePlaylistModal) {
                NavigationView {
                    Form {
                        Section(header: Text("Параметры плейлиста")) {
                            TextField("Название плейлиста", text: $newPlaylistName)
                            TextField("Описание", text: $newPlaylistDesc)
                            Toggle("Публичный доступ (по ссылке)", isOn: $newPlaylistIsPublic)
                        }

                        Section(header: Text("Обложка плейлиста (с телефона)")) {
                            HStack {
                                Button(action: { showPlaylistCoverPicker = true }) {
                                    HStack {
                                        Image(systemName: "photo")
                                        Text(newPlaylistCoverUrl.isEmpty ? "Выбрать обложку с телефона" : "Обложка загружена ✓")
                                            .font(.system(size: 14, weight: .bold))
                                    }
                                }
                                if isUploadingPlaylistCover { ProgressView() }
                            }
                        }
                    }
                    .navigationBarTitle("Новый плейлист", displayMode: .inline)
                    .navigationBarItems(
                        leading: Button("Отмена") { showCreatePlaylistModal = false },
                        trailing: Button("Создать") {
                            viewModel.createPlaylist(
                                name: newPlaylistName,
                                description: newPlaylistDesc,
                                coverUrl: newPlaylistCoverUrl.isEmpty ? nil : newPlaylistCoverUrl,
                                isPublic: newPlaylistIsPublic
                            )
                            newPlaylistName = ""
                            newPlaylistDesc = ""
                            newPlaylistCoverUrl = ""
                            showCreatePlaylistModal = false
                        }
                        .font(.system(size: 16, weight: .bold))
                        .disabled(newPlaylistName.isEmpty)
                    )
                    .sheet(isPresented: $showPlaylistCoverPicker) {
                        ImagePicker(selectedImage: $playlistCoverImage) { img in
                            Task {
                                isUploadingPlaylistCover = true
                                if let url = try? await NetworkManager.shared.uploadImage(uiImage: img) {
                                    newPlaylistCoverUrl = url
                                }
                                isUploadingPlaylistCover = false
                            }
                        }
                    }
                }
            }
        }
    }
}
