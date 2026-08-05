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
        
        // Симулированный демонстрационный контент социальной сети VK-стиля
        let author1 = User(
            id: 1,
            username: "durov",
            firstName: "Павел",
            lastName: "Дуров",
            avatarUrl: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80",
            statusText: "Создаем будущее",
            isVerified: true,
            isOnline: true
        )
        
        let author2 = User(
            id: 2,
            username: "tech_insider",
            firstName: "Apple",
            lastName: "News",
            avatarUrl: "https://images.unsplash.com/photo-1611186871348-b1ce696e52c9?auto=format&fit=crop&w=400&q=80",
            isVerified: true,
            isOnline: false
        )

        let post1 = Post(
            id: 101,
            author: author1,
            text: "Привет всем пользователям нашей новой социальной сети на Swift & SwiftUI! 🚀\n\nДизайн создан по всем стандартам iOS 13–18 с плавной анимацией, полной поддержкой встроенной музыки, видео, стенами и статусами.",
            attachments: [
                PostAttachment(id: "att1", type: .image, url: "https://images.unsplash.com/photo-1512941937669-90a1b58e7e9c?auto=format&fit=crop&w=1000&q=80")
            ],
            likesCount: 1420,
            isLiked: true,
            repostsCount: 312,
            commentsCount: 89,
            viewsCount: 15400,
            createdAtFormatted: "15 минут назад"
        )

        let post2 = Post(
            id: 102,
            author: author2,
            text: "🎵 Премьера нового альбома в плеере приложения! Нажмите на трек ниже, чтобы включить фоновый аудиоплеер с обложкой и управлением.",
            attachments: [
                PostAttachment(id: "att2", type: .audio, url: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3", title: "Cyberpunk Dreams (Original Mix)", subtitle: "Synthwave Beats")
            ],
            likesCount: 950,
            isLiked: false,
            repostsCount: 140,
            commentsCount: 42,
            viewsCount: 8900,
            createdAtFormatted: "2 часа назад",
            channelName: "VK Music Official",
            channelAvatarUrl: "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?auto=format&fit=crop&w=400&q=80"
        )

        self.posts = [post1, post2]
        self.isLoading = false
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

    public func createPost(author: User, text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let newPost = Post(
            id: Int.random(in: 1000...9999),
            author: author,
            text: text,
            likesCount: 0,
            isLiked: false,
            repostsCount: 0,
            commentsCount: 0,
            viewsCount: 1,
            createdAtFormatted: "Только что"
        )
        
        posts.insert(newPost, at: 0)
        postText = ""
    }
}
