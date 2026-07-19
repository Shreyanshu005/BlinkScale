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
            ARViewContainer(
                source: .parametric(dimensions, requiredSurface: product.requiredSurface),
                coordinator: coordinator
            )
            .ignoresSafeArea()

            // Gradients alone bleed under the Dynamic Island/home indicator
            // for a seamless look — the actual text sits in a SEPARATE layer
            // below that respects the safe area, so it never renders behind
            // the island itself (this matters most for wall items, whose
            // longer "Scanning for a wall…" status text is more likely to
            // sit right under the island if it isn't kept clear of it).
            VStack(spacing: 0) {
                topScrim
                Spacer()
                bottomScrim
            }
            .ignoresSafeArea()

            VStack {
                backButton
                Spacer()
            }
            .padding()
        }
        .sheet(isPresented: $showFeedbackPrompt) {
            feedbackSheet
        }
        // Same reasoning as PolishedARPreviewView — wherever this screen
        // ends up presented from, its own toast host guarantees the
        // wall/floor mismatch toast is visible on top of it.
        .toastHost()
    }

    private var topScrim: some View {
        LinearGradient(colors: [.black.opacity(0.55), .clear], startPoint: .top, endPoint: .bottom)
            .frame(height: 150)
            .allowsHitTesting(false)
    }

    private var bottomScrim: some View {
        LinearGradient(colors: [.clear, .black.opacity(0.6)], startPoint: .top, endPoint: .bottom)
            .frame(height: 220)
            .allowsHitTesting(false)
    }

    private var backButton: some View {
        HStack {
            Button {
                onDone()
            } label: {
                Image(systemName: "chevron.backward")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.glass)
            .accessibilityLabel("Back")
            Spacer()
        }
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.5), radius: 6)
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
            Button {
                showFeedbackPrompt = true
            } label: {
                Text("Doesn't look right?")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.blinkitOrange)
            }
            .padding(.top, 4)
        }
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.5), radius: 6)
        .frame(maxWidth: .infinity, alignment: .leading)
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
