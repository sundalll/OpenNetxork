import Foundation
import Combine

public class ProfileViewModel: ObservableObject {
    @Published public var user: User
    @Published public var userPosts: [Post] = []
    @Published public var followers: [User] = []
    @Published public var following: [User] = []
    @Published public var isLoading: Bool = false
    @Published public var isEditingProfile: Bool = false
    @Published public var statusEditingText: String = ""
    @Published public var isEditingStatus: Bool = false

    public init(user: User = User.demoUser) {
        self.user = user
        self.statusEditingText = user.statusText ?? ""
        loadUserProfile()
    }

    public func loadUserProfile() {
        self.isLoading = true
        Task {
            do {
                let fetchedUser: User = try await NetworkManager.shared.request(endpoint: "profile.php?user_id=\(user.id)")
                let allFeedPosts: [Post] = try await NetworkManager.shared.request(endpoint: "feed.php")
                await MainActor.run {
                    self.user = fetchedUser
                    self.userPosts = allFeedPosts.filter { $0.author.id == fetchedUser.id }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run { self.isLoading = false }
            }
        }
    }

    public func updateProfile(avatarUrl: String, coverUrl: String, statusText: String, bio: String) async -> Bool {
        let body: [String: Any] = [
            "user_id": user.id,
            "avatar_url": avatarUrl,
            "cover_url": coverUrl,
            "status_text": statusText,
            "bio": bio
        ]
        
        do {
            let _: APIResponse<[String: String]> = try await NetworkManager.shared.request(endpoint: "profile.php", method: "POST", jsonBody: body)
            await MainActor.run {
                if !avatarUrl.isEmpty { self.user.avatarUrl = avatarUrl }
                if !coverUrl.isEmpty { self.user.coverUrl = coverUrl }
                if !statusText.isEmpty { self.user.statusText = statusText }
                if !bio.isEmpty { self.user.bio = bio }
            }
            return true
        } catch {
            return false
        }
    }

    public func saveStatus() {
        user.statusText = statusEditingText
        isEditingStatus = false
    }
}
