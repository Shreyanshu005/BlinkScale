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

    // MARK: Dimensions
    /// Real, known dimensions in centimeters — since this content path is
    /// for products with genuine supplied assets (photo + usdz), these are
    /// ground truth, not an AI estimate. `nil` hides the dimensions row.
    var dimensionsCM: (width: Double, height: Double, depth: Double)? = nil

    /// "60 × 75 × 40 cm" formatted for display, matching the style used by
    /// `ProductDimensions.dimensionLabel` elsewhere in the app.
    var dimensionsLabel: String? {
        guard let dimensionsCM else { return nil }
        let fmt: (Double) -> String = {
            $0.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", $0) : String(format: "%.1f", $0)
        }
        return "\(fmt(dimensionsCM.width)) × \(fmt(dimensionsCM.height)) × \(fmt(dimensionsCM.depth)) cm"
    }

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

    // MARK: AR
    /// Filename (no extension) of a `.usdz` bundled in the app's resources.
    /// When set, BlinkitProductPageView shows a "View in your room" button
    /// under the image carousel that launches the system AR Quick Look
    /// viewer. `nil` hides the button entirely — a product with no 3D model
    /// yet just doesn't get one. Defaults to `nil` so existing content
    /// doesn't need updating.
    var arModelResourceName: String? = nil

    /// Which real-world surface this item goes against in AR — same value
    /// as the originating `MockProduct.requiredSurface`, kept in sync
    /// manually like `dimensionsCM` above. Threaded through to
    /// `PolishedARPreviewView` so the AR flow can warn (rather than
    /// mis-place) if the user points at the wrong kind of surface.
    var requiredSurface: PlacementSurface = .floor

    /// Manual per-model orientation fix, in degrees around each local axis
    /// (X = pitch, Y = yaw, Z = roll), applied once after the usdz loads.
    /// Needed because usdz export pipelines don't agree on "up" — RealityKit/
    /// USD convention is Y-up, but a model converted through a tool that
    /// defaults to Z-up (common with Blender-originated meshes, for example)
    /// comes in tipped over even though its scale is correct. `(0, 0, 0)`
    /// (the default) applies no correction. Only set this once you've seen a
    /// specific model rotated wrong in AR and know which way to counter it —
    /// e.g. `(pitchX: -90, yawY: 0, rollZ: 0)` is the standard fix for a
    /// Z-up mesh lying on its back.
    var arModelRotationDegrees: (pitchX: Double, yawY: Double, rollZ: Double) = (0, 0, 0)
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
