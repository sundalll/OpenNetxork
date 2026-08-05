import SwiftUI

@main
struct SocialNetworkApp: App {
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            MainTabView(authViewModel: authViewModel)
        }
    }
}
