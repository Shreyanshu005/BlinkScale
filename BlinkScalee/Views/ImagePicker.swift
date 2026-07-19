//
//  ImagePicker.swift
//  BlinkScalee
//
//  Standard UIImagePickerController bridge — camera or photo library. This
//  is the one part of the space-fit flow that isn't beta/speculative API;
//  it's been stable UIKit since iOS 3, so unlike the FoundationModels calls
//  elsewhere in this app, there's no SDK/OS version-skew risk here.
//

import SwiftUI
import UIKit

struct ImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onImagePicked: (CGImage) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let uiImage = info[.originalImage] as? UIImage, let cgImage = normalizedCGImage(from: uiImage) {
                parent.onImagePicked(cgImage)
            } else {
                parent.onCancel()
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onCancel()
        }

        /// `CGImage` does not retain UIImage's orientation metadata. Redraw
        /// once so SwiftUI and the Foundation Model both receive upright
        /// pixels instead of the camera sensor's landscape image.
        private func normalizedCGImage(from image: UIImage) -> CGImage? {
            let format = UIGraphicsImageRendererFormat.default()
            format.scale = image.scale
            return UIGraphicsImageRenderer(size: image.size, format: format)
                .image { _ in image.draw(in: CGRect(origin: .zero, size: image.size)) }
                .cgImage
        }
    }
}
