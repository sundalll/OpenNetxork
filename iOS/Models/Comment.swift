import Foundation

public struct Comment: Identifiable, Codable, Equatable, Hashable {
    public let id: Int
    public let postId: Int
    public let author: User
    public var text: String
    public var likesCount: Int
    public var isLiked: Bool
    public var createdAtFormatted: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case postId = "post_id"
        case author
        case text
        case likesCount = "likes_count"
        case isLiked = "is_liked"
        case createdAtFormatted = "created_at_formatted"
    }

    public init(id: Int, postId: Int, author: User, text: String, likesCount: Int = 0, isLiked: Bool = false, createdAtFormatted: String = "Только что") {
        self.id = id
        self.postId = postId
        self.author = author
        self.text = text
        self.likesCount = likesCount
        self.isLiked = isLiked
        self.createdAtFormatted = createdAtFormatted
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        postId = try container.decodeIfPresent(Int.self, forKey: .postId) ?? 0
        author = try container.decode(User.self, forKey: .author)
        text = try container.decodeIfPresent(String.self, forKey: .text) ?? ""
        likesCount = try container.decodeIfPresent(Int.self, forKey: .likesCount) ?? 0
        isLiked = try container.decodeIfPresent(Bool.self, forKey: .isLiked) ?? false
        createdAtFormatted = try container.decodeIfPresent(String.self, forKey: .createdAtFormatted) ?? "Только что"
    }
}

public struct Track: Identifiable, Codable, Equatable, Hashable {
    public let id: Int
    public var title: String
    public var artist: String
    public var durationSeconds: Int
    public var coverUrl: String?
    public var audioUrl: String
    public var isLiked: Bool
    public var explicit: Bool
    public var lyrics: String?
    public var albumName: String?
    public var frequencyFM: String?

    public var durationFormatted: String {
        if durationSeconds == 0 { return "LIVE" }
        let mins = durationSeconds / 60
        let secs = durationSeconds % 60
        return String(format: "%d:%02d", mins, secs)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case artist
        case durationSeconds = "duration_seconds"
        case coverUrl = "cover_url"
        case audioUrl = "audio_url"
        case isLiked = "is_liked"
        case explicit
        case lyrics
        case albumName = "album_name"
        case frequencyFM = "frequency_fm"
    }

    public init(id: Int, title: String, artist: String, durationSeconds: Int, coverUrl: String? = nil, audioUrl: String, isLiked: Bool = false, explicit: Bool = false, lyrics: String? = nil, albumName: String? = nil, frequencyFM: String? = nil) {
        self.id = id
        self.title = title
        self.artist = artist
        self.durationSeconds = durationSeconds
        self.coverUrl = coverUrl
        self.audioUrl = audioUrl
        self.isLiked = isLiked
        self.explicit = explicit
        self.lyrics = lyrics
        self.albumName = albumName
        self.frequencyFM = frequencyFM
    }
}

public struct Album: Identifiable, Codable, Equatable, Hashable {
    public let id: Int
    public var title: String
    public var artist: String
    public var coverUrl: String?
    public var releaseYear: String
    public var tracks: [Track]

    enum CodingKeys: String, CodingKey {
        case id, title, artist, tracks
        case coverUrl = "cover_url"
        case releaseYear = "release_year"
    }

    public init(id: Int, title: String, artist: String, coverUrl: String? = nil, releaseYear: String = "2026", tracks: [Track] = []) {
        self.id = id
        self.title = title
        self.artist = artist
        self.coverUrl = coverUrl
        self.releaseYear = releaseYear
        self.tracks = tracks
    }
}

public struct Playlist: Identifiable, Codable, Equatable, Hashable {
    public let id: Int
    public var name: String
    public var description: String
    public var coverUrl: String?
    public var isPublic: Bool
    public var shareUrl: String?
    public var tracks: [Track]

    enum CodingKeys: String, CodingKey {
        case id, name, description, tracks
        case coverUrl = "cover_url"
        case isPublic = "is_public"
        case shareUrl = "share_url"
    }

    public init(id: Int, name: String, description: String, coverUrl: String? = nil, isPublic: Bool = true, shareUrl: String? = nil, tracks: [Track] = []) {
        self.id = id
        self.name = name
        self.description = description
        self.coverUrl = coverUrl
        self.isPublic = isPublic
        self.shareUrl = shareUrl
        self.tracks = tracks
    }
}

