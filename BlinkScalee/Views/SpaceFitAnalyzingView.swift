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

    private var progress: Double {
        let filled = [partialWidth != nil, partialDepth != nil, partialConfidence != nil, partialReasoning != nil]
        return Double(filled.filter { $0 }.count) / 4.0
    }

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Text(isMatchingProducts ? "Finding what fits" : "Reading your space")
                .font(.title3.weight(.semibold))
                .contentTransition(.opacity)
                .animation(.easeOut(duration: 0.2), value: isMatchingProducts)

            capturedImagePreview

            ProgressView(value: progress)
                .tint(.blinkitOrange)
                .frame(maxWidth: 260)

            VStack(alignment: .leading, spacing: 10) {
                fieldRow(label: "Width", value: partialWidth.map { "\(Int($0)) cm" })
                fieldRow(label: "Depth", value: partialDepth.map { "\(Int($0)) cm" })
                if let confidence = partialConfidence {
                    HStack {
                        Text("Confidence")
                            .foregroundStyle(.secondary)
                        Spacer()
                        ConfidenceBadge(confidence: confidence)
                    }
                }
            }
            .font(.subheadline)
            .frame(maxWidth: 260)

            if let errorMessage {
                VStack(spacing: 10) {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    Button("Try Again") {
                        self.errorMessage = nil
                        Task { await runAnalysis() }
                    }
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.blinkitOrange)
                }
            }

            Spacer()

            Button("Cancel", action: onCancel)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
        .task {
            await runAnalysis()
        }
    }

    private var capturedImagePreview: some View {
        Image(decorative: photo.cgImage, scale: 1)
            .resizable()
            .scaledToFill()
            .frame(width: 200, height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.blinkitOrange, lineWidth: 2))
            .clipped()
    }

    @ViewBuilder
    private func fieldRow(label: String, value: String?) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            if let value {
                Text(value)
                    .fontWeight(.medium)
            } else {
                Text("···")
                    .foregroundStyle(.tertiary)
            }
        }
        .animation(.easeOut(duration: 0.25), value: value)
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
