//
//  SpaceFitCaptureView.swift
//  BlinkScalee
//
//  Entry point for "Find a table for my space." Coaches the user to
//  include a reference object in frame — since SpaceAnalyzer has no stated
//  measurement to anchor on, the quality of this photo directly determines
//  how good the estimate can be.
//

import SwiftUI
import UIKit

struct SpaceFitCaptureView: View {
    let onCancel: () -> Void
    let onPhotoCaptured: (CapturedSpacePhoto) -> Void

    @State private var showPicker = false
    @State private var pickerSource: UIImagePickerController.SourceType = .photoLibrary

    var body: some View {
        VStack(spacing: 24) {
            header

            Spacer()

            Image(systemName: "camera.viewfinder")
                .font(.system(size: 64))
                .foregroundStyle(Color.blinkitOrange)

            Text("Find a table for your space")
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)

            Text("Take a photo of the empty spot. Include a doorway, floor tile, or piece of furniture in frame — it gives the AI something to judge scale against.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            actionButtons
        }
        .sheet(isPresented: $showPicker) {
            ImagePicker(
                sourceType: pickerSource,
                onImagePicked: { cgImage in
                    showPicker = false
                    onPhotoCaptured(CapturedSpacePhoto(cgImage: cgImage))
                },
                onCancel: {
                    showPicker = false
                }
            )
        }
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
                    .background(Color(.secondarySystemBackground))
                    .foregroundStyle(.primary)
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
