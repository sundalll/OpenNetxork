import SwiftUI

public class ChannelsViewModel: ObservableObject {
    @Published public var channels: [Channel] = []
    @Published public var selectedChannelDetails: Channel? = nil
    @Published public var isLoading: Bool = false

    public init() {
        loadChannels()
    }

    public func loadChannels() {
        self.isLoading = true
        Task {
            do {
                let fetchedChannels: [Channel] = try await NetworkManager.shared.request(endpoint: "channels.php")
                await MainActor.run {
                    self.channels = fetchedChannels
                    self.isLoading = false
                }
            } catch {
                await MainActor.run { self.isLoading = false }
            }
        }
    }

    public func fetchChannelDetails(channelId: Int) {
        Task {
            do {
                let details: Channel = try await NetworkManager.shared.request(endpoint: "channels.php?channel_id=\(channelId)")
                await MainActor.run {
                    self.selectedChannelDetails = details
                }
            } catch {}
        }
    }

    public func createChannel(name: String, description: String, category: String, avatarUrl: String, coverUrl: String) async -> Bool {
        let body: [String: Any] = [
            "action": "create",
            "name": name,
            "description": description,
            "category": category,
            "avatar_url": avatarUrl,
            "cover_url": coverUrl
        ]

        do {
            let _: APIResponse<Channel> = try await NetworkManager.shared.request(endpoint: "channels.php", method: "POST", jsonBody: body)
            await MainActor.run {
                loadChannels()
            }
            return true
        } catch {
            await MainActor.run {
                loadChannels()
            }
            return true
        }
    }

    public func toggleSubscribe(channel: Channel) {
        if let idx = channels.firstIndex(where: { $0.id == channel.id }) {
            channels[idx].isSubscribed.toggle()
            if channels[idx].isSubscribed {
                channels[idx].subscribersCount += 1
            } else {
                channels[idx].subscribersCount = max(0, channels[idx].subscribersCount - 1)
            }
        }

        let body: [String: Any] = [
            "action": "toggle_subscribe",
            "channel_id": channel.id
        ]

        Task {
            do {
                let _: APIResponse<[String: Bool]> = try await NetworkManager.shared.request(endpoint: "channels.php", method: "POST", jsonBody: body)
            } catch {}
        }
    }

    public func createChannelPost(channelId: Int, text: String, imageUrl: String) async -> Bool {
        let body: [String: Any] = [
            "action": "create_post",
            "channel_id": channelId,
            "text": text,
            "image_url": imageUrl
        ]

        do {
            let response: APIResponse<ChannelPost> = try await NetworkManager.shared.request(endpoint: "channels.php", method: "POST", jsonBody: body)
            if response.success, let post = response.data {
                await MainActor.run {
                    if self.selectedChannelDetails?.id == channelId {
                        if self.selectedChannelDetails?.posts == nil {
                            self.selectedChannelDetails?.posts = []
                        }
                        self.selectedChannelDetails?.posts?.insert(post, at: 0)
                    }
                }
                return true
            }
            return false
        } catch {
            return false
        }
    }
}

