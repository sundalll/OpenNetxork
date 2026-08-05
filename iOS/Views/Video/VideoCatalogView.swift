import SwiftUI
import UniformTypeIdentifiers

public struct UploadVideoView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: VideoViewModel

    @State private var title: String = ""
    @State private var description: String = ""
    @State private var videoUrl: String = ""
    @State private var thumbnailUrl: String = ""

    @State private var showVideoPicker: Bool = false
    @State private var showThumbnailPicker: Bool = false
    @State private var thumbnailImage: UIImage? = nil
    @State private var isUploadingVideo: Bool = false
    @State private var isUploadingThumbnail: Bool = false
    @State private var isSubmitting: Bool = false

    public init(viewModel: VideoViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Информация о видео")) {
                    TextField("Название видео", text: $title)
                    TextField("Описание видео", text: $description)
                }

                Section(header: Text("Видеофайл (выбор с телефона)")) {
                    HStack {
                        Button(action: { showVideoPicker = true }) {
                            HStack {
                                Image(systemName: "video.fill")
                                Text(videoUrl.isEmpty ? "Выбрать видеофайл с телефона" : "Видеофайл загружен ✓")
                                    .font(.system(size: 14, weight: .bold))
                            }
                        }
                        if isUploadingVideo { ProgressView() }
                    }

                    if !videoUrl.isEmpty {
                        Text("Файл: \(videoUrl)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Section(header: Text("Превью / Обложка видео (с телефона)")) {
                    HStack {
                        Button(action: { showThumbnailPicker = true }) {
                            HStack {
                                Image(systemName: "photo.on.rectangle")
                                Text(thumbnailUrl.isEmpty ? "Выбрать превью с телефона" : "Превью загружено ✓")
                                    .font(.system(size: 14, weight: .bold))
                            }
                        }
                        if isUploadingThumbnail { ProgressView() }
                    }
                }
            }
            .navigationBarTitle("Загрузить видео", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Отмена") { presentationMode.wrappedValue.dismiss() },
                trailing: Button("Загрузить") {
                    Task {
                        isSubmitting = true
                        let success = await viewModel.uploadNewVideo(title: title, description: description, videoUrl: videoUrl, thumbnailUrl: thumbnailUrl)
                        isSubmitting = false
                        if success {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
                .font(.system(size: 16, weight: .bold))
                .disabled(title.isEmpty || videoUrl.isEmpty || isSubmitting)
            )
            .sheet(isPresented: $showVideoPicker) {
                DocumentPicker(allowedContentTypes: [.movie, .video, .quickTimeMovie, .mpeg4Movie]) { fileURL in
                    Task {
                        isUploadingVideo = true
                        if let url = try? await NetworkManager.shared.uploadFile(fileURL: fileURL) {
                            videoUrl = url
                        }
                        isUploadingVideo = false
                    }
                }
            }
            .sheet(isPresented: $showThumbnailPicker) {
                ImagePicker(selectedImage: $thumbnailImage) { img in
                    Task {
                        isUploadingThumbnail = true
                        if let url = try? await NetworkManager.shared.uploadImage(uiImage: img) {
                            thumbnailUrl = url
                        }
                        isUploadingThumbnail = false
                    }
                }
            }
        }
    }
}

public class VideoViewModel: ObservableObject {
    @Published public var videos: [Video] = []
    @Published public var isLoading: Bool = false

    public init() {
        loadVideos()
    }

    public func loadVideos() {
        self.isLoading = true
        Task {
            do {
                let fetchedVideos: [Video] = try await NetworkManager.shared.request(endpoint: "videos.php")
                await MainActor.run {
                    self.videos = fetchedVideos
                    self.isLoading = false
                }
            } catch {
                await MainActor.run { self.isLoading = false }
            }
        }
    }

    public func uploadNewVideo(title: String, description: String, videoUrl: String, thumbnailUrl: String) async -> Bool {
        let body: [String: Any] = [
            "title": title,
            "description": description,
            "video_url": videoUrl,
            "thumbnail_url": thumbnailUrl
        ]

        do {
            let response: APIResponse<Video> = try await NetworkManager.shared.request(endpoint: "video_upload.php", method: "POST", jsonBody: body)
            if response.success, let newVideo = response.data {
                await MainActor.run {
                    self.videos.insert(newVideo, at: 0)
                }
                return true
            }
            return false
        } catch {
            return false
        }
    }
}

public struct VideoCatalogView: View {
    @StateObject private var viewModel = VideoViewModel()
    @State private var showUploadModal: Bool = false
    @State private var selectedVideo: Video? = nil
    @State private var searchText: String = ""

    var filteredVideos: [Video] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return viewModel.videos
        } else {
            let query = searchText.lowercased()
            return viewModel.videos.filter {
                $0.title.lowercased().contains(query) || $0.description.lowercased().contains(query)
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
                    TextField("Поиск видео...", text: $searchText)
                        .autocapitalization(.none)
                }
                .padding(10)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal, 16)
                .padding(.top, 8)

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Видеозаписи")
                                .font(.system(size: 20, weight: .bold))
                            Spacer()
                            Button("+ Загрузить видео") {
                                showUploadModal = true
                            }
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.blue)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                        if filteredVideos.isEmpty {
                            Text(searchText.isEmpty ? "Видео пока не загружены. Нажмите '+ Загрузить видео', чтобы добавить первый ролик!" : "Видео по запросу '\(searchText)' не найдены.")
                                .foregroundColor(.secondary)
                                .font(.system(size: 14))
                                .padding(20)
                        } else {
                            LazyVStack(spacing: 20) {
                                ForEach(filteredVideos) { video in
                                    VStack(alignment: .leading, spacing: 10) {
                                        ZStack(alignment: .bottomTrailing) {
                                            if let url = URL(string: video.thumbnailUrl) {
                                                if #available(iOS 15.0, *) {
                                                    AsyncImage(url: url) { img in
                                                        img.resizable().scaledToFill()
                                                    } placeholder: {
                                                        Rectangle().fill(Color.gray.opacity(0.3))
                                                    }
                                                    .frame(height: 200)
                                                    .cornerRadius(12)
                                                    .clipped()
                                                } else {
                                                    Rectangle().fill(Color.gray.opacity(0.3))
                                                        .frame(height: 200)
                                                        .cornerRadius(12)
                                                }
                                            } else {
                                                Rectangle().fill(Color.gray.opacity(0.3))
                                                    .frame(height: 200)
                                                    .cornerRadius(12)
                                            }

                                            Image(systemName: "play.circle.fill")
                                                .font(.system(size: 50))
                                                .foregroundColor(.white)
                                                .shadow(radius: 6)
                                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

                                            Text(video.durationFormatted)
                                                .font(.system(size: 12, weight: .bold))
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Color.black.opacity(0.75))
                                                .foregroundColor(.white)
                                                .cornerRadius(6)
                                                .padding(10)
                                        }
                                        .frame(height: 200)
                                        .onTapGesture {
                                            selectedVideo = video
                                        }

                                        HStack(alignment: .top, spacing: 12) {
                                            AvatarView(urlString: video.author.avatarUrl, size: 40)

                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(video.title)
                                                    .font(.system(size: 16, weight: .bold))
                                                    .lineLimit(2)

                                                Text("\(video.author.fullName) • \(video.viewsCount) просмотров • \(video.createdAtFormatted)")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                        }
                    }
                }
            }
            .navigationBarTitle("Видеокаталог", displayMode: .inline)
            .sheet(isPresented: $showUploadModal) {
                UploadVideoView(viewModel: viewModel)
            }
        }
    }
}
