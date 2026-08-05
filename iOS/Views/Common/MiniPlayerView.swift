import SwiftUI

public struct MiniPlayerView: View {
    @ObservedObject var playerManager = AudioPlayerManager.shared
    @State private var showFullPlayer: Bool = false
    
    public init() {}
    
    public var body: some View {
        if let track = playerManager.currentTrack {
            HStack(spacing: 12) {
                if let coverUrl = track.coverUrl, let url = URL(string: coverUrl) {
                    AsyncImage(url: url) { img in
                        img.resizable().scaledToFill()
                    } placeholder: {
                        Color.gray.opacity(0.3)
                    }
                    .frame(width: 42, height: 42)
                    .cornerRadius(6)
                } else {
                    Image(systemName: "music.note")
                        .frame(width: 42, height: 42)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(6)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(1)
                    
                    Text(track.artist)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Button(action: {
                    playerManager.togglePlayPause()
                }) {
                    Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.primary)
                        .padding(8)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                    .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 60)
            .onTapGesture {
                showFullPlayer = true
            }
            .sheet(isPresented: $showFullPlayer) {
                MusicPlayerView(track: track)
            }
        }
    }
}
