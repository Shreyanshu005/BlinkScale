//
//  SpaceFitResultView.swift
//  BlinkScalee
//
//  Shows the estimated space alongside the best-fitting table from
//  TableMatcher (or an honest "nothing fits" message — never fabricates a
//  recommendation just to have something to show).
//

import SwiftUI

struct SpaceFitResultView: View {
    let estimate: SpaceEstimate
    let recommendedTable: MockProduct?
    let onDone: () -> Void
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 20) {
                    estimateCard

                    if let table = recommendedTable {
                        recommendationCard(for: table)
                    } else {
                        noFitCard
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
            Text("Your Match")
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

    private func recommendationCard(for table: MockProduct) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("RECOMMENDED")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.blinkitOrange)

            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor(hex: table.tintHex) ?? .systemGray).opacity(0.12))
                    Image(systemName: table.imageSystemName)
                        .font(.system(size: 32))
                        .foregroundStyle(Color(UIColor(hex: table.tintHex) ?? .systemGray))
                }
                .frame(width: 64, height: 64)

                VStack(alignment: .leading, spacing: 4) {
                    Text(table.name)
                        .font(.subheadline.weight(.semibold))
                    Text("\(Int(table.referenceDimensionsCM.width)) × \(Int(table.referenceDimensionsCM.depth)) cm")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("₹\(table.priceRupees)")
                        .font(.subheadline.weight(.bold))
                }
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.blinkitOrange.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var noFitCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text("None of our tables fit that space comfortably.")
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.center)
            Text("Try a spot with a bit more room, or check back as we add more sizes.")
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

#Preview {
    SpaceFitResultView(
        estimate: SpaceEstimate(availableWidthCM: 92, availableDepthCM: 60, confidence: .medium, reasoning: "Used the doorway width as a reference."),
        recommendedTable: MockProduct.tableCatalog.first,
        onDone: {},
        onRetry: {}
    )
}
