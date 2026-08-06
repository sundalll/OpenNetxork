import Foundation

public struct User: Identifiable, Codable, Equatable, Hashable {
    public let id: Int
    public var username: String
    public var firstName: String
    public var lastName: String
    public var avatarUrl: String?
    public var coverUrl: String?
    public var statusText: String?
    public var isVerified: Bool
    public var followersCount: Int
    public var followingCount: Int
    public var bio: String?
    public var isOnline: Bool
    public var lastSeenText: String?
    
    public var fullName: String {
        return "\(firstName) \(lastName)".trimmingCharacters(in: .whitespacesAndNewlines)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case firstName = "first_name"
        case lastName = "last_name"
        case avatarUrl = "avatar_url"
        case coverUrl = "cover_url"
        case statusText = "status_text"
        case isVerified = "is_verified"
        case followersCount = "followers_count"
        case followingCount = "following_count"
        case bio
        case isOnline = "is_online"
        case lastSeenText = "last_seen_text"
    }

    public init(
        id: Int,
        username: String,
        firstName: String,
        lastName: String,
        avatarUrl: String? = nil,
        coverUrl: String? = nil,
        statusText: String? = nil,
        isVerified: Bool = false,
        followersCount: Int = 0,
        followingCount: Int = 0,
        bio: String? = nil,
        isOnline: Bool = false,
        lastSeenText: String? = nil
    ) {
        self.id = id
        self.username = username
        self.firstName = firstName
        self.lastName = lastName
        self.avatarUrl = avatarUrl
        self.coverUrl = coverUrl
        self.statusText = statusText
        self.isVerified = isVerified
        self.followersCount = followersCount
        self.followingCount = followingCount
        self.bio = bio
        self.isOnline = isOnline
        self.lastSeenText = lastSeenText
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        username = try container.decodeIfPresent(String.self, forKey: .username) ?? "user"
        firstName = try container.decodeIfPresent(String.self, forKey: .firstName) ?? "Пользователь"
        lastName = try container.decodeIfPresent(String.self, forKey: .lastName) ?? ""
        avatarUrl = try container.decodeIfPresent(String.self, forKey: .avatarUrl)
        coverUrl = try container.decodeIfPresent(String.self, forKey: .coverUrl)
        statusText = try container.decodeIfPresent(String.self, forKey: .statusText)
        isVerified = try container.decodeIfPresent(Bool.self, forKey: .isVerified) ?? false
        followersCount = try container.decodeIfPresent(Int.self, forKey: .followersCount) ?? 0
        followingCount = try container.decodeIfPresent(Int.self, forKey: .followingCount) ?? 0
        bio = try container.decodeIfPresent(String.self, forKey: .bio)
        isOnline = try container.decodeIfPresent(Bool.self, forKey: .isOnline) ?? true
        lastSeenText = try container.decodeIfPresent(String.self, forKey: .lastSeenText)
    }

    public static var demoUser = User(
        id: 1,
        username: "user",
        firstName: "Пользователь",
        lastName: "",
        avatarUrl: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80",
        coverUrl: "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?auto=format&fit=crop&w=1200&q=80",
        statusText: "Свобода общения и музыка 🚀",
        isVerified: true,
        followersCount: 0,
        followingCount: 0,
        bio: "Пользователь сети Murlika",
        isOnline: true
    )
}
