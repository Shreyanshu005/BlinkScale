//
//  SpaceFitResultView.swift
//  BlinkScalee
//
//  Shows the estimated space alongside every catalog product that both
//  matches the user's free-text prompt (resolved by ProductIntentResolver)
//  AND fits inside the estimate (filtered/ranked by ProductSpaceMatcher) —
//  or an honest "nothing fits" message when the list comes back empty.
//  Never fabricates a recommendation just to have something to show.
//

import SwiftUI

struct SpaceFitResultView: View {
    let estimate: SpaceEstimate
    let matches: [MockProduct]
    let onSelectProduct: (MockProduct) -> Void
    let onDone: () -> Void
    let onRetry: () -> Void

    private let columnGap: CGFloat = 12
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    // Measured off the grid's own ACTUAL proposed width at render time —
    // `UIScreen.main.bounds.width` turned out to be unreliable in some
    // environments (returned a value that made cards render wider than the
    // real screen), so this reads the real, current width directly instead.
    @State private var cardWidth: CGFloat?

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 20) {
                    estimateCard

                    if matches.isEmpty {
                        noFitCard
                    } else {
                        matchesGrid
                    }
                }
                .padding()
            }
            .background(AppPalette.background)

            Button("Try Another Photo", action: onRetry)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.blinkitOrange)
                .padding(.bottom)
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack {
            Spacer()
            Text("Your Matches")
                .font(.headline)
            Spacer()
        }
        .overlay(alignment: .trailing) {
            Button(action: onDone) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .padding(.trailing)
        }
        .padding(.top)
        .padding(.bottom, 8)
        .background(AppPalette.background)
    }

    private var estimateCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Estimated Space")
                    .font(.headline)
                Spacer()
                ConfidenceBadge(confidence: estimate.confidence)
            }
            Text(estimate.spaceLabel)
                .font(.title3.weight(.bold))
            Text(estimate.reasoning)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppPalette.background.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var matchesGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(matches.count) thing\(matches.count == 1 ? "" : "s") that fit\(matches.count == 1 ? "s" : "")")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.blinkitOrange)

            LazyVGrid(columns: columns, spacing: columnGap) {
                ForEach(matches) { product in
                    ProductCard(
                        product: product,
                        badge: product.id == matches.first?.id ? .bestFit : nil,
                        width: cardWidth,
                        onSelect: { onSelectProduct(product) }
                    )
                }
            }
            .onGeometryChange(for: CGFloat.self) { proxy in
                (proxy.size.width - columnGap) / 2
            } action: { newValue in
                cardWidth = newValue
            }
        }
    }

    private var noFitCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text("Nothing in our catalog fits that space comfortably.")
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.center)
            Text("Try a spot with a bit more room, a different request, or check back as we add more products.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AppPalette.background.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    SpaceFitResultView(
        estimate: SpaceEstimate(availableWidthCM: 92, availableDepthCM: 60, confidence: .medium, reasoning: "Used the doorway width as a reference."),
        matches: Array(MockProduct.all.prefix(3)),
        onSelectProduct: { _ in },
        onDone: {},
        onRetry: {}
    )
}
