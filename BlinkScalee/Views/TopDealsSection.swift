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

    // Measured off the grid's own actual proposed width at render time.
    @State private var cardWidth: CGFloat?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top Deals")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)

            LazyVGrid(columns: columns, spacing: columnGap) {
                ForEach(MockProduct.all) { product in
                    ProductCard(
                        product: product,
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
        .padding(horizontalPadding)
    }
}

#Preview {
    ScrollView {
        TopDealsSection(onSelectProduct: { _ in })
    }
    .background(AppPalette.background)
    .preferredColorScheme(.dark)
}
