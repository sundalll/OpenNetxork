import SwiftUI
import AVKit

public struct VideoPlayerView: View {
    public let video: Video
    @Environment(\.presentationMode) var presentationMode
    
    public init(video: Video) {
        self.video = video
    }

    public var body: some View {
        VStack(spacing: 0) {
            if let url = URL(string: video.videoUrl) {
                VideoPlayer(player: AVPlayer(url: url))
                    .frame(height: 240)
            } else {
                Rectangle()
                    .fill(Color.black)
                    .frame(height: 240)
                    .overlay(Text("Видео недоступно").foregroundColor(.white))
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(video.title)
                        .font(.system(size: 18, weight: .bold))
                    
                    HStack(spacing: 12) {
                        Text("\(video.viewsCount) просмотров")
                        Text("•")
                        Text(video.createdAtFormatted)
                    }
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    
                    Divider()
                    
                    HStack(spacing: 12) {
                        AvatarView(urlString: video.author.avatarUrl, size: 40)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(video.author.fullName)
                                .font(.system(size: 15, weight: .bold))
                            Text("Автор видео")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    Text(video.description)
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                        .padding(.top, 4)
                }
                .padding(16)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

public struct VideoCatalogView: View {
    @StateObject private var viewModel = VideoViewModel()
    
    public init() {}

    public var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.videos) { video in
                        NavigationLink(destination: VideoPlayerView(video: video)) {
                            VStack(alignment: .leading, spacing: 8) {
                                // Thumbnail with Duration Badge
                                ZStack(alignment: .bottomTrailing) {
                                    AsyncImage(url: URL(string: video.thumbnailUrl)) { img in
                                        img.resizable().scaledToFill()
                                    } placeholder: {
                                        Rectangle().fill(Color.gray.opacity(0.3))
                                    }
                                    .frame(height: 200)
                                    .clipped()
                                    .cornerRadius(12)
                                    
                                    Text(video.durationFormatted)
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(Color.black.opacity(0.8))
                                        .cornerRadius(4)
                                        .padding(8)
                                }
                                
                                HStack(alignment: .top, spacing: 10) {
                                    AvatarView(urlString: video.author.avatarUrl, size: 36)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(video.title)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(.primary)
                                            .lineLimit(2)
                                            .multilineTextAlignment(.leading)
                                        
                                        HStack(spacing: 6) {
                                            Text(video.author.fullName)
                                            Text("•")
                                            Text("\(video.viewsCount) просмотров")
                                        }
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(12)
                .padding(.bottom, 80)
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Видео")
        }
    }
}
