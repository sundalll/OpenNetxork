import Foundation

public struct PostAttachment: Codable, Hashable {
    public enum AttachmentType: String, Codable {
        case image
        case video
        case audio
    }
    
    public let id: String
    public let type: AttachmentType
    public let url: String
    public let title: String?
    public let subtitle: String?
    public let thumbnailUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id, type, url, title, subtitle
        case thumbnailUrl = "thumbnail_url"
    }

    public init(id: String, type: AttachmentType, url: String, title: String? = nil, subtitle: String? = nil, thumbnailUrl: String? = nil) {
        self.id = id
        self.type = type
        self.url = url
        self.title = title
        self.subtitle = subtitle
        self.thumbnailUrl = thumbnailUrl
    }
}

public struct Post: Identifiable, Codable, Equatable, Hashable {
    public let id: Int
    public let author: User
    public var text: String
    public var attachments: [PostAttachment]
    public var likesCount: Int
    public var isLiked: Bool
    public var repostsCount: Int
    public var isReposted: Bool
    public var commentsCount: Int
    public var viewsCount: Int
    public var createdAtFormatted: String
    public var channelName: String?
    public var channelAvatarUrl: String?

    enum CodingKeys: String, CodingKey {
        case id
        case author
        case text
        case attachments
        case likesCount = "likes_count"
        case isLiked = "is_liked"
        case repostsCount = "reposts_count"
        case isReposted = "is_reposted"
        case commentsCount = "comments_count"
        case viewsCount = "views_count"
        case createdAtFormatted = "created_at_formatted"
        case channelName = "channel_name"
        case channelAvatarUrl = "channel_avatar_url"
    }

    public init(
        id: Int,
        author: User,
        text: String,
        attachments: [PostAttachment] = [],
        likesCount: Int = 0,
        isLiked: Bool = false,
        repostsCount: Int = 0,
        isReposted: Bool = false,
        commentsCount: Int = 0,
        viewsCount: Int = 0,
        createdAtFormatted: String = "Только что",
        channelName: String? = nil,
        channelAvatarUrl: String? = nil
    ) {
        self.id = id
        self.author = author
        self.text = text
        self.attachments = attachments
        self.likesCount = likesCount
        self.isLiked = isLiked
        self.repostsCount = repostsCount
        self.isReposted = isReposted
        self.commentsCount = commentsCount
        self.viewsCount = viewsCount
        self.createdAtFormatted = createdAtFormatted
        self.channelName = channelName
        self.channelAvatarUrl = channelAvatarUrl
    }
}
