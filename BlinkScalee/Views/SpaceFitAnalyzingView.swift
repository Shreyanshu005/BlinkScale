//
//  SpaceFitAnalyzingView.swift
//  BlinkScalee
//
//  Same streaming-reveal treatment as AnalysisView, applied to SpaceEstimate
//  instead of ProductDimensions. No demo-safety "use fallback dims" button
//  here, unlike AnalysisView — there's no ground truth for an arbitrary
//  room photo to fall back to, so on failure we just offer a clean retry.
//
//  Runs in two phases: first SpaceAnalyzer streams the room-size estimate
//  (as before), then — once that's done — ProductIntentResolver +
//  ProductSpaceMatcher run quietly to turn the user's free-text prompt into
//  a ranked list of real catalog products that actually fit. Both phases
//  need to finish before `onComplete` fires, since the result screen shows
//  the estimate AND the matches together.
//

import SwiftUI

struct SpaceFitAnalyzingView: View {
    let photo: CapturedSpacePhoto
    let onComplete: (SpaceEstimate, [MockProduct]) -> Void
    let onCancel: () -> Void

    @State private var partialWidth: Double?
    @State private var partialDepth: Double?
    @State private var partialConfidence: DimensionConfidence?
    @State private var partialReasoning: String?
    @State private var errorMessage: String?
    @State private var isMatchingProducts = false

    private let analyzer = SpaceAnalyzer()
    private let intentResolver = ProductIntentResolver()

    var body: some View {
        ZStack {
            // The captured photo itself, heavily blurred, so the loading
            // state still feels connected to what the user just took a
            // photo of instead of a generic blank screen.
            Image(decorative: photo.cgImage, scale: 1)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .blur(radius: 40)
                .overlay(.black.opacity(0.45))
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ProgressView()
                    .controlSize(.large)
                    .tint(.white)

                Text(isMatchingProducts ? "Finding what fits…" : "Reading your space…")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .contentTransition(.opacity)
                    .animation(.easeOut(duration: 0.2), value: isMatchingProducts)

                if let errorMessage {
                    VStack(spacing: 10) {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)

                        Button("Try Again") {
                            self.errorMessage = nil
                            Task { await runAnalysis() }
                        }
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.blinkitOrange)
                    }
                    .padding(.top, 8)
                }
            }

            VStack {
                Spacer()
                Button("Cancel", action: onCancel)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.bottom, 24)
            }
        }
        .task {
            await runAnalysis()
        }
    }

    private func runAnalysis() async {
        if let reason = DimensionAnalyzer.availabilityReason {
            errorMessage = "On-device AI isn't ready right now (\(reason))."
            return
        }

        do {
            for try await partial in analyzer.streamEstimate(image: photo.cgImage) {
                partialWidth = partial.availableWidthCM
                partialDepth = partial.availableDepthCM
                partialConfidence = partial.confidence
                partialReasoning = partial.reasoning
            }

            let finalEstimate: SpaceEstimate
            if let width = partialWidth, let depth = partialDepth,
               let confidence = partialConfidence, let reasoning = partialReasoning {
                finalEstimate = SpaceEstimate(
                    availableWidthCM: width, availableDepthCM: depth,
                    confidence: confidence, reasoning: reasoning
                )
            } else {
                finalEstimate = try await analyzer.estimateSpace(image: photo.cgImage)
            }

            await finishMatching(estimate: finalEstimate)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Second phase: resolve the free-text prompt against the real catalog,
    /// then keep only the resolved candidates that actually fit the
    /// estimated space, ranked largest-fit first.
    private func finishMatching(estimate: SpaceEstimate) async {
        isMatchingProducts = true
        let candidates = await intentResolver.resolveMatches(prompt: photo.prompt, catalog: MockProduct.all)
        let matches = ProductSpaceMatcher.fittingMatches(for: estimate, candidates: candidates)
        onComplete(estimate, matches)
    }
}
