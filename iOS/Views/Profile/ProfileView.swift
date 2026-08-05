import SwiftUI

public struct EditProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: ProfileViewModel

    @State private var avatarUrl: String = ""
    @State private var coverUrl: String = ""
    @State private var statusText: String = ""
    @State private var bio: String = ""
    @State private var isSaving: Bool = false

    public init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
        _avatarUrl = State(initialValue: viewModel.user.avatarUrl ?? "")
        _coverUrl = State(initialValue: viewModel.user.coverUrl ?? "")
        _statusText = State(initialValue: viewModel.user.statusText ?? "")
        _bio = State(initialValue: viewModel.user.bio ?? "")
    }

    public var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Аватарка пользователя")) {
                    TextField("URL картинки аватарки", text: $avatarUrl)
                        .autocapitalization(.none)
                }

                Section(header: Text("Задняя обложка профиля")) {
                    TextField("URL картинки обложки", text: $coverUrl)
                        .autocapitalization(.none)
                }

                Section(header: Text("Статус профиля")) {
                    TextField("Ваш текущий статус", text: $statusText)
                }

                Section(header: Text("О себе (Био)")) {
                    TextField("Расскажите о себе", text: $bio)
                }
            }
            .navigationBarTitle("Редактировать профиль", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Отмена") { presentationMode.wrappedValue.dismiss() },
                trailing: Button("Сохранить") {
                    Task {
                        isSaving = true
                        let success = await viewModel.updateProfile(avatarUrl: avatarUrl, coverUrl: coverUrl, statusText: statusText, bio: bio)
                        isSaving = false
                        if success {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
                .font(.system(size: 16, weight: .bold))
                .disabled(isSaving)
            )
        }
    }
}

public struct ProfileView: View {
    @StateObject private var viewModel: ProfileViewModel
    @State private var showEditProfileModal: Bool = false

    public init(user: User = User.demoUser) {
        _viewModel = StateObject(wrappedValue: ProfileViewModel(user: user))
    }

    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header / Cover Image
                    ZStack(alignment: .bottomLeading) {
                        if let coverUrl = viewModel.user.coverUrl, let url = URL(string: coverUrl) {
                            if #available(iOS 15.0, *) {
                                AsyncImage(url: url) { img in
                                    img.resizable().scaledToFill()
                                } placeholder: {
                                    Rectangle().fill(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .topLeading, endPoint: .bottomTrailing))
                                }
                                .frame(height: 160)
                                .clipped()
                            } else {
                                Rectangle().fill(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(height: 160)
                            }
                        } else {
                            Rectangle().fill(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(height: 160)
                        }

                        // Avatar Image
                        AvatarView(user: viewModel.user, size: 90)
                            .overlay(Circle().stroke(Color(UIColor.systemBackground), lineWidth: 4))
                            .offset(x: 20, y: 45)
                    }
                    .padding(.bottom, 50)

                    // Profile User Info
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(viewModel.user.fullName)
                                        .font(.system(size: 22, weight: .bold))
                                    if viewModel.user.isVerified {
                                        Image(systemName: "checkmark.seal.fill")
                                            .foregroundColor(.blue)
                                            .font(.system(size: 18))
                                    }
                                }

                                Text("@\(viewModel.user.username)")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Button(action: {
                                showEditProfileModal = true
                            }) {
                                Text("Редактировать")
                                    .font(.system(size: 14, weight: .semibold))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.blue.opacity(0.15))
                                    .foregroundColor(.blue)
                                    .cornerRadius(20)
                            }
                        }

                        // Status
                        if let status = viewModel.user.statusText, !status.isEmpty {
                            Text("💬 \(status)")
                                .font(.system(size: 14))
                                .foregroundColor(.primary)
                                .padding(.top, 4)
                        }

                        // Bio
                        if let bio = viewModel.user.bio, !bio.isEmpty {
                            Text(bio)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .padding(.top, 2)
                        }

                        // Followers / Following Stats
                        HStack(spacing: 24) {
                            HStack(spacing: 4) {
                                Text("\(viewModel.user.followersCount)")
                                    .font(.system(size: 16, weight: .bold))
                                Text("подписчиков")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }

                            HStack(spacing: 4) {
                                Text("\(viewModel.user.followingCount)")
                                    .font(.system(size: 16, weight: .bold))
                                Text("подписок")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)

                    Divider()
                        .padding(.vertical, 16)

                    // User Wall Posts
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Стена профиля")
                            .font(.system(size: 18, weight: .bold))
                            .padding(.horizontal, 20)

                        if viewModel.userPosts.isEmpty {
                            Text("На стене пока нет записей.")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 20)
                        } else {
                            ForEach(viewModel.userPosts) { post in
                                PostCardView(post: post)
                            }
                        }
                    }
                }
            }
            .navigationBarTitle("Профиль", displayMode: .inline)
            .sheet(isPresented: $showEditProfileModal) {
                EditProfileView(viewModel: viewModel)
            }
        }
    }
}
