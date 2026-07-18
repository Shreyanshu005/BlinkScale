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
    @State private var scanLineOffset: CGFloat = -1

    private let analyzer = DimensionAnalyzer()

    /// Rough progress indicator: each of the 5 fields worth 20%.
    private var progress: Double {
        let filled = [partialShape != nil, partialWidth != nil, partialHeight != nil, partialDepth != nil, partialConfidence != nil]
        return Double(filled.filter { $0 }.count) / 5.0
    }

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Text("Analyzing dimensions")
                .font(.title3.weight(.semibold))

            imageWithScanline

            ProgressView(value: progress)
                .tint(.blinkitOrange)
                .frame(maxWidth: 260)

            VStack(alignment: .leading, spacing: 10) {
                fieldRow(label: "Shape", value: partialShape?.displayName)
                fieldRow(label: "Width", value: partialWidth.map { "\(Int($0)) cm" })
                fieldRow(label: "Height", value: partialHeight.map { "\(Int($0)) cm" })
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

                    // Demo-safety net: the on-device model can be briefly
                    // unavailable (still downloading, guardrail rejection,
                    // etc.) — never let that dead-end a live demo.
                    Button("Use estimated dimensions instead") {
                        onComplete(product.fallbackDimensions)
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

    private var imageWithScanline: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor(hex: product.tintHex) ?? .systemGray).opacity(0.12))
            Image(systemName: product.imageSystemName)
                .font(.system(size: 80))
                .foregroundStyle(Color(UIColor(hex: product.tintHex) ?? .systemGray))

            LinearGradient(colors: [.clear, Color.blinkitOrange.opacity(0.8), .clear], startPoint: .top, endPoint: .bottom)
                .frame(height: 40)
                .offset(y: scanLineOffset * 180 + 90)
                .onAppear {
                    withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: true)) {
                        scanLineOffset = 1
                    }
                }
        }
        .frame(width: 200, height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
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
