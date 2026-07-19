//
//  SpaceFitResultView.swift
//  BlinkScalee
//
//  Shows a short, Siri-style recommendation for the shopper's room photo
//  (RoomAdvisor, on-device Foundation Models image understanding) alongside
//  catalog products that would suit it. No dimensions, no confidence badge,
//  no "estimated space" — just a spoken-style summary and tappable cards.
//

import SwiftUI
import UIKit

struct SpaceFitResultView: View {
    let photo: CapturedSpacePhoto
    let onSelectProduct: (MockProduct) -> Void
    let onDone: () -> Void

    private let columnGap: CGFloat = 12
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    @State private var summary: String = ""
    @State private var products: [MockProduct] = []
    @State private var isLoading = true

    // Measured off the grid's own ACTUAL proposed width at render time —
    // `UIScreen.main.bounds.width` turned out to be unreliable in some
    // environments (returned a value that made cards render wider than the
    // real screen), so this reads the real, current width directly instead.
    @State private var cardWidth: CGFloat?

    private let advisor = RoomAdvisor()

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 20) {
                    summaryCard

                    if !isLoading {
                        if products.isEmpty {
                            noFitCard
                        } else {
                            matchesGrid
                        }
                    }
                }
                .padding()
            }
            .background(AppPalette.background)
        }
        .preferredColorScheme(.dark)
        .task {
            let result = await advisor.recommend(image: photo.cgImage, prompt: photo.prompt, catalog: MockProduct.all)
            summary = result.summary
            products = result.products
            isLoading = false
        }
    }

    private var header: some View {
        HStack {
            Spacer()
            Text("For Your Space")
                .font(.headline)
            Spacer()
        }
        .overlay(alignment: .trailing) {
            Button(action: onDone) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
            }
            .glassEffect(.regular.interactive(), in: Circle())
            .padding(.trailing)
        }
        .padding(.top)
        .padding(.bottom, 8)
        .background(AppPalette.background)
    }

    private var summaryCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "sparkles")
                .foregroundStyle(.white.opacity(0.85))
                .font(.system(size: 16, weight: .semibold))
                .padding(.top, 2)

            if isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(.white.opacity(0.7))
                    Text("Looking at your room…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text(summary)
                    .font(.subheadline.weight(.medium))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppPalette.background.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var matchesGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recommended for you")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.75))

            LazyVGrid(columns: columns, spacing: columnGap) {
                ForEach(products) { product in
                    ProductCard(
                        product: product,
                        badge: product.id == products.first?.id ? .bestFit : nil,
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
            Image(systemName: "sparkles")
                .foregroundStyle(.secondary)
            Text("Nothing in our catalog feels right for this room yet.")
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.center)
            Text("Check back as we add more products.")
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
        photo: CapturedSpacePhoto(cgImage: UIImage(systemName: "photo")!.cgImage!, prompt: ""),
        onSelectProduct: { _ in },
        onDone: {}
    )
}
