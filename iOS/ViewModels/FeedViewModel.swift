import Foundation
import Combine

public class AuthViewModel: ObservableObject {
    @Published public var currentUser: User? = nil
    @Published public var isAuthenticated: Bool = false
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil
    
    @Published public var emailInput: String = ""
    @Published public var passwordInput: String = ""
    @Published public var usernameInput: String = ""
    @Published public var firstNameInput: String = ""
    @Published public var lastNameInput: String = ""

    public init() {
        // Создаем демо-пользователя по умолчанию для моментальной готовности интерфейса
        setupDemoUser()
    }

    public func setupDemoUser() {
        let demoUser = User(
            id: 1,
            username: "user",
            firstName: "Пользователь",
            lastName: "",
            avatarUrl: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80",
            coverUrl: "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?auto=format&fit=crop&w=1200&q=80",
            statusText: "Свобода общения и музыка 🚀",
            isVerified: true,
            followersCount: 1420,
            followingCount: 12,
            bio: "Профиль социальной сети",
            isOnline: true,
            lastSeenText: "В сети"
        )
        self.currentUser = demoUser
        self.isAuthenticated = true
    }

    public func login() async {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        // Симуляция задержки сети и проверки
        try? await Task.sleep(nanoseconds: 600_000_000)
        
        await MainActor.run {
            self.setupDemoUser()
            self.isLoading = false
        }
    }

    public func logout() {
        self.currentUser = nil
        self.isAuthenticated = false
    }
}

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
