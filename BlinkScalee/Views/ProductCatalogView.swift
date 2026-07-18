//
//  ProductCatalogView.swift
//  BlinkScalee
//
//  Category tab: products grouped under a heading per category (Furniture,
//  Plants, Appliances, ...), each rendered with the shared ProductCard.
//  Grouping is derived from MockProduct.category at render time, so dropping
//  more products (or a brand-new category) into MockProduct.all is all it
//  takes to show up here — no changes needed in this file.
//

import SwiftUI

struct ProductCatalogView: View {
    let onSelectProduct: (MockProduct) -> Void

    /// Categories in first-seen order from the catalog, each paired with its products.
    private var categorySections: [(category: String, products: [MockProduct])] {
        var order: [String] = []
        var grouped: [String: [MockProduct]] = [:]
        for product in MockProduct.all {
            if grouped[product.category] == nil {
                order.append(product.category)
            }
            grouped[product.category, default: []].append(product)
        }
        return order.map { ($0, grouped[$0] ?? []) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                ForEach(categorySections, id: \.category) { section in
                    CategoryProductsSection(
                        title: section.category,
                        products: section.products,
                        onSelectProduct: onSelectProduct
                    )
                }
            }
            .padding(.vertical, 16)
        }
        .background(AppPalette.background)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ProductCatalogView(onSelectProduct: { _ in })
}
