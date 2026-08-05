import SwiftUI

public struct ProfileView: View {
    @StateObject private var viewModel: ProfileViewModel
    
    public init(user: User) {
        _viewModel = StateObject(wrappedValue: ProfileViewModel(user: user))
    }

    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Cover Banner
                    ZStack(alignment: .bottomLeading) {
                        if let coverUrl = viewModel.userProfile.coverUrl, let url = URL(string: coverUrl) {
                            AsyncImage(url: url) { img in
                                img.resizable().scaledToFill()
                            } placeholder: {
                                LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                            }
                            .frame(height: 140)
                            .clipped()
                        } else {
                            LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                                .frame(height: 140)
                        }
                    }
                    
                    // Profile Header Details
                    VStack(spacing: 12) {
                        // Avatar overlay
                        HStack {
                            AvatarView(urlString: viewModel.userProfile.avatarUrl, size: 84, isOnline: viewModel.userProfile.isOnline)
                                .offset(y: -42)
                                .padding(.bottom, -42)
                            Spacer()
                            
                            Button(action: {
                                viewModel.isEditingStatus.toggle()
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "pencil")
                                    Text("Редактировать")
                                }
                                .font(.system(size: 13, weight: .semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .cornerRadius(16)
                            }
                        }
                        .padding(.horizontal, 20)

                        // Name & Verification
                        HStack(spacing: 6) {
                            Text(viewModel.userProfile.fullName)
                                .font(.system(size: 22, weight: .bold))
                            
                            if viewModel.userProfile.isVerified {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.blue)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)

                        // Status Text
                        if viewModel.isEditingStatus {
                            HStack {
                                TextField("Установите статус...", text: $viewModel.statusEditingText)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                Button("Сохранить") {
                                    viewModel.saveStatus()
                                }
                                .bold()
                            }
                            .padding(.horizontal, 20)
                        } else if let status = viewModel.userProfile.statusText, !status.isEmpty {
                            Text(status)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)
                        }

                        // Followers & Following Stats
                        HStack(spacing: 24) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(viewModel.userProfile.followersCount)")
                                    .font(.system(size: 16, weight: .bold))
                                Text("подписчиков")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(viewModel.userProfile.followingCount)")
                                    .font(.system(size: 16, weight: .bold))
                                Text("подписок")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 4)

                        Divider()
                            .padding(.top, 8)
                    }

                    // User Wall Title
                    HStack {
                        Text("Стена профиля")
                            .font(.system(size: 17, weight: .bold))
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    // Wall Posts
                    ForEach(viewModel.userPosts) { post in
                        PostCardView(
                            post: post,
                            onLike: {},
                            onRepost: {},
                            onComment: {}
                        )
                    }
                }
                .padding(.bottom, 80)
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Профиль")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