public struct CreateChannelView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: ChannelsViewModel

    @State private var name: String = ""
    @State private var description: String = ""
    @State private var category: String = "Паблик"
    @State private var avatarUrl: String = ""
    @State private var coverUrl: String = ""

    @State private var showAvatarPicker: Bool = false
    @State private var showCoverPicker: Bool = false
    @State private var avatarImage: UIImage? = nil
    @State private var coverImage: UIImage? = nil
    @State private var isUploadingAvatar: Bool = false
    @State private var isUploadingCover: Bool = false
    @State private var isSubmitting: Bool = false

    public init(viewModel: ChannelsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Основная информация")) {
                    TextField("Название канала / паблика", text: $name)
                    TextField("Категория (новости, игры, музыка)", text: $category)
                    TextField("Описание канала", text: $description)
                }

                Section(header: Text("Оформление (с телефона)")) {
                    HStack {
                        Button(action: { showAvatarPicker = true }) {
                            HStack {
                                Image(systemName: "photo.on.rectangle")
                                Text(avatarUrl.isEmpty ? "Выбрать аватарку с телефона" : "Аватарка выбрана ✓")
                                    .font(.system(size: 14, weight: .bold))
                            }
                        }
                        if isUploadingAvatar { ProgressView() }
                    }

                    HStack {
                        Button(action: { showCoverPicker = true }) {
                            HStack {
                                Image(systemName: "photo.fill")
                                Text(coverUrl.isEmpty ? "Выбрать обложку с телефона" : "Обложка выбрана ✓")
                                    .font(.system(size: 14, weight: .bold))
                            }
                        }
                        if isUploadingCover { ProgressView() }
                    }
                }
            }
            .navigationBarTitle("Создать канал", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Отмена") { presentationMode.wrappedValue.dismiss() },
                trailing: Button("Создать") {
                    Task {
                        isSubmitting = true
                        let success = await viewModel.createChannel(name: name, description: description, category: category, avatarUrl: avatarUrl, coverUrl: coverUrl)
                        isSubmitting = false
                        if success {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
                .font(.system(size: 16, weight: .bold))
                .disabled(name.isEmpty || isSubmitting)
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

public struct ChannelDetailView: View {
    public let channel: Channel
    @ObservedObject var viewModel: ChannelsViewModel
    @State private var newPostText: String = ""
    @State private var newPostImageUrl: String = ""

    @State private var showPostImagePicker: Bool = false
    @State private var postImage: UIImage? = nil
    @State private var isUploadingPostImage: Bool = false
    @State private var showPostModal: Bool = false

    public init(channel: Channel, viewModel: ChannelsViewModel) {
        self.channel = channel
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header / Cover
                ZStack(alignment: .bottomLeading) {
                    if let coverUrl = channel.coverUrl, let url = URL(string: coverUrl) {
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
                    AvatarView(urlString: channel.avatarUrl, size: 84)
                        .overlay(Circle().stroke(Color(UIColor.systemBackground), lineWidth: 4))
                        .offset(x: 20, y: 40)
                }
                .padding(.bottom, 45)

                // Channel Info Header
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Text(channel.name)
                                    .font(.system(size: 22, weight: .bold))
                                if channel.isVerified {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(.blue)
                                        .font(.system(size: 18))
                                }
                            }

                            Text("\(channel.category) • \(channel.subscribersCount) подписчиков")
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                        }

                        Spacer()

                        Button(action: {
                            viewModel.toggleSubscribe(channel: channel)
                        }) {
                            Text(channel.isSubscribed ? "Вы подписаны" : "Подписаться")
                                .font(.system(size: 14, weight: .bold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(channel.isSubscribed ? Color(UIColor.systemGroupedBackground) : Color.blue)
                                .foregroundColor(channel.isSubscribed ? .primary : .white)
                                .cornerRadius(20)
                        }
                    }

                    Text(channel.description)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 20)

                Divider()
                    .padding(.vertical, 16)

                // Channel Wall Posts
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("Записи канала")
                            .font(.system(size: 18, weight: .bold))
                        Spacer()
                        Button("+ Написать пост") {
                            showPostModal = true
                        }
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 20)

                    if let posts = viewModel.selectedChannelDetails?.posts, !posts.isEmpty {
                        ForEach(posts) { post in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(post.text)
                                    .font(.system(size: 15))
                                    .lineSpacing(4)

                                if let img = post.imageUrl, let url = URL(string: img) {
                                    if #available(iOS 15.0, *) {
                                        AsyncImage(url: url) { image in
                                            image.resizable().scaledToFill()
                                        } placeholder: {
                                            Color.gray.opacity(0.3)
                                        }
                                        .frame(height: 200)
                                        .cornerRadius(12)
                                    }
                                }

                                HStack {
                                    Text(post.createdAtFormatted)
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    HStack(spacing: 4) {
                                        Image(systemName: "eye.fill")
                                            .font(.system(size: 12))
                                        Text("\(post.viewsCount)")
                                            .font(.system(size: 12))
                                    }
                                    .foregroundColor(.secondary)
                                }
                            }
                            .padding(16)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                            .padding(.horizontal, 20)
                        }
                    } else {
                        Text("В этом канале пока нет публикаций. Опубликуйте первую запись!")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .padding(20)
                    }
                }
            }
        }
        .navigationBarTitle(channel.name, displayMode: .inline)
        .onAppear {
            viewModel.fetchChannelDetails(channelId: channel.id)
        }
        .sheet(isPresented: $showPostModal) {
            NavigationView {
                Form {
                    Section(header: Text("Текст публикации")) {
                        TextEditor(text: $newPostText)
                            .frame(height: 120)
                    }
                    Section(header: Text("Фото к посту (с телефона)")) {
                        HStack {
                            Button(action: { showPostImagePicker = true }) {
                                HStack {
                                    Image(systemName: "photo")
                                    Text(newPostImageUrl.isEmpty ? "Выбрать фото с телефона" : "Фото добавлено ✓")
                                        .font(.system(size: 14, weight: .bold))
                                }
                            }
                            if isUploadingPostImage { ProgressView() }
                        }
                    }
                }
                .navigationBarTitle("Пост в канал", displayMode: .inline)
                .navigationBarItems(
                    leading: Button("Отмена") { showPostModal = false },
                    trailing: Button("Опубликовать") {
                        Task {
                            let success = await viewModel.createChannelPost(channelId: channel.id, text: newPostText, imageUrl: newPostImageUrl)
                            if success {
                                newPostText = ""
                                newPostImageUrl = ""
                                showPostModal = false
                            }
                        }
                    }
                    .font(.system(size: 16, weight: .bold))
                    .disabled(newPostText.isEmpty)
                )
                .sheet(isPresented: $showPostImagePicker) {
                    ImagePicker(selectedImage: $postImage) { img in
                        Task {
                            isUploadingPostImage = true
                            if let url = try? await NetworkManager.shared.uploadImage(uiImage: img) {
                                newPostImageUrl = url
                            }
                            isUploadingPostImage = false
                        }
                    }
                }
            }
        }
    }
}

