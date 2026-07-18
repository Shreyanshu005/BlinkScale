//
//  ARPreviewView.swift
//  BlinkScalee
//
//  The money shot. Live camera feed, floor scan indicator, tap-to-place,
//  and the dimension card that makes the judge go "oh, it actually knows
//  how big this is." Dimensions can be refined in place via "Doesn't look
//  right?" without leaving AR.
//

import SwiftUI

struct ARPreviewView: View {
    let product: MockProduct
    let onDone: () -> Void

    @State private var dimensions: ProductDimensions
    @StateObject private var coordinator = ARCoordinator()
    @State private var showFeedbackPrompt = false
    @State private var feedbackText = ""
    @State private var isRefining = false

    private let analyzer = DimensionAnalyzer()

    init(product: MockProduct, dimensions: ProductDimensions, onDone: @escaping () -> Void) {
        self.product = product
        self._dimensions = State(initialValue: dimensions)
        self.onDone = onDone
    }

    var body: some View {
        ZStack {
            ARViewContainer(source: .parametric(dimensions), coordinator: coordinator)
                .ignoresSafeArea()

            VStack {
                topStatusBar
                Spacer()
                if coordinator.isPlaced {
                    dimensionCard
                }
                controlBar
            }
            .padding()
        }
        .sheet(isPresented: $showFeedbackPrompt) {
            feedbackSheet
        }
    }

    private var topStatusBar: some View {
        HStack {
            Image(systemName: coordinator.isFloorDetected ? "checkmark.circle.fill" : "arrow.triangle.2.circlepath")
                .foregroundStyle(coordinator.isFloorDetected ? .green : .white)
            Text(coordinator.scanningStatusText)
                .fontWeight(.medium)
            Spacer()
            Button {
                onDone()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
            }
        }
        .foregroundStyle(.white)
        .padding()
        .background(.black.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var dimensionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: product.imageSystemName)
                Text(product.name)
                    .fontWeight(.semibold)
                Spacer()
                ConfidenceBadge(confidence: dimensions.confidence)
            }
            Text(dimensions.dimensionLabel)
                .font(.title3.weight(.bold))
            Label("Walk around it", systemImage: "figure.walk")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button {
                showFeedbackPrompt = true
            } label: {
                Text("Doesn't look right?")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.blinkitOrange)
            }
            .padding(.top, 4)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var controlBar: some View {
        HStack(spacing: 12) {
            controlPill(icon: "arrow.up.left.and.arrow.down.right", label: "Pinch to resize")
            controlPill(icon: "rotate.3d", label: "Twist to rotate")
            controlPill(icon: "hand.tap.fill", label: "Hold to re-place")
        }
        .font(.caption)
        .foregroundStyle(.white)
        .opacity(coordinator.isPlaced ? 1 : 0)
    }

    private func controlPill(icon: String, label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(label)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.black.opacity(0.35))
        .clipShape(Capsule())
    }

    private var feedbackSheet: some View {
        VStack(spacing: 16) {
            Text("What looks off?")
                .font(.headline)
            TextField("e.g. \"too tall\" or \"it's more of a box shape\"", text: $feedbackText)
                .textFieldStyle(.roundedBorder)
            Button {
                Task { await refine() }
            } label: {
                if isRefining {
                    ProgressView()
                } else {
                    Text("Re-analyze")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.blinkitOrange)
            .disabled(feedbackText.trimmingCharacters(in: .whitespaces).isEmpty || isRefining)
            Spacer()
        }
        .padding()
        .presentationDetents([.height(220)])
    }

    private func refine() async {
        guard let image = product.renderedCGImage else { return }
        isRefining = true
        defer { isRefining = false }
        do {
            let updated = try await analyzer.refine(previous: dimensions, userFeedback: feedbackText, image: image)
            dimensions = updated
            coordinator.updateDimensions(updated)
            showFeedbackPrompt = false
            feedbackText = ""
        } catch {
            // Keep the sheet open so the user can retry the wording.
        }
    }
}
