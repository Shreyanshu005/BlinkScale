//
//  SpaceFitCaptureView.swift
//  BlinkScalee
//
//  Entry point for "Find something that fits my space." Opens the camera
//  immediately on appear — no intro screen in between — then, once a photo
//  is captured, asks the one thing left: a free-text prompt for what the
//  user wants. The room advisor uses that optional detail to refine its
//  photo-based decor recommendations.
//

import SwiftUI
import UIKit

struct SpaceFitCaptureView: View {
    let onCancel: () -> Void
    let onPhotoCaptured: (CapturedSpacePhoto) -> Void

    /// Wraps *which* source to open together with *whether* to open it, as a
    /// single Identifiable value — see the historical note this file used to
    /// carry: two independent `@State` vars (a bool and an enum) raced on
    /// real devices, `.sheet(item:)` doesn't have that gap.
    private struct PickerRequest: Identifiable {
        let id = UUID()
        let source: UIImagePickerController.SourceType
    }

    @State private var pickerRequest: PickerRequest? = PickerRequest(
        source: UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
    )
    @State private var capturedImage: CGImage?
    @State private var prompt: String = ""
    @FocusState private var promptFocused: Bool

    var body: some View {
        Group {
            if let capturedImage {
                promptStep(image: capturedImage)
            } else {
                // The camera sheet is presented immediately from the initial
                // picker request — nothing needs to show behind it.
                AppPalette.background.ignoresSafeArea()
            }
        }
        .sheet(item: $pickerRequest) { request in
            ImagePicker(
                sourceType: request.source,
                onImagePicked: { cgImage in
                    pickerRequest = nil
                    capturedImage = cgImage
                },
                onCancel: {
                    pickerRequest = nil
                    // No photo yet and the picker was dismissed — nothing
                    // left to show, so back out of the flow entirely.
                    if capturedImage == nil {
                        onCancel()
                    }
                }
            )
        }
    }

    private func promptStep(image: CGImage) -> some View {
        VStack(spacing: 24) {
            header

            Spacer()

            Image(decorative: image, scale: 1)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 260)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .padding(.horizontal, 24)

            promptField

            Spacer()

            Button {
                onPhotoCaptured(CapturedSpacePhoto(
                    cgImage: image,
                    prompt: prompt
                ))
            } label: {
                Text("See recommendations")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .foregroundStyle(.white)
            .buttonStyle(.glass)
            .buttonBorderShape(.roundedRectangle(radius: 14))
            .padding(.horizontal)
            .padding(.bottom)
        }
        .background(AppPalette.background)
    }

    private var promptField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("What are you looking for?")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(.white.opacity(0.8))
                TextField("e.g. a plant, an air fryer, a study table…", text: $prompt)
                    .focused($promptFocused)
                    .submitLabel(.done)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Text("Leave blank for recommendations based on your room.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 24)
    }

    private var header: some View {
        HStack {
            Button(action: onCancel) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
            }
            .glassEffect(.regular.interactive(), in: Circle())
            Spacer()
            Text("Find for your room")
                .font(.headline)
            Spacer()
            Image(systemName: "xmark").opacity(0) // symmetry spacer
        }
        .padding()
    }
}

#Preview {
    SpaceFitCaptureView(onCancel: {}, onPhotoCaptured: { _ in })
}
