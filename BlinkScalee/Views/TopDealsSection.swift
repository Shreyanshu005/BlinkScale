//
//  TopDealsSection.swift
//  BlinkScalee
//
//  Reusable "Top Deals" grid — heading plus the full product catalog rendered
//  with the shared ProductCard, same as ProductCatalogView's grid.
//

import SwiftUI

struct TopDealsSection: View {
    let onSelectProduct: (MockProduct) -> Void

    // Same horizontalPadding/columnGap pair used by CategoryProductsSection/
    // CategoryDetailView/SearchProductsView, so Home/Category/Search all
    // compute the identical hard card width.
    private let horizontalPadding: CGFloat = 16
    private let columnGap: CGFloat = 20
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    // Measured off the grid's own ACTUAL proposed width at render time —
    // `UIScreen.main.bounds.width` turned out to be unreliable in some
    // environments (returned a value that made cards render wider than the
    // real screen), so this reads the real, current width directly instead.
    @State private var cardWidth: CGFloat?
    @State private var gridWidth: CGFloat? // TEMPORARY diagnostic

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top Deals")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)

            // TEMPORARY DIAGNOSTIC — remove once the overflow bug is
            // root-caused. Shows the actual measured grid width and computed
            // card width on screen, since three different computation
            // methods have all produced identical-looking overflow, which
            // means we need real numbers instead of more guessing.
            Text("DEBUG grid=\(gridWidth.map { String(format: "%.0f", $0) } ?? "nil")  card=\(cardWidth.map { String(format: "%.0f", $0) } ?? "nil")  screen=\(String(format: "%.0f", UIScreen.main.bounds.width))")
                .font(.caption2)
                .foregroundStyle(.yellow)

            LazyVGrid(columns: columns, spacing: columnGap) {
                ForEach(MockProduct.all) { product in
                    ProductCard(
                        product: product,
                        width: cardWidth,
                        onSelect: { onSelectProduct(product) }
                    )
                }
            }
            .background(Color.blue.opacity(0.15)) // TEMPORARY — outlines the grid's own actual bounds
            .onGeometryChange(for: CGFloat.self) { proxy in
                gridWidth = proxy.size.width
                return (proxy.size.width - columnGap) / 2
            } action: { newValue in
                cardWidth = newValue
            }
        }
        .padding(horizontalPadding)
        .background(Color.red.opacity(0.15)) // TEMPORARY — outlines this section's own actual bounds
    }
}

#Preview {
    ScrollView {
        TopDealsSection(onSelectProduct: { _ in })
    }
    .background(AppPalette.background)
    .preferredColorScheme(.dark)
}
