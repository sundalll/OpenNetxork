import SwiftUI

public struct MusicPlayerView: View {
    public let track: Track
    @ObservedObject var playerManager = AudioPlayerManager.shared
    @Environment(\.presentationMode) var presentationMode
    
    public init(track: Track) {
        self.track = track
    }

    public var body: some View {
        VStack(spacing: 24) {
            // Dismiss handle
            Capsule()
                .fill(Color.gray.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 12)

            Spacer()

            // Big Cover Art
            if let coverUrl = track.coverUrl, let url = URL(string: coverUrl) {
                if #available(iOS 15.0, *) {
                    AsyncImage(url: url) { img in
                        img.resizable().scaledToFill()
                    } placeholder: {
                        Rectangle().fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 280, height: 280)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 8)
                } else {
                    Image(systemName: "music.note")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                        .frame(width: 280, height: 280)
                        .background(Color.blue.opacity(0.15))
                        .cornerRadius(20)
                }
            } else {
                Image(systemName: "music.note")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                    .frame(width: 280, height: 280)
                    .background(Color.blue.opacity(0.15))
                    .cornerRadius(20)
            }

            // Track Info
            VStack(spacing: 6) {
                Text(track.title)
                    .font(.system(size: 22, weight: .bold))
                    .multilineTextAlignment(.center)
                
                Text(track.artist)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 24)

            // Progress Slider
            VStack(spacing: 6) {
                Slider(value: Binding(
                    get: { playerManager.currentTime },
                    set: { newValue in playerManager.seek(to: newValue) }
                ), in: 0...(playerManager.duration > 0 ? playerManager.duration : Double(track.durationSeconds)))
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

            // Controls
            HStack(spacing: 40) {
                Button(action: {}) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 28))
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
                        .font(.system(size: 28))
                        .foregroundColor(.primary)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .background(Color(UIColor.systemBackground).ignoresSafeArea())
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

    public init() {}

    public var body: some View {
        NavigationView {
            List {
                Section(header: Text("Моя музыка & Рекомендации")) {
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
            .navigationTitle("Музыка")
        }
    }
}
