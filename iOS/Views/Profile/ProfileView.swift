import SwiftUI

public struct EditProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: ProfileViewModel
    public var onUpdate: ((User) -> Void)? = nil
    
    @State private var avatarUrl: String
    @State private var coverUrl: String
    @State private var statusText: String
    @State private var bio: String

    @State private var showAvatarPicker: Bool = false
    @State private var showCoverPicker: Bool = false
    @State private var avatarImage: UIImage? = nil
    @State private var coverImage: UIImage? = nil
    @State private var isUploadingAvatar: Bool = false
    @State private var isUploadingCover: Bool = false

    public init(viewModel: ProfileViewModel, onUpdate: ((User) -> Void)? = nil) {
        self.viewModel = viewModel
        self.onUpdate = onUpdate
        _avatarUrl = State(initialValue: viewModel.user.avatarUrl ?? "")
        _coverUrl = State(initialValue: viewModel.user.coverUrl ?? "")
        _statusText = State(initialValue: viewModel.user.statusText ?? "")
        _bio = State(initialValue: viewModel.user.bio ?? "")
    }

    public var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Аватарка и Обложка (с телефона)")) {
                    HStack {
                        Button(action: { showAvatarPicker = true }) {
                            HStack {
                                Image(systemName: "photo.on.rectangle")
                                Text(avatarUrl.isEmpty ? "Выбрать аватарку с телефона" : "Аватарка загружена ✓")
                                    .font(.system(size: 14, weight: .bold))
                            }
                        }
                        if isUploadingAvatar { ProgressView() }
                    }

                    HStack {
                        Button(action: { showCoverPicker = true }) {
                            HStack {
                                Image(systemName: "photo.fill")
                                Text(coverUrl.isEmpty ? "Выбрать обложку с телефона" : "Обложка загружена ✓")
                                    .font(.system(size: 14, weight: .bold))
                            }
                        }
                        if isUploadingCover { ProgressView() }
                    }
                }

                Section(header: Text("Статус и Описание профиля")) {
                    TextField("Текстовый статус", text: $statusText)
                    TextField("О себе (био)", text: $bio)
                }
            }
            .navigationBarTitle("Редактировать профиль", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Отмена") { presentationMode.wrappedValue.dismiss() },
                trailing: Button("Сохранить") {
                    Task {
                        let success = await viewModel.updateProfile(avatarUrl: avatarUrl, coverUrl: coverUrl, statusText: statusText, bio: bio)
                        if success {
                            // Сохраняем обновленную сессию локально
                            if let data = try? JSONEncoder().encode(viewModel.user) {
                                UserDefaults.standard.set(data, forKey: "saved_murlika_user")
                            }
                            onUpdate?(viewModel.user)
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
                .font(.system(size: 16, weight: .bold))
            )
            .sheet(isPresented: $showAvatarPicker) {
                ImagePicker(selectedImage: $avatarImage) { img in
                    Task {
                        isUploadingAvatar = true
                        if let url = try? await NetworkManager.shared.uploadImage(uiImage: img) {
                            avatarUrl = url
                        }
                        isUploadingAvatar = false
                    }
                }
            }
            .sheet(isPresented: $showCoverPicker) {
                ImagePicker(selectedImage: $coverImage) { img in
                    Task {
                        isUploadingCover = true
                        if let url = try? await NetworkManager.shared.uploadImage(uiImage: img) {
                            coverUrl = url
                        }
                        isUploadingCover = false
                    }
                }
            }
        }
    }
}

public struct ProfileView: View {
    @StateObject private var viewModel: ProfileViewModel
    public var currentUser: User?
    @State private var showEditModal: Bool = false
    @State private var showFollowersModal: Bool = false
    @State private var showFollowingModal: Bool = false
    @State private var isSubscribed: Bool = false

    public init(user: User = User.demoUser, currentUser: User? = nil) {
        _viewModel = StateObject(wrappedValue: ProfileViewModel(user: user))
        self.currentUser = currentUser
    }

    private var isOwnProfile: Bool {
        if let current = currentUser {
            return current.id == viewModel.user.id
        }
        return false
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Background Header Cover
                ZStack(alignment: .bottomLeading) {
                    if let coverUrl = viewModel.user.coverUrl, let url = URL(string: coverUrl) {
                        if #available(iOS 15.0, *) {
                            AsyncImage(url: url) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .topLeading, endPoint: .bottomTrailing)
                            }
                            .frame(height: 160)
                            .clipped()
                        } else {
                            LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .topLeading, endPoint: .bottomTrailing)
                                .frame(height: 160)
                        }
                    } else {
                        LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .topLeading, endPoint: .bottomTrailing)
                            .frame(height: 160)
                    }

                    // Avatar
                    AvatarView(user: viewModel.user, size: 84)
                        .offset(x: 20, y: 40)
                }
                .padding(.bottom, 45)

                // Profile Info
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text(viewModel.user.fullName)
                                    .font(.system(size: 22, weight: .bold))
                                if viewModel.user.isVerified {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(.blue)
                                        .font(.system(size: 18))
                                }
                            }

                            if let status = viewModel.user.statusText, !status.isEmpty {
                                Text(status)
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        if isOwnProfile {
                            Button(action: { showEditModal = true }) {
                                Text("Редактировать")
                                    .font(.system(size: 13, weight: .semibold))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(Color(UIColor.secondarySystemGroupedBackground))
                                    .cornerRadius(16)
                            }
                        } else {
                            Button(action: { isSubscribed.toggle() }) {
                                Text(isSubscribed ? "Вы подписаны" : "Подписаться")
                                    .font(.system(size: 13, weight: .bold))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(isSubscribed ? Color(UIColor.secondarySystemGroupedBackground) : Color.blue)
                                    .foregroundColor(isSubscribed ? .primary : .white)
                                    .cornerRadius(16)
                            }
                        }
                    }

                    if let bio = viewModel.user.bio, !bio.isEmpty {
                        Text(bio)
                            .font(.system(size: 13))
                            .foregroundColor(.primary)
                            .padding(.top, 4)
                    }

                    HStack(spacing: 20) {
                        Button(action: { showFollowersModal = true }) {
                            HStack(spacing: 4) {
                                Text("\(viewModel.user.followersCount)")
                                    .font(.system(size: 14, weight: .bold))
                                Text("подписчиков")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        }

                        Button(action: { showFollowingModal = true }) {
                            HStack(spacing: 4) {
                                Text("\(viewModel.user.followingCount)")
                                    .font(.system(size: 14, weight: .bold))
                                Text("подписок")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.top, 6)
                }
                .padding(.horizontal, 20)

                Divider()
                    .padding(.vertical, 16)

                // User's Posts Wall
                VStack(alignment: .leading, spacing: 12) {
                    Text("Стена записей")
                        .font(.system(size: 18, weight: .bold))
                        .padding(.horizontal, 20)

                    if viewModel.userPosts.isEmpty {
                        Text("Публикаций пока нет.")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14))
                            .padding(20)
                    } else {
                        ForEach(viewModel.userPosts) { post in
                            PostCardView(post: post)
                                .padding(.horizontal, 16)
                        }
                    }
                }
            }
        }
        .navigationBarTitle(viewModel.user.fullName, displayMode: .inline)
        .sheet(isPresented: $showEditModal) {
            EditProfileView(viewModel: viewModel)
        }
        .sheet(isPresented: $showFollowersModal) {
            UserListSheetView(title: "Подписчики", users: [User.demoUser])
        }
        .sheet(isPresented: $showFollowingModal) {
            UserListSheetView(title: "Подписки", users: [User.demoUser])
        }
    }
}
