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

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

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

            Button("Try Another Photo", action: onRetry)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.blinkitOrange)
                .padding(.bottom)
        }
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
        .background(.ultraThinMaterial)
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
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var matchesGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(matches.count) thing\(matches.count == 1 ? "" : "s") that fit\(matches.count == 1 ? "s" : "")")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.blinkitOrange)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(matches) { product in
                    Button {
                        onSelectProduct(product)
                    } label: {
                        MatchCard(product: product, isTopPick: product.id == matches.first?.id)
                    }
                    .buttonStyle(.plain)
                }
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
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct MatchCard: View {
    let product: MockProduct
    let isTopPick: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor(hex: product.tintHex) ?? .systemGray).opacity(0.12))
                Image(systemName: product.imageSystemName)
                    .font(.system(size: 36))
                    .foregroundStyle(Color(UIColor(hex: product.tintHex) ?? .systemGray))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                if isTopPick {
                    Text("BEST FIT")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.blinkitOrange)
                        .clipShape(Capsule())
                        .padding(6)
                }
            }
            .frame(height: 90)

            Text(product.name)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
                .foregroundStyle(.primary)

            Text("\(Int(product.referenceDimensionsCM.width)) × \(Int(product.referenceDimensionsCM.depth)) cm")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("₹\(product.priceRupees)")
                .font(.subheadline.weight(.bold))
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
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
