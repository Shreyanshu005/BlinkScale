//
//  CategoryDetailView.swift
//  BlinkScalee
//
//  Single-category product grid, pushed via NavigationStack when a
//  household category tile is tapped on Home — gives a native push/pop
//  transition into just that category's products instead of jumping to a
//  different tab.
//

import SwiftUI

/// Value type for `.navigationDestination(for: CategoryRoute.self)` — just a
/// category name, but its own type keeps it from colliding with any other
/// `String` that might one day be pushed onto the same NavigationStack.
struct CategoryRoute: Hashable {
    let name: String
}

struct CategoryDetailView: View {
    let category: String
    let products: [MockProduct]
    let onSelectProduct: (MockProduct) -> Void

    // Same horizontalPadding/columnGap pair used by TopDealsSection/
    // CategoryProductsSection/SearchProductsView, so Home/Category/Search
    // all compute the identical hard card width.
    private let horizontalPadding: CGFloat = 16
    private let columnGap: CGFloat = 20
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    // Measured off the grid's own ACTUAL proposed width at render time —
    // `UIScreen.main.bounds.width` turned out to be unreliable in some
    // environments (returned a value that made cards render wider than the
    // real screen), so this reads the real, current width directly instead.
    @State private var cardWidth: CGFloat?

    var body: some View {
        ScrollView {
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
            .padding(horizontalPadding)
        }
        .background(AppPalette.background)
        .navigationTitle(category)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        CategoryDetailView(
            category: "Plants",
            products: MockProduct.all.filter { $0.category == "Plants" },
            onSelectProduct: { _ in }
        )
        .navigationDestination(for: MockProduct.self) { product in
            ProductPageDestination(product: product)
        }
    }
}
