import SwiftUI

public struct MainTabView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @StateObject var feedViewModel = FeedViewModel()
    @State private var selectedTab: Int = 0

    public init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
    }

    public var body: some View {
        if let user = authViewModel.currentUser {
            ZStack(alignment: .bottom) {
                TabView(selection: $selectedTab) {
                    FeedView(feedViewModel: feedViewModel, currentUser: user)
                        .tabItem {
                            Label("Новости", systemImage: "newspaper.fill")
                        }
                        .tag(0)

                    ChannelsView()
                        .tabItem {
                            Label("Каналы", systemImage: "text.bubble.fill")
                        }
                        .tag(1)

                    MusicView()
                        .tabItem {
                            Label("Музыка", systemImage: "music.note.house.fill")
                        }
                        .tag(2)

                    VideoCatalogView()
                        .tabItem {
                            Label("Видео", systemImage: "play.tv.fill")
                        }
                        .tag(3)

                    ProfileView(user: user)
                        .tabItem {
                            Label("Профиль", systemImage: "person.crop.circle.fill")
                        }
                        .tag(4)
                }

                // Mini Player overlay for background audio playback
                MiniPlayerView()
            }
        } else {
            AuthView(authViewModel: authViewModel)
        }
    }
}
