//
//  AnalysisView.swift
//  BlinkScalee
//
//  The AI "magic moment." Streams ProductDimensions from Foundation Models
//  field-by-field so width/height/depth/shape visibly fill in one at a time
//  instead of showing a blank spinner — this is the screen that sells "this
//  is real on-device AI, not a canned demo."
//

import SwiftUI

struct AnalysisView: View {
    let product: MockProduct
    let onComplete: (ProductDimensions) -> Void
    let onCancel: () -> Void

    @State private var partialWidth: Double?
    @State private var partialHeight: Double?
    @State private var partialDepth: Double?
    @State private var partialShape: ProductShape?
    @State private var partialConfidence: DimensionConfidence?
    @State private var errorMessage: String?

    private let analyzer = DimensionAnalyzer()

    var body: some View {
        ZStack {
            // The product's own tinted icon, heavily blurred, so the loading
            // state still feels connected to the item being analyzed instead
            // of a generic blank screen.
            Color(UIColor(hex: product.tintHex) ?? .systemGray)
                .overlay {
                    Image(systemName: product.imageSystemName)
                        .font(.system(size: 160))
                        .foregroundStyle(.white.opacity(0.3))
                }
                .blur(radius: 40)
                .overlay(.black.opacity(0.45))
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ProgressView()
                    .controlSize(.large)
                    .tint(.white)

                Text("Analyzing dimensions…")
                    .font(.headline)
                    .foregroundStyle(.white)

                if let errorMessage {
                    VStack(spacing: 10) {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)

                        // Demo-safety net: the on-device model can be briefly
                        // unavailable (still downloading, guardrail
                        // rejection, etc.) — never let that dead-end a live
                        // demo.
                        Button("Use estimated dimensions instead") {
                            onComplete(product.fallbackDimensions)
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

        guard let image = product.renderedCGImage else {
            errorMessage = "Couldn't prepare the product image."
            return
        }

        do {
            for try await partial in analyzer.streamAnalysis(image: image) {
                partialShape = partial.shape
                partialWidth = partial.widthCM
                partialHeight = partial.heightCM
                partialDepth = partial.depthCM
                partialConfidence = partial.confidence
            }

            // The stream should have completed every field by the time it
            // finishes. Assemble the final struct from the last partial
            // rather than re-running inference — only fall back to a fresh
            // one-shot call in the rare case the stream ended early.
            if let shape = partialShape, let width = partialWidth,
               let height = partialHeight, let depth = partialDepth,
               let confidence = partialConfidence {
                let finalDims = ProductDimensions(
                    shape: shape, widthCM: width, heightCM: height,
                    depthCM: depth, confidence: confidence
                )
                onComplete(finalDims)
            } else {
                let finalDims = try await analyzer.analyze(image: image)
                onComplete(finalDims)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct ConfidenceBadge: View {
    let confidence: DimensionConfidence

    private var color: Color {
        switch confidence {
        case .high: return .green
        case .medium: return .yellow
        case .low: return .red
        }
    }

    var body: some View {
        Text(confidence.rawValue.capitalized)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.18))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

#Preview {
    AnalysisView(product: MockProduct.all[0], onComplete: { _ in }, onCancel: {})
}
