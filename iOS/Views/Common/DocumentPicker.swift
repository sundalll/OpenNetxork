import SwiftUI
import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

public struct DocumentPicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    public var allowedContentTypes: [UTType]
    public var onFilePicked: (URL) -> Void

    public init(allowedContentTypes: [UTType] = [.audio, .mp3, .wav], onFilePicked: @escaping (URL) -> Void) {
        self.allowedContentTypes = allowedContentTypes
        self.onFilePicked = onFilePicked
    }

    public func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: allowedContentTypes, asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    public func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker

        init(_ parent: DocumentPicker) {
            self.parent = parent
        }

        public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            parent.onFilePicked(url)
            parent.presentationMode.wrappedValue.dismiss()
        }

        public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
