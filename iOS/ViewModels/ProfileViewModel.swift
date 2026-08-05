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
                await MainActor.run {
                    self.user = fetchedUser
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
