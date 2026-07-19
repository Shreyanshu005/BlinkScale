//
//  OnboardingView.swift
//  BlinkScalee
//
//  Placeholder onboarding screen. Uses the animated Aurora shader as a
//  blurred, dimmed background, with placeholder copy and a "Next" button
//  that advances to the homepage placeholder.
//

import AVFoundation
import SwiftUI
import UIKit

struct OnboardingView: View {
    var onNext: () -> Void

    @State private var welcomeText = ""
    @State private var brandText = ""
    @State private var taglineText = ""
    @State private var isNextEnabled = false
    @State private var hasStartedAnimation = false

    var body: some View {
        ZStack {
            // Solid base so transparent aurora regions stay dark.
            AppPalette.background
                .ignoresSafeArea()

            // Animated aurora, blurred and pushed back behind a scrim.
            AuroraView()
                .blur(radius: 40)
                .opacity(0.9)
                .ignoresSafeArea()

            // Darkening scrim for legible foreground content.
            LinearGradient(
                colors: [AppPalette.background.opacity(0.1), AppPalette.background.opacity(0.75)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Foreground placeholder content.
            VStack(spacing: 16) {
                Spacer()

                LoopingOnboardingVideo()
                    .frame(width: 300, height: 300)

                VStack(spacing: 6) {
                    Text(welcomeText)
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                        .opacity(welcomeText.isEmpty ? 0 : 1)
                        .offset(y: welcomeText.isEmpty ? 12 : 0)

                    (
                        Text(String(brandText.prefix(5))).fontWeight(.heavy)
                            + Text(String(brandText.dropFirst(5))).fontWeight(.heavy).foregroundStyle(Color.blinkitOrange)
                    )
                    .font(.system(size: 36, design: .rounded))
                    .foregroundStyle(.white)
                    .opacity(brandText.isEmpty ? 0 : 1)
                    .scaleEffect(brandText.isEmpty ? 0.92 : 1)
                    .offset(y: brandText.isEmpty ? 16 : 0)

                    Text(taglineText)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .padding(.top, 6)
                        .opacity(taglineText.isEmpty ? 0 : 1)
                        .offset(y: taglineText.isEmpty ? 12 : 0)
                }
                .padding(.top, 8)

                Spacer()

                Button(action: onNext) {
                    Text("Next")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .glassEffect(.regular.tint(Color.blinkitOrange).interactive(), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .disabled(!isNextEnabled)
                .opacity(isNextEnabled ? 1 : 0.45)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 24)
        }
        .task {
            guard !hasStartedAnimation else { return }
            hasStartedAnimation = true

            haptic()
            await typewrite("Welcome to") { welcomeText = $0 }
            try? await Task.sleep(for: .milliseconds(180))
            guard !Task.isCancelled else { return }
            haptic()
            await typewrite("BlinkScalee") { brandText = $0 }
            try? await Task.sleep(for: .milliseconds(180))
            guard !Task.isCancelled else { return }
            haptic()
            await typewrite("See it in your space before it's in your cart.") { taglineText = $0 }
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.25)) {
                isNextEnabled = true
            }
        }
    }

    private func typewrite(_ text: String, update: @escaping (String) -> Void) async {
        var result = ""
        for character in text {
            guard !Task.isCancelled else { return }
            result.append(character)
            update(result)
            try? await Task.sleep(for: .milliseconds(32))
        }
    }

    private func haptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
}

private struct LoopingOnboardingVideo: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.playerLayer.player = context.coordinator.player
        context.coordinator.player.play()
        return view
    }

    func updateUIView(_ uiView: PlayerView, context: Context) {}

    static func dismantleUIView(_ uiView: PlayerView, coordinator: Coordinator) {
        coordinator.player.pause()
    }

    final class Coordinator {
        let player = AVQueuePlayer()
        private var looper: AVPlayerLooper?

        init() {
            // The movie lives in an asset-catalog data set. Those files are
            // not exposed through Bundle.url(forResource:), so materialize
            // its data at a temporary URL before handing it to AVPlayer.
            guard let asset = NSDataAsset(name: "onboardingVideo") else { return }
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("BlinkScalee-onboarding.mov")
            do {
                try asset.data.write(to: url, options: .atomic)
            } catch {
                return
            }
            looper = AVPlayerLooper(player: player, templateItem: AVPlayerItem(url: url))
            player.isMuted = true
        }
    }
}

private final class PlayerView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }

    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        playerLayer.videoGravity = .resizeAspect
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

#Preview {
    OnboardingView(onNext: {})
}
