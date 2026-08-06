import SwiftUI

public struct CommentsModalView: View {
    @Environment(\.presentationMode) var presentationMode
    public let post: Post
    public let currentUser: User
    @State private var comments: [Comment] = []
    @State private var commentText: String = ""
    @State private var isLoading: Bool = false

    public init(post: Post, currentUser: User) {
        self.post = post
        self.currentUser = currentUser
    }

    public var body: some View {
        NavigationView {
            VStack {
                List {
                    Section(header: Text("Запись")) {
                        Text(post.text)
                            .font(.system(size: 15))
                    }

                    Section(header: Text("Комментарии (\(comments.count))")) {
                        if comments.isEmpty {
                            Text("Пока нет комментариев. Напишите первый комментарий!")
                                .foregroundColor(.secondary)
                                .font(.system(size: 14))
                                .padding(.vertical, 12)
                        } else {
                            ForEach(comments) { comment in
                                HStack(alignment: .top, spacing: 10) {
                                    AvatarView(urlString: comment.author.avatarUrl, size: 36)
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(comment.author.fullName)
                                                .font(.system(size: 14, weight: .bold))
                                            Spacer()
                                            Text(comment.createdAtFormatted)
                                                .font(.system(size: 11))
                                                .foregroundColor(.secondary)
                                        }
                                        Text(comment.text)
                                            .font(.system(size: 14))
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())

                // Input bar
                HStack(spacing: 12) {
                    TextField("Написать комментарий...", text: $commentText)
                        .padding(10)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(20)

                    Button(action: {
                        let trimmed = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        let newComment = Comment(
                            id: Int.random(in: 1000...9999),
                            postId: post.id,
                            author: currentUser,
                            text: trimmed,
                            createdAtFormatted: "Только что"
                        )
                        comments.append(newComment)
                        commentText = ""
                    }) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                    }
                    .disabled(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(UIColor.systemBackground))
            }
            .navigationBarTitle("Комментарии", displayMode: .inline)
            .navigationBarItems(trailing: Button("Закрыть") { presentationMode.wrappedValue.dismiss() })
        }
    }
}

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
                        Text("Видно всем подписчикам")
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
                    Text("Фотография успешно прикреплена к посту ✓")
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
                            Text("Выбрать фото с телефона")
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
                    feedViewModel.createPost(author: currentUser, text: textInput, imageUrl: imageUrl)
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
    @State private var selectedPostForComments: Post? = nil
    @State private var searchText: String = ""
    @State private var selectedFeedSegment: Int = 0 // 0: Рекомендации, 1: Подписки

    var filteredPosts: [Post] {
        let basePosts = feedViewModel.posts
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return basePosts
        } else {
            let query = searchText.lowercased()
            return basePosts.filter {
                $0.text.lowercased().contains(query) ||
                $0.author.username.lowercased().contains(query) ||
                $0.author.fullName.lowercased().contains(query)
            }
        }
    }
    
    public init(feedViewModel: FeedViewModel, currentUser: User) {
        self.feedViewModel = feedViewModel
        self.currentUser = currentUser
    }

    public var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 8) {
                    // Global Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Поиск по новостям, авторам, никнеймам...", text: $searchText)
                            .autocapitalization(.none)
                    }
                    .padding(10)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)

                    // Feed Segmented Control
                    Picker("", selection: $selectedFeedSegment) {
                        Text("🔥 Рекомендации").tag(0)
                        Text("👥 Мои подписки").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, 12)

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
                    .padding(.vertical, 4)

                    // Feed Posts
                    if filteredPosts.isEmpty {
                        Text(searchText.isEmpty ? "В ленте пока нет публикаций. Напишите первую запись!" : "Ничего не найдено по запросу '\(searchText)'")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14))
                            .padding(24)
                    } else {
                        ForEach(filteredPosts) { post in
                            PostCardView(
                                post: post,
                                onLike: {
                                    feedViewModel.toggleLike(for: post)
                                },
                                onRepost: {
                                    feedViewModel.toggleRepost(for: post)
                                },
                                onComment: {
                                    selectedPostForComments = post
                                }
                            )
                        }
                    }
                }
                .padding(.bottom, 80)
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationBarTitle("Главная лента")
            .sheet(isPresented: $showCreatePostModal) {
                CreatePostView(feedViewModel: feedViewModel, currentUser: currentUser)
            }
            .sheet(item: $selectedPostForComments) { targetPost in
                CommentsModalView(post: targetPost, currentUser: currentUser)
            }
        }
    }
}
