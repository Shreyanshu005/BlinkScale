//
//  CategoryProductsSection.swift
//  BlinkScalee
//
//  Reusable "products grouped under a category heading" block — used by
//  ProductCatalogView to render one section per product category. Grouping
//  is driven entirely by MockProduct.category, so adding new products (or
//  new categories) later needs no changes here.
//

import SwiftUI

struct CategoryProductsSection: View {
    let title: String
    let products: [MockProduct]
    let onSelectProduct: (MockProduct) -> Void

    // Same horizontalPadding/columnGap pair used by TopDealsSection/
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

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)

            LazyVGrid(columns: columns, spacing: columnGap) {
                ForEach(products) { product in
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
        .padding(.horizontal, horizontalPadding)
    }
}

#Preview {
    ScrollView {
        CategoryProductsSection(
            title: "Plants",
            products: MockProduct.all.filter { $0.category == "Plants" },
            onSelectProduct: { _ in }
        )
    }
    .background(AppPalette.background)
    .preferredColorScheme(.dark)
}