public struct ChannelsView: View {
    @StateObject private var viewModel = ChannelsViewModel()
    @State private var showCreateChannelModal: Bool = false
    @State private var searchText: String = ""

    var filteredChannels: [Channel] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return viewModel.channels
        } else {
            let query = searchText.lowercased()
            return viewModel.channels.filter {
                $0.name.lowercased().contains(query) ||
                $0.description.lowercased().contains(query) ||
                $0.category.lowercased().contains(query)
            }
        }
    }

    public init() {}

    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Поиск каналов и пабликов...", text: $searchText)
                        .autocapitalization(.none)
                }
                .padding(10)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal, 16)
                .padding(.top, 8)

                List {
                    Section(header: HStack {
                        Text("Каналы & Паблики")
                        Spacer()
                        Button("+ Создать канал") {
                            showCreateChannelModal = true
                        }
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.blue)
                    }) {
                        if filteredChannels.isEmpty {
                            VStack(spacing: 12) {
                                Text(searchText.isEmpty ? "Каналы пока не созданы." : "Каналы не найдены по запросу '\(searchText)'")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 15))
                                
                                Button(action: { showCreateChannelModal = true }) {
                                    Text("Создать первый канал")
                                        .font(.system(size: 14, weight: .bold))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                }
                            }
                            .padding(.vertical, 24)
                            .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            ForEach(filteredChannels) { channel in
                                NavigationLink(destination: ChannelDetailView(channel: channel, viewModel: viewModel)) {
                                    HStack(spacing: 12) {
                                        AvatarView(urlString: channel.avatarUrl, size: 52)

                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack(spacing: 4) {
                                                Text(channel.name)
                                                    .font(.system(size: 15, weight: .bold))
                                                if channel.isVerified {
                                                    Image(systemName: "checkmark.seal.fill")
                                                        .font(.system(size: 12))
                                                        .foregroundColor(.blue)
                                                }
                                            }
                                            
                                            Text(channel.description)
                                                .font(.system(size: 12))
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                            
                                            Text("\(channel.subscribersCount) подписчиков")
                                                .font(.system(size: 11))
                                                .foregroundColor(.blue)
                                        }

                                        Spacer()

                                        Button(action: {
                                            viewModel.toggleSubscribe(channel: channel)
                                        }) {
                                            Text(channel.isSubscribed ? "Вы подписаны" : "Подписаться")
                                                .font(.system(size: 12, weight: .semibold))
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background(channel.isSubscribed ? Color(UIColor.systemGroupedBackground) : Color.blue)
                                                .foregroundColor(channel.isSubscribed ? .primary : .white)
                                                .cornerRadius(14)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationBarTitle("Каналы")
            .sheet(isPresented: $showCreateChannelModal) {
                CreateChannelView(viewModel: viewModel)
            }
        }
    }
}
