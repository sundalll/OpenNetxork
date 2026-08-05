import SwiftUI

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
                Text(track.lyrics ?? "Текст для этой песни пока не добавлен.")
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
                
                if let freq = track.frequencyFM {
                    Text(freq)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.blue.opacity(0.15))
                        .cornerRadius(6)
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

            // Controls & Lyrics Trigger
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

public struct UberRadioView: View {
    @ObservedObject var viewModel: MusicViewModel
    @ObservedObject private var playerManager = AudioPlayerManager.shared
    
    public init(viewModel: MusicViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 20) {
            // Radio Header Visualizer
            VStack(spacing: 8) {
                Text("UBER RADIO FM")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.blue)
                    .tracking(2)
                
                Text(String(format: "%.1f FM", viewModel.currentFrequency))
                    .font(.system(size: 44, weight: .black, design: .monospaced))
                    .foregroundColor(.primary)
                
                HStack(spacing: 4) {
                    ForEach(0..<16, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(i % 3 == 0 ? Color.blue : Color.gray.opacity(0.4))
                            .frame(width: 4, height: CGFloat.random(in: 12...36))
                    }
                }
                .frame(height: 40)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)

            // Frequency Slider / Tuner
            VStack(alignment: .leading, spacing: 8) {
                Text("Тюнер частот FM")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)

                Slider(value: $viewModel.currentFrequency, in: 87.5...108.0, step: 0.1)
                    .accentColor(.blue)

                HStack {
                    Text("87.5 FM")
                    Spacer()
                    Text("108.0 FM")
                }
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            }

            // Radio Stations Presets List
            VStack(alignment: .leading, spacing: 10) {
                Text("Станции прямого эфира")
                    .font(.system(size: 15, weight: .bold))

                ForEach(viewModel.radioStations) { station in
                    HStack(spacing: 12) {
                        Image(systemName: "radio.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                            .frame(width: 42, height: 42)
                            .background(Color.blue.opacity(0.15))
                            .cornerRadius(10)

                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(station.name)
                                    .font(.system(size: 15, weight: .bold))
                                Spacer()
                                Text(station.frequencyText)
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundColor(.blue)
                            }
                            Text(station.genre)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }

                        Button(action: {
                            viewModel.currentFrequency = station.frequency
                            let track = Track(
                                id: station.id + 1000,
                                title: station.name,
                                artist: station.genre,
                                durationSeconds: 0,
                                coverUrl: station.coverUrl,
                                audioUrl: station.streamUrl,
                                frequencyFM: station.frequencyText
                            )
                            playerManager.play(track: track)
                        }) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(10)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                }
            }
        }
        .padding(16)
    }
}

public struct MusicView: View {
    @StateObject private var viewModel = MusicViewModel()
    @ObservedObject private var playerManager = AudioPlayerManager.shared
    @State private var selectedSegment: Int = 0
    @State private var showCreatePlaylistModal: Bool = false
    @State private var newPlaylistName: String = ""
    @State private var newPlaylistDesc: String = ""

    public init() {}

    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Segmented Picker (Музыка / Uber Радио / Альбомы / Плейлисты)
                Picker("", selection: $selectedSegment) {
                    Text("Музыка").tag(0)
                    Text("Uber FM 📻").tag(1)
                    Text("Альбомы").tag(2)
                    Text("Плейлисты").tag(3)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                if selectedSegment == 0 {
                    // Music Tracks List
                    List {
                        Section(header: Text("Треки & Музыка")) {
                            ForEach(viewModel.tracks) { track in
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
                                        HStack(spacing: 4) {
                                            Text(track.title)
                                                .font(.system(size: 15, weight: .semibold))
                                            if track.explicit {
                                                Text("E")
                                                    .font(.system(size: 10, weight: .bold))
                                                    .padding(.horizontal, 4)
                                                    .padding(.vertical, 2)
                                                    .background(Color.secondary.opacity(0.2))
                                                    .cornerRadius(4)
                                            }
                                        }
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
                    .listStyle(InsetGroupedListStyle())
                } else if selectedSegment == 1 {
                    // Uber Radio Tuner View
                    ScrollView {
                        UberRadioView(viewModel: viewModel)
                            .padding(.bottom, 80)
                    }
                } else if selectedSegment == 2 {
                    // Albums View
                    List {
                        Section(header: Text("Музыкальные Альбомы")) {
                            ForEach(viewModel.albums) { album in
                                HStack(spacing: 14) {
                                    Image(systemName: "square.stack.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.purple)
                                        .frame(width: 52, height: 52)
                                        .background(Color.purple.opacity(0.15))
                                        .cornerRadius(10)

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(album.title)
                                            .font(.system(size: 16, weight: .bold))
                                        Text("\(album.artist) • \(album.releaseYear)")
                                            .font(.system(size: 13))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                } else if selectedSegment == 3 {
                    // Playlists View
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
            .navigationBarTitle("Музыка & Радио")
            .sheet(isPresented: $showCreatePlaylistModal) {
                NavigationView {
                    Form {
                        Section(header: Text("Параметры плейлиста")) {
                            TextField("Название плейлиста", text: $newPlaylistName)
                            TextField("Описание", text: $newPlaylistDesc)
                        }
                    }
                    .navigationBarTitle("Новый плейлист", displayMode: .inline)
                    .navigationBarItems(
                        leading: Button("Отмена") { showCreatePlaylistModal = false },
                        trailing: Button("Создать") {
                            viewModel.createPlaylist(name: newPlaylistName, description: newPlaylistDesc)
                            newPlaylistName = ""
                            newPlaylistDesc = ""
                            showCreatePlaylistModal = false
                        }.font(.system(size: 16, weight: .bold))
                    )
                }
            }
        }
    }
}
