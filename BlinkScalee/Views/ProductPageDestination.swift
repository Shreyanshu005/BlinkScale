//
//  ProductPageDestination.swift
//  BlinkScalee
//
//  Push destination for `.navigationDestination(for: MockProduct.self)` —
//  registered once per tab's own NavigationStack so selecting a product gets
//  a real system push/pop transition and interactive swipe-back, instead of
//  the app's custom cross-fade state machine in ContentView (which is still
//  used by the Space Fit flow, since that flow isn't wrapped in a
//  NavigationStack at all).
//

import SwiftUI

struct ProductPageDestination: View {
    let product: MockProduct

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        if let polished = product.polishedPageContent {
            BlinkitProductPageView(
                content: polished,
                onBack: { dismiss() },
                onAddToCart: {}, // no cart model yet — decorative for the demo, matches ContentView's usage
                showsCustomBackGesture: false
            )
        } else {
            // No real assets yet — every current catalog entry has
            // `polishedPageContent`, so this path isn't reachable today.
            // The live-AI flow (AnalysisView → ARPreviewView) only exists
            // wired through ContentView's state machine right now; a future
            // product added without real assets would need that chain
            // rebuilt as further NavigationStack pushes here.
            ProductDetailView(product: product, onBack: { dismiss() }, onSeeInRoom: {})
        }
    }
}