public struct RadioStation: Identifiable, Codable, Equatable, Hashable {
    public let id: Int
    public var name: String
    public var frequency: Double
    public var genre: String
    public var streamUrl: String
    public var coverUrl: String?
    
    public var frequencyText: String {
        return String(format: "%.1f FM", frequency)
    }

    public init(id: Int, name: String, frequency: Double, genre: String, streamUrl: String, coverUrl: String? = nil) {
        self.id = id
        self.name = name
        self.frequency = frequency
        self.genre = genre
        self.streamUrl = streamUrl
        self.coverUrl = coverUrl
    }
}

public struct Video: Identifiable, Codable, Equatable, Hashable {
    public let id: Int
    public var title: String
    public var description: String
    public var author: User
    public var thumbnailUrl: String
    public var videoUrl: String
    public var durationSeconds: Int
    public var viewsCount: Int
    public var likesCount: Int
    public var isLiked: Bool
    public var createdAtFormatted: String

    public var durationFormatted: String {
        let mins = durationSeconds / 60
        let secs = durationSeconds % 60
        return String(format: "%d:%02d", mins, secs)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case author
        case thumbnailUrl = "thumbnail_url"
        case videoUrl = "video_url"
        case durationSeconds = "duration_seconds"
        case viewsCount = "views_count"
        case likesCount = "likes_count"
        case isLiked = "is_liked"
        case createdAtFormatted = "created_at_formatted"
    }

    public init(id: Int, title: String, description: String, author: User, thumbnailUrl: String, videoUrl: String, durationSeconds: Int, viewsCount: Int = 0, likesCount: Int = 0, isLiked: Bool = false, createdAtFormatted: String = "Только что") {
        self.id = id
        self.title = title
        self.description = description
        self.author = author
        self.thumbnailUrl = thumbnailUrl
        self.videoUrl = videoUrl
        self.durationSeconds = durationSeconds
        self.viewsCount = viewsCount
        self.likesCount = likesCount
        self.isLiked = isLiked
        self.createdAtFormatted = createdAtFormatted
    }
}

public struct ChannelPost: Identifiable, Codable, Equatable, Hashable {
    public let id: Int
    public let channelId: Int
    public var text: String
    public var imageUrl: String?
    public var likesCount: Int
    public var viewsCount: Int
    public var createdAtFormatted: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case channelId = "channel_id"
        case text
        case imageUrl = "image_url"
        case likesCount = "likes_count"
        case viewsCount = "views_count"
        case createdAtFormatted = "created_at_formatted"
    }

    public init(id: Int, channelId: Int, text: String, imageUrl: String? = nil, likesCount: Int = 0, viewsCount: Int = 1, createdAtFormatted: String = "Только что") {
        self.id = id
        self.channelId = channelId
        self.text = text
        self.imageUrl = imageUrl
        self.likesCount = likesCount
        self.viewsCount = viewsCount
        self.createdAtFormatted = createdAtFormatted
    }
}

public struct Channel: Identifiable, Codable, Equatable, Hashable {
    public let id: Int
    public var userId: Int?
    public var name: String
    public var description: String
    public var avatarUrl: String?
    public var coverUrl: String?
    public var subscribersCount: Int
    public var isSubscribed: Bool
    public var isVerified: Bool
    public var category: String
    public var posts: [ChannelPost]?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case description
        case avatarUrl = "avatar_url"
        case coverUrl = "cover_url"
        case subscribersCount = "subscribers_count"
        case isSubscribed = "is_subscribed"
        case isVerified = "is_verified"
        case category
        case posts
    }

    public init(id: Int, userId: Int? = 1, name: String, description: String, avatarUrl: String? = nil, coverUrl: String? = nil, subscribersCount: Int = 0, isSubscribed: Bool = false, isVerified: Bool = false, category: String = "Паблик", posts: [ChannelPost]? = []) {
        self.id = id
        self.userId = userId
        self.name = name
        self.description = description
        self.avatarUrl = avatarUrl
        self.coverUrl = coverUrl
        self.subscribersCount = subscribersCount
        self.isSubscribed = isSubscribed
        self.isVerified = isVerified
        self.category = category
        self.posts = posts
    }
}

public struct APIResponse<T: Codable>: Codable {
    public let success: Bool
    public let message: String?
    public let data: T?
}
