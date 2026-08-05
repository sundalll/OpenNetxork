import Foundation
import Combine

public class ProfileViewModel: ObservableObject {
    @Published public var userProfile: User
    @Published public var userPosts: [Post] = []
    @Published public var statusEditingText: String = ""
    @Published public var isEditingStatus: Bool = false
    
    public init(user: User) {
        self.userProfile = user
        self.statusEditingText = user.statusText ?? ""
        loadUserWall()
    }
    
    public func loadUserWall() {
        let samplePost = Post(
            id: 201,
            author: userProfile,
            text: "Привет всем! Добро пожаловать на мою официальную страницу в приложении. Пишите в комментарии свои впечатления! ✨",
            likesCount: 88,
            isLiked: false,
            repostsCount: 12,
            commentsCount: 15,
            viewsCount: 1200,
            createdAtFormatted: "Вчера в 18:40"
        )
        self.userPosts = [samplePost]
    }
    
    public func saveStatus() {
        userProfile.statusText = statusEditingText
        isEditingStatus = false
    }
}

public class MusicViewModel: ObservableObject {
    @Published public var tracks: [Track] = []
    @Published public var albums: [Album] = []
    @Published public var playlists: [Playlist] = []
    @Published public var searchQuery: String = ""
    @Published public var isLoading: Bool = false
    @Published public var uploadError: String? = nil
    
    public init() {
        loadMusicCatalog()
        loadAlbumsAndPlaylists()
    }
    
    public func loadMusicCatalog() {
        self.isLoading = true
        
        // Загрузка реальных треков с сервера
        Task {
            do {
                let fetchedTracks: [Track] = try await NetworkManager.shared.request(endpoint: "music.php")
                await MainActor.run {
                    self.tracks = fetchedTracks
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    public func uploadNewTrack(title: String, artist: String, album: String, audioUrl: String, coverUrl: String) async -> Bool {
        guard !title.isEmpty, !artist.isEmpty, !audioUrl.isEmpty else { return false }
        
        let newTrack = Track(
            id: Int.random(in: 1000...9999),
            title: title,
            artist: artist,
            durationSeconds: 180,
            coverUrl: coverUrl.isEmpty ? nil : coverUrl,
            audioUrl: audioUrl,
            albumName: album.isEmpty ? nil : album
        )
        
        await MainActor.run {
            self.tracks.insert(newTrack, at: 0)
        }
        return true
    }
    
    public func loadAlbumsAndPlaylists() {
        self.albums = []
        self.playlists = [
            Playlist(id: 1, name: "Моя медиатека 💖", description: "Загруженная музыка", coverUrl: nil, tracks: tracks)
        ]
    }
    
    public func createPlaylist(name: String, description: String) {
        let newPlaylist = Playlist(
            id: Int.random(in: 100...999),
            name: name,
            description: description,
            coverUrl: nil,
            tracks: []
        )
        playlists.append(newPlaylist)
    }

    public func createAlbum(title: String, artist: String) {
        let newAlbum = Album(
            id: Int.random(in: 100...999),
            title: title,
            artist: artist,
            coverUrl: nil,
            releaseYear: "2026",
            tracks: []
        )
        albums.append(newAlbum)
    }
    
    public func toggleLike(track: Track) {
        if let index = tracks.firstIndex(where: { $0.id == track.id }) {
            tracks[index].isLiked.toggle()
        }
    }
}

public class VideoViewModel: ObservableObject {
    @Published public var videos: [Video] = []
    
    public init() {
        loadVideos()
    }
    
    public func loadVideos() {
        let author = User(id: 1, username: "apple_tech", firstName: "Apple", lastName: "Special", avatarUrl: "https://images.unsplash.com/photo-1611186871348-b1ce696e52c9?auto=format&fit=crop&w=400&q=80")
        
        self.videos = [
            Video(
                id: 1,
                title: "Презентация iOS & SwiftUI: Будущее мобильных приложений",
                description: "Полный обзор создания современных интерактивных приложений для iOS от 13 до 18 систем.",
                author: author,
                thumbnailUrl: "https://images.unsplash.com/photo-1512941937669-90a1b58e7e9c?auto=format&fit=crop&w=800&q=80",
                videoUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
                durationSeconds: 125,
                viewsCount: 42300,
                likesCount: 3410,
                isLiked: true,
                createdAtFormatted: "3 дня назад"
            ),
            Video(
                id: 2,
                title: "Обзор функционала соцсети: Музыка, Видео, Каналы",
                description: "Подробный разбор интерфейса и фоновой музыки.",
                author: author,
                thumbnailUrl: "https://images.unsplash.com/photo-1498050108023-c5249f4df085?auto=format&fit=crop&w=800&q=80",
                videoUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
                durationSeconds: 596,
                viewsCount: 18900,
                likesCount: 1200,
                isLiked: false,
                createdAtFormatted: "Неделю назад"
            )
        ]
    }
}

public class ChannelsViewModel: ObservableObject {
    @Published public var channels: [Channel] = []
    
    public init() {
        loadChannels()
    }
    
    public func loadChannels() {
        self.channels = [
            Channel(
                id: 1,
                name: "Технологии будущего 🚀",
                description: "Главные новости науки, искусственного интеллекта и разработки ПО.",
                avatarUrl: "https://images.unsplash.com/photo-1518770660439-4636190af475?auto=format&fit=crop&w=400&q=80",
                coverUrl: "https://images.unsplash.com/photo-1451187580459-43490279c0fa?auto=format&fit=crop&w=800&q=80",
                subscribersCount: 84500,
                isSubscribed: true,
                isVerified: true,
                category: "ИТ и Наука"
            ),
            Channel(
                id: 2,
                name: "Музыкальный Пульс 🎵",
                description: "Самые горячие новинки мира музыки, рецензии и альбомы.",
                avatarUrl: "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?auto=format&fit=crop&w=400&q=80",
                coverUrl: "https://images.unsplash.com/photo-1514525253161-7a46d19cd819?auto=format&fit=crop&w=800&q=80",
                subscribersCount: 120300,
                isSubscribed: false,
                isVerified: true,
                category: "Музыка"
            )
        ]
    }
    
    public func toggleSubscribe(channel: Channel) {
        if let index = channels.firstIndex(where: { $0.id == channel.id }) {
            channels[index].isSubscribed.toggle()
            channels[index].subscribersCount += channels[index].isSubscribed ? 1 : -1
        }
    }
}
