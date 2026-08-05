import Foundation
import Combine

public class FeedViewModel: ObservableObject {
    @Published public var posts: [Post] = []
    @Published public var isLoading: Bool = false
    @Published public var isRefreshing: Bool = false
    @Published public var postText: String = ""

    public init() {
        loadFeed()
    }

    public func loadFeed() {
        self.isLoading = true
        Task {
            do {
                let fetchedPosts: [Post] = try await NetworkManager.shared.request(endpoint: "feed.php")
                await MainActor.run {
                    self.posts = fetchedPosts
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }

    public func toggleLike(for post: Post) {
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            posts[index].isLiked.toggle()
            posts[index].likesCount += posts[index].isLiked ? 1 : -1
        }
    }

    public func toggleRepost(for post: Post) {
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            posts[index].isReposted.toggle()
            posts[index].repostsCount += posts[index].isReposted ? 1 : -1
        }
    }

    public func createPost(author: User, text: String, imageUrl: String = "") {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        // Добавляем временно в интерфейс
        let tempPost = Post(
            id: Int.random(in: 10000...99999),
            author: author,
            text: trimmedText,
            attachments: !imageUrl.isEmpty ? [PostAttachment(id: "img_temp", type: .image, url: imageUrl)] : [],
            likesCount: 0,
            isLiked: false,
            repostsCount: 0,
            commentsCount: 0,
            viewsCount: 1,
            createdAtFormatted: "Только что"
        )
        self.posts.insert(tempPost, at: 0)

        // Сохраняем пост на сервере в базу данных MariaDB
        let body: [String: Any] = [
            "user_id": author.id,
            "text": trimmedText,
            "image_url": imageUrl
        ]

        Task {
            do {
                let response: APIResponse<Post> = try await NetworkManager.shared.request(endpoint: "feed.php", method: "POST", jsonBody: body)
                if response.success, let createdPost = response.data {
                    await MainActor.run {
                        if let idx = self.posts.firstIndex(where: { $0.id == tempPost.id }) {
                            self.posts[idx] = createdPost
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.loadFeed()
                }
            }
        }
    }
}
