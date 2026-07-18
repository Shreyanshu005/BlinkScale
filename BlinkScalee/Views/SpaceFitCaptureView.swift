//
//  SpaceFitCaptureView.swift
//  BlinkScalee
//
//  Entry point for "Find something that fits my space." Collects two
//  things before the AI ever runs: a free-text prompt for what the user
//  wants (any product in the catalog, not just tables — ProductIntentResolver
//  interprets it later) and a photo of the empty spot. Coaches the user to
//  include a reference object in frame — since SpaceAnalyzer has no stated
//  measurement to anchor on, the quality of this photo directly determines
//  how good the estimate can be.
//

import SwiftUI
import UIKit

struct SpaceFitCaptureView: View {
    let onCancel: () -> Void
    let onPhotoCaptured: (CapturedSpacePhoto) -> Void

    @State private var prompt: String = ""
    @State private var showPicker = false
    @State private var pickerSource: UIImagePickerController.SourceType = .photoLibrary
    @FocusState private var promptFocused: Bool

    var body: some View {
        VStack(spacing: 24) {
            header

            Spacer()

            Image(systemName: "camera.viewfinder")
                .font(.system(size: 64))
                .foregroundStyle(Color.blinkitOrange)

            Text("Find something that fits your space")
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)

            Text("Take a photo of the empty spot. Include a doorway, floor tile, or piece of furniture in frame — it gives the AI something to judge scale against.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            promptField

            Spacer()

            actionButtons
        }
        .sheet(isPresented: $showPicker) {
            ImagePicker(
                sourceType: pickerSource,
                onImagePicked: { cgImage in
                    showPicker = false
                    onPhotoCaptured(CapturedSpacePhoto(cgImage: cgImage, prompt: prompt))
                },
                onCancel: {
                    showPicker = false
                }
            )
        }
    }

    private var promptField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("What are you looking for?")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color.blinkitOrange)
                TextField("e.g. a plant, an air fryer, a study table…", text: $prompt)
                    .focused($promptFocused)
                    .submitLabel(.done)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Text("Leave blank to see anything that fits.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 24)
    }

    private var header: some View {
        HStack {
            Button(action: onCancel) {
                Image(systemName: "xmark")
                    .font(.title3.weight(.semibold))
            }
            Spacer()
            Text("Space Fit Finder")
                .font(.headline)
            Spacer()
            Image(systemName: "xmark").opacity(0) // symmetry spacer
        }
        .padding()
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button {
                    pickerSource = .camera
                    showPicker = true
                } label: {
                    Label("Take Photo", systemImage: "camera.fill")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.blinkitOrange)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }

            Button {
                pickerSource = .photoLibrary
                showPicker = true
            } label: {
                Label("Choose from Library", systemImage: "photo.on.rectangle")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppPalette.background.opacity(0.72))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
}

#Preview {
    SpaceFitCaptureView(onCancel: {}, onPhotoCaptured: { _ in })
}
