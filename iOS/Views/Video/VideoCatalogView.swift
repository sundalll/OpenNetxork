import SwiftUI

public struct UploadVideoView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: VideoViewModel

    @State private var title: String = ""
    @State private var description: String = ""
    @State private var videoUrl: String = ""
    @State private var thumbnailUrl: String = ""
    @State private var showThumbnailPicker: Bool = false
    @State private var thumbnailImage: UIImage? = nil
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

                Section(header: Text("Видеофайл (MP4, MOV, AVI)")) {
                    TextField("URL видеофайла (например: http://.../video.mp4)", text: $videoUrl)
                        .autocapitalization(.none)
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

                    TextField("Или введите URL обложки", text: $thumbnailUrl)
                        .autocapitalization(.none)
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
                .disabled(title.isEmpty || isSubmitting)
            )
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
            let _: APIResponse<[String: String]> = try await NetworkManager.shared.request(endpoint: "video_upload.php", method: "POST", jsonBody: body)
            await MainActor.run {
                loadVideos()
            }
            return true
        } catch {
            return false
        }
    }
}

public struct VideoCatalogView: View {
    @StateObject private var viewModel = VideoViewModel()
    @State private var showUploadModal: Bool = false

    public init() {}

    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Видеокаталог")
                            .font(.system(size: 20, weight: .bold))
                        Spacer()
                        Button("+ Загрузить видео") {
                            showUploadModal = true
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 16)

                    if viewModel.videos.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "video.badge.plus")
                                .font(.system(size: 48))
                                .foregroundColor(.blue)
                            Text("Пока нет загруженных видео")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Нажмите '+ Загрузить видео', чтобы добавить первый видеоролик в сеть!")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(40)
                        .frame(maxWidth: .infinity)
                    } else {
                        LazyVStack(spacing: 20) {
                            ForEach(viewModel.videos) { video in
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
                                            } else {
                                                Rectangle().fill(Color.blue.opacity(0.2))
                                                    .frame(height: 200)
                                                    .cornerRadius(12)
                                            }
                                        }

                                        Text(video.durationFormatted)
                                            .font(.system(size: 12, weight: .bold))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.black.opacity(0.7))
                                            .foregroundColor(.white)
                                            .cornerRadius(6)
                                            .padding(8)
                                    }

                                    HStack(alignment: .top, spacing: 12) {
                                        AvatarView(user: video.author, size: 40)

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
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                }
                .padding(.vertical, 16)
            }
            .navigationBarTitle("Видео", displayMode: .inline)
            .sheet(isPresented: $showUploadModal) {
                UploadVideoView(viewModel: viewModel)
            }
        }
    }
}
