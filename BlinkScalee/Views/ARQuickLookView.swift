//
//  ARQuickLookView.swift
//  BlinkScalee
//
//  Native "View in AR" via QLPreviewController (stable, long-standing
//  QuickLook API, not the beta FoundationModels/RealityKit surface).
//
//  NOT currently used by BlinkitProductPageView — it switched to
//  PolishedARPreviewView (custom ARView + ARCoordinator) instead, since
//  Quick Look offers no way to correct a usdz's baked-in scale and only
//  the generic system gesture set. Kept here in case a plain, zero-code
//  system AR viewer is useful again later; `arModelURL` below is still
//  used by BlinkitProductPageView regardless of which viewer is active.
//

import SwiftUI
import QuickLook

struct ARQuickLookView: UIViewControllerRepresentable {
    let modelURL: URL

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(url: modelURL)
    }

    final class Coordinator: NSObject, QLPreviewControllerDataSource {
        let url: URL

        init(url: URL) {
            self.url = url
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            1
        }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            url as NSURL
        }
    }
}

extension BlinkitProductPageContent {
    /// Resolves `arModelResourceName` to an actual bundled file URL. `nil`
    /// if there's no model name set, or the .usdz hasn't been added to the
    /// Xcode project's resources yet.
    var arModelURL: URL? {
        guard let name = arModelResourceName else { return nil }
        return Bundle.main.url(forResource: name, withExtension: "usdz")
    }
}
