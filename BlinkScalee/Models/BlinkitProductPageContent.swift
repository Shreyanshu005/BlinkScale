//
//  BlinkitProductPageContent.swift
//  BlinkScalee
//
//  Pure content model for BlinkitProductPageView — deliberately decoupled
//  from MockProduct so this page can be generated for ANY product just by
//  filling in this struct, without touching the view code. Every field the
//  reference screenshot showed (variant pills, delivery time, rating, bank
//  offer, brand row, cart state) is represented here so new instances are
//  just data, not new SwiftUI.
//

import Foundation

struct BlinkitProductPageContent: Identifiable {
    let id = UUID()

    // MARK: Image carousel
    /// Real product photos, by Assets.xcassets image set name — one slide
    /// per name, in order. Takes priority over `imageSystemNames` whenever
    /// non-empty, so supplying real photos requires no other code changes.
    var imageAssetNames: [String] = []
    /// Placeholder SF Symbol per carousel slide, used only when
    /// `imageAssetNames` is empty (i.e. no real photos supplied yet).
    let imageSystemNames: [String]
    let imageTintHex: String

    // MARK: Variant selectors (e.g. "Colour: Crimson Red", "Type: Laptop Table")
    struct VariantOption: Identifiable {
        let id = UUID()
        let label: String
        let value: String
    }
    let variantOptions: [VariantOption]
    let viewDetailsLabel: String

    // MARK: Delivery + rating
    let deliveryTimeLabel: String
    let rating: Double
    let reviewCount: Int

    // MARK: Title + stock
    let title: String
    let quantityLabel: String
    let stockLeftLabel: String?

    // MARK: Price
    let priceRupees: Int
    let mrpRupees: Int?

    // MARK: Bank offer
    struct BankOffer {
        let bankInitial: String
        let bankTintHex: String
        let offerPriceRupees: Int
        let couponCode: String
    }
    let bankOffer: BankOffer?

    // MARK: Brand
    struct BrandInfo {
        let name: String
        let subtitle: String
        let iconSystemName: String
    }
    let brand: BrandInfo?

    // MARK: Cart state
    let cartItemCount: Int

    // MARK: AR
    /// Filename (no extension) of a `.usdz` bundled in the app's resources.
    /// When set, BlinkitProductPageView shows a "View in your room" button
    /// under the image carousel that launches the system AR Quick Look
    /// viewer. `nil` hides the button entirely — a product with no 3D model
    /// yet just doesn't get one. Defaults to `nil` so existing content
    /// doesn't need updating.
    var arModelResourceName: String? = nil
}

// Identity equality (matches the pattern used by MockProduct and
// CapturedSpacePhoto elsewhere in this app) — needed so AppState, which
// carries this type as an associated value, can stay Equatable without
// requiring every nested struct (VariantOption, BankOffer, BrandInfo) to
// individually conform.
extension BlinkitProductPageContent: Equatable {
    static func == (lhs: BlinkitProductPageContent, rhs: BlinkitProductPageContent) -> Bool {
        lhs.id == rhs.id
    }
}
