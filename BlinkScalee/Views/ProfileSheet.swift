//
//  ProfileSheet.swift
//  BlinkScalee
//

import ImagePlayground
import PhotosUI
import SwiftUI
import UIKit

struct ProfileSheet: View {
    @ObservedObject var profile: UserProfile
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showsImagePlayground = false
    @State private var showsUnavailableAlert = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 14) {
                        avatar

                        Menu {
                            Button("Create with Image Playground", systemImage: "sparkles") {
                                if ImagePlaygroundViewController.isAvailable {
                                    showsImagePlayground = true
                                } else {
                                    showsUnavailableAlert = true
                                }
                            }

                            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                Label("Choose from Photos", systemImage: "photo.on.rectangle")
                            }
                        } label: {
                            Label("Change avatar", systemImage: "camera")
                                .font(.subheadline.weight(.semibold))
                        }
                        .buttonStyle(.glass)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .listRowBackground(Color.clear)
                }

                Section("Profile") {
                    TextField("Your name", text: $profile.displayName)
                        .textContentType(.name)
                }

                Section("Your BlinkScalee") {
                    Label("Saved items", systemImage: "heart")
                    Label("Orders", systemImage: "bag")
                    Label("Help & support", systemImage: "questionmark.circle")
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppPalette.background)
            .foregroundStyle(.white)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done", action: dismiss.callAsFunction)
                        .foregroundStyle(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
        // Empty concepts intentionally let the shopper write their own
        // Image Playground prompt and choose the generation style.
        .imagePlaygroundSheet(
            isPresented: $showsImagePlayground,
            concepts: [],
            onCompletion: saveImagePlaygroundAvatar,
            onCancellation: {}
        )
        .task(id: selectedPhoto) {
            guard let selectedPhoto,
                  let data = try? await selectedPhoto.loadTransferable(type: Data.self) else { return }
            profile.avatarData = data
        }
        .alert("Image Playground is unavailable", isPresented: $showsUnavailableAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You can still choose an avatar from Photos.")
        }
    }

    private var avatar: some View {
        Group {
            if let data = profile.avatarData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: 34, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.white.opacity(0.14))
            }
        }
        .frame(width: 108, height: 108)
        .clipShape(Circle())
        .overlay(Circle().stroke(.white.opacity(0.25), lineWidth: 1))
    }

    private func saveImagePlaygroundAvatar(from url: URL) {
        profile.avatarData = try? Data(contentsOf: url)
    }
}
