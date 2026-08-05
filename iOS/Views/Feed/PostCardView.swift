import SwiftUI

public struct PostCardView: View {
    public let post: Post
    public let onLike: () -> Void
    public let onRepost: () -> Void
    public let onComment: () -> Void
    
    @ObservedObject private var playerManager = AudioPlayerManager.shared
    
    public init(
        post: Post,
        onLike: @escaping () -> Void = {},
        onRepost: @escaping () -> Void = {},
        onComment: @escaping () -> Void = {}
    ) {
        self.post = post
        self.onLike = onLike
        self.onRepost = onRepost
        self.onComment = onComment
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Author Avatar & Name & Time
            NavigationLink(destination: ProfileView(user: post.author)) {
                HStack(spacing: 10) {
                    AvatarView(urlString: post.author.avatarUrl, size: 42, isOnline: post.author.isOnline)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(post.channelName ?? post.author.fullName)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.primary)
                            
                            if post.author.isVerified {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        Text(post.createdAtFormatted)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.secondary)
                            .padding(6)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 16)
            .padding(.top, 14)

            // Post Text
            if !post.text.isEmpty {
                Text(post.text)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, 16)
            }

            // Attachments (Images or Audio)
            ForEach(post.attachments, id: \.id) { attachment in
                if attachment.type == .image, let url = URL(string: attachment.url) {
                    if #available(iOS 15.0, *) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(8)
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .aspectRatio(16/9, contentMode: .fit)
                        }
                        .padding(.horizontal, 16)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 200)
                            .cornerRadius(8)
                            .padding(.horizontal, 16)
                    }
                } else if attachment.type == .audio {
                    HStack(spacing: 12) {
                        Image(systemName: "music.note")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.blue)
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(attachment.title ?? "Аудиозапись")
                                .font(.system(size: 14, weight: .semibold))
                            Text(attachment.subtitle ?? "Исполнитель")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            let track = Track(
                                id: Int.random(in: 100...999),
                                title: attachment.title ?? "Трек",
                                artist: attachment.subtitle ?? "Артист",
                                durationSeconds: 180,
                                audioUrl: attachment.url
                            )
                            playerManager.play(track: track)
                        }) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(12)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                }
            }

            Divider()

            // Footer: Likes, Comments, Reposts, Views
            HStack(spacing: 16) {
                // Like Button
                Button(action: onLike) {
                    HStack(spacing: 6) {
                        Image(systemName: post.isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 16))
                            .foregroundColor(post.isLiked ? .red : .secondary)
                        
                        Text("\(post.likesCount)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(post.isLiked ? .red : .secondary)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(post.isLiked ? Color.red.opacity(0.1) : Color(UIColor.systemGroupedBackground))
                    .cornerRadius(16)
                }

                // Comment Button
                Button(action: onComment) {
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.left")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                        
                        Text("\(post.commentsCount)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(Color(UIColor.systemGroupedBackground))
                    .cornerRadius(16)
                }

                // Repost Button
                Button(action: onRepost) {
                    HStack(spacing: 6) {
                        Image(systemName: post.isReposted ? "arrow.triangle.2.circlepath.circle.fill" : "arrow.triangle.2.circlepath")
                            .font(.system(size: 15))
                            .foregroundColor(post.isReposted ? .green : .secondary)
                        
                        Text("\(post.repostsCount)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(post.isReposted ? .green : .secondary)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(post.isReposted ? Color.green.opacity(0.1) : Color(UIColor.systemGroupedBackground))
                    .cornerRadius(16)
                }

                Spacer()

                // Views Count
                HStack(spacing: 4) {
                    Image(systemName: "eye")
                        .font(.system(size: 12))
                    Text("\(post.viewsCount)")
                        .font(.system(size: 12))
                }
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}
