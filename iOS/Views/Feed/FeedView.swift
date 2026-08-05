import SwiftUI

public struct CreatePostView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var feedViewModel: FeedViewModel
    public let currentUser: User
    
    @State private var textInput: String = ""
    @State private var imageUrl: String = ""
    @State private var showImagePicker: Bool = false
    @State private var selectedImage: UIImage? = nil
    @State private var isUploadingImage: Bool = false

    public init(feedViewModel: FeedViewModel, currentUser: User) {
        self.feedViewModel = feedViewModel
        self.currentUser = currentUser
    }

    public var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    AvatarView(urlString: currentUser.avatarUrl, size: 44)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(currentUser.fullName)
                            .font(.system(size: 16, weight: .bold))
                        Text("Видно всем друзьям")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                TextEditor(text: $textInput)
                    .font(.system(size: 16))
                    .padding(.horizontal, 12)

                if !imageUrl.isEmpty {
                    Text("Фото прикреплено ✓")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 16)
                }

                Spacer()

                HStack(spacing: 24) {
                    Button(action: { showImagePicker = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 22))
                                .foregroundColor(.blue)
                            Text("Фото с телефона")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.blue)
                        }
                    }
                    if isUploadingImage { ProgressView() }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(UIColor.secondarySystemGroupedBackground))
            }
            .navigationTitle("Создать запись")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Отмена") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Опубликовать") {
                    feedViewModel.createPost(author: currentUser, text: textInput)
                    presentationMode.wrappedValue.dismiss()
                }
                .font(.system(size: 16, weight: .bold))
                .disabled(textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            )
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: $selectedImage) { img in
                    Task {
                        isUploadingImage = true
                        if let url = try? await NetworkManager.shared.uploadImage(uiImage: img) {
                            imageUrl = url
                        }
                        isUploadingImage = false
                    }
                }
            }
        }
    }
}

public struct FeedView: View {
    @ObservedObject var feedViewModel: FeedViewModel
    public let currentUser: User
    
    @State private var showCreatePostModal: Bool = false
    
    public init(feedViewModel: FeedViewModel, currentUser: User) {
        self.feedViewModel = feedViewModel
        self.currentUser = currentUser
    }

    public var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 8) {
                    // Create Post Trigger Bar
                    HStack(spacing: 12) {
                        AvatarView(urlString: currentUser.avatarUrl, size: 38)
                        
                        Button(action: {
                            showCreatePostModal = true
                        }) {
                            Text("Что у вас нового?")
                                .foregroundColor(.secondary)
                                .font(.system(size: 15))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal, 8)
                    .padding(.top, 8)

                    // Feed Posts
                    ForEach(feedViewModel.posts) { post in
                        PostCardView(
                            post: post,
                            onLike: {
                                feedViewModel.toggleLike(for: post)
                            },
                            onRepost: {
                                feedViewModel.toggleRepost(for: post)
                            },
                            onComment: {
                                // комментарии
                            }
                        )
                    }
                }
                .padding(.bottom, 80)
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationBarTitle("Главная лента")
            .sheet(isPresented: $showCreatePostModal) {
                CreatePostView(feedViewModel: feedViewModel, currentUser: currentUser)
            }
        }
    }
}
