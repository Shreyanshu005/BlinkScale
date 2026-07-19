//
//  MockProduct.swift
//  BlinkScalee
//
//  Catalog model for the demo. Every entry in `all` below has real supplied
//  assets (a photo + a converted .usdz) and routes straight to the polished
//  BlinkitProductPageView + AR Quick Look via `polishedPageContent`. The
//  `imageSystemName`/`renderedCGImage` machinery below still exists to
//  support the live-AI flow (ProductDetailView → AnalysisView → ARPreviewView)
//  for any future product added WITHOUT real assets yet — Foundation Models
//  reasons fine over an SF Symbol rendered to a CGImage in that path.
//

import SwiftUI
import UIKit
import CoreGraphics

struct MockProduct: Identifiable, Equatable, Hashable {
    let id = UUID()
    let name: String
    let category: String
    let priceRupees: Int
    let weightOrSizeLabel: String
    let imageSystemName: String
    let tintHex: String

    /// Ground-truth dimensions used only to sanity-check the AI estimate
    /// during rehearsal — never shown to the user, never fed to the model.
    /// Also doubles as a demo-safety fallback (see `fallbackDimensions`) if
    /// the on-device model is briefly unavailable during a live demo.
    let referenceDimensionsCM: (width: Double, height: Double, depth: Double)
    let referenceShape: ProductShape

    /// Which real-world surface this item is placed against in AR. Defaults
    /// to `.floor` since that's every current catalog entry — a future wall
    /// item (curtains, wall art) or ceiling item (a pendant light) would set
    /// this explicitly, and the AR flow warns rather than mis-places if the
    /// user points at the wrong kind of surface for it.
    var requiredSurface: PlacementSurface = .floor

    // MARK: Card display (ProductCard) — mirrors the matching
    // BlinkitProductPageContent sample 1:1 by design; the two models stay
    // deliberately decoupled (see `polishedPageContent` below), so these are
    // kept in sync manually rather than derived from one another.
    var mrpRupees: Int? = nil
    var rating: Double = 4.5
    var reviewCount: Int = 0
    var deliveryTimeLabel: String = "—"
    /// Real product photo (Assets.xcassets image set name) shown on
    /// `ProductCard`. `nil` falls back to the tinted `imageSystemName` icon.
    var cardImageAssetName: String? = nil
    /// Shows the "Ad" tag on the card. `false` for everything in this
    /// catalog — every product here is a real, non-sponsored listing.
    var isSponsored: Bool = false

    /// When set, this product has real, pre-supplied assets (photo +
    /// converted .usdz) and should route straight to the polished
    /// BlinkitProductPageView + native AR Quick Look instead of the live
    /// AI-analysis flow. `nil` (the default) means "no demo assets yet" —
    /// the product falls through to ProductDetailView/AnalysisView/
    /// ARPreviewView, i.e. the real on-device-AI implementation.
    var polishedPageContent: BlinkitProductPageContent? = nil

    // Tuples aren't Equatable/Hashable, so `referenceDimensionsCM` can't be
    // auto-synthesized into either conformance. Every mock product has a
    // unique UUID, so identity equality/hashing is exactly what we want here
    // anyway (two products are "equal" iff they're the same catalog entry).
    // Hashable is needed so `NavigationPath`/`.navigationDestination(for:)`
    // can route a tapped product to its detail page.
    static func == (lhs: MockProduct, rhs: MockProduct) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension MockProduct {
    /// Renders the SF Symbol placeholder to a CGImage so it can be fed to
    /// `DimensionAnalyzer` exactly like a real product photo would be. This
    /// is the hackathon shortcut mentioned in the plan — swapping in real
    /// product photography later requires no changes to the AI or AR layers.
    var renderedCGImage: CGImage? {
        let config = UIImage.SymbolConfiguration(pointSize: 200, weight: .regular)
        guard let symbolImage = UIImage(systemName: imageSystemName, withConfiguration: config) else { return nil }
        let tint = UIColor(hex: tintHex) ?? .systemOrange

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 400))
        let uiImage = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 400, height: 400))
            tint.setFill()
            let tinted = symbolImage.withTintColor(tint, renderingMode: .alwaysOriginal)
            let imageRect = CGRect(x: 100, y: 100, width: 200, height: 200)
            tinted.draw(in: imageRect)
        }
        return uiImage.cgImage
    }

    /// Demo-safety net: if `DimensionAnalyzer` fails (model unavailable,
    /// still downloading, guardrail rejection, etc.) this lets the flow
    /// continue with known-good reference dimensions instead of stalling
    /// out on stage. Confidence is marked `.low` since it's a hardcoded
    /// stand-in, not a genuine per-photo AI estimate.
    var fallbackDimensions: ProductDimensions {
        ProductDimensions(
            shape: referenceShape,
            widthCM: referenceDimensionsCM.width,
            heightCM: referenceDimensionsCM.height,
            depthCM: referenceDimensionsCM.depth,
            confidence: .low
        )
    }
}

extension Int {
    /// "₹1,605" comma-grouped formatting shared by every price label in the
    /// app (ProductCard, BlinkitProductPageView) — plain string
    /// interpolation on an Int silently drops the thousands separator.
    var asRupeeLabel: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.groupingSize = 3
        return "₹" + (formatter.string(from: NSNumber(value: self)) ?? "\(self)")
    }
}

extension UIColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}

extension MockProduct {
    static let all: [MockProduct] = [
        MockProduct(
            name: "Portronics My Buddy D Adjustable Laptop Table (Crimson Red)",
            category: "Furniture",
            priceRupees: 1_605,
            weightOrSizeLabel: "1 pc",
            imageSystemName: "studentdesk",
            tintHex: "B33A2E",
            referenceDimensionsCM: (width: 60, height: 75, depth: 40),
            referenceShape: .box,
            mrpRupees: 2_999,
            rating: 4.5,
            reviewCount: 599,
            deliveryTimeLabel: "29 mins",
            cardImageAssetName: "portronics_laptop_table",
            // Demo-ready: real photo + real .usdz once supplied, routes to
            // BlinkitProductPageView instead of the live-AI flow.
            polishedPageContent: .portronicsLaptopTable
        ),
        MockProduct(
            name: "Rooted Jade Plant with Self-Watering Pot",
            category: "Plants",
            priceRupees: 349,
            weightOrSizeLabel: "1 pc",
            imageSystemName: "leaf.fill",
            tintHex: "3E7C4F",
            referenceDimensionsCM: (width: 9.9, height: 24.9, depth: 9.9),
            referenceShape: .cylinder,
            rating: 4.5,
            reviewCount: 128,
            deliveryTimeLabel: "29 mins",
            cardImageAssetName: "plant_pot",
            polishedPageContent: .rootedJadePlant
        ),
        MockProduct(
            name: "Ugaoo Lady Valentine Aglaonema Plant",
            category: "Plants",
            priceRupees: 369,
            weightOrSizeLabel: "1 pc",
            imageSystemName: "leaf.fill",
            tintHex: "C46B8C",
            referenceDimensionsCM: (width: 10, height: 20, depth: 10),
            referenceShape: .cylinder,
            mrpRupees: 499,
            rating: 4.5,
            reviewCount: 342,
            deliveryTimeLabel: "12 mins",
            cardImageAssetName: "plant",
            polishedPageContent: .ugaooLadyValentine
        ),
        MockProduct(
            name: "Nurturing Green ZZ Plant with Self-Watering Pot",
            category: "Plants",
            priceRupees: 400,
            weightOrSizeLabel: "1 pc",
            imageSystemName: "leaf.fill",
            tintHex: "2F6B3A",
            referenceDimensionsCM: (width: 11.4, height: 25.4, depth: 11.4),
            referenceShape: .cylinder,
            mrpRupees: 549,
            rating: 4.5,
            reviewCount: 214,
            deliveryTimeLabel: "14 mins",
            cardImageAssetName: "plant2",
            polishedPageContent: .nurturingGreenZZ
        ),
        MockProduct(
            name: "Solara Air Fryer with See Through Window (4.5 ltr, 1500 W)",
            category: "Appliances",
            priceRupees: 3_699,
            weightOrSizeLabel: "1 unit",
            imageSystemName: "oven.fill",
            tintHex: "1A1A1A",
            referenceDimensionsCM: (width: 30, height: 30.5, depth: 24.5),
            referenceShape: .box,
            mrpRupees: 9_999,
            rating: 4.5,
            reviewCount: 208,
            deliveryTimeLabel: "28 mins",
            cardImageAssetName: "airfryer",
            polishedPageContent: .solaraAirFryer
        ),
        MockProduct(
            name: "FunBlast Premium Velvet Dining Chair Cover (Coffee) - Pack of 2",
            category: "Furniture",
            priceRupees: 699,
            weightOrSizeLabel: "2 pcs",
            imageSystemName: "sofa.fill",
            tintHex: "6F4E37",
            referenceDimensionsCM: (width: 48.3, height: 66.0, depth: 45.7),
            referenceShape: .box,
            mrpRupees: 1_499,
            rating: 4.5,
            reviewCount: 176,
            deliveryTimeLabel: "19 mins",
            cardImageAssetName: "chair",
            polishedPageContent: .funBlastChairCover
        ),
        MockProduct(
            name: "Decathlon Quechua Folding Camping Chair (Blue)",
            category: "Furniture",
            priceRupees: 1_799,
            weightOrSizeLabel: "1 pc",
            imageSystemName: "sofa.fill",
            tintHex: "2A6FB5",
            referenceDimensionsCM: (width: 82, height: 17.5, depth: 17.5),
            referenceShape: .box,
            mrpRupees: 1_999,
            rating: 4.5,
            reviewCount: 231,
            deliveryTimeLabel: "22 mins",
            cardImageAssetName: "chair2",
            polishedPageContent: .decathlonQuechuaChair
        ),
        MockProduct(
            name: "Real Wood Wall Clock (Mahogany)",
            category: "Home Decor",
            priceRupees: 1_299,
            weightOrSizeLabel: "1 pc",
            imageSystemName: "clock.fill",
            tintHex: "6F2C1E",
            referenceDimensionsCM: (width: 30, height: 30, depth: 5),
            referenceShape: .cylinder,
            requiredSurface: .wall,
            mrpRupees: 2_599,
            rating: 4.5,
            reviewCount: 143,
            deliveryTimeLabel: "16 mins",
            cardImageAssetName: "clock",
            polishedPageContent: .realWoodWallClock
        ),
        MockProduct(
            name: "Home Sizzler Blackout Door Curtain (Brown, 48x84 inch)",
            category: "Home Decor",
            priceRupees: 499,
            weightOrSizeLabel: "1 pc",
            imageSystemName: "rectangle.fill",
            tintHex: "5C3A21",
            referenceDimensionsCM: (width: 121.9, height: 213.4, depth: 2),
            referenceShape: .box,
            requiredSurface: .wall,
            mrpRupees: 999,
            rating: 4.5,
            reviewCount: 267,
            deliveryTimeLabel: "11 mins",
            cardImageAssetName: "curtain",
            polishedPageContent: .homeSizzlerCurtain
        ),
        MockProduct(
            name: "Ganesha Deepak Brass Wall Hanging with Bell (Golden)",
            category: "Home Decor",
            priceRupees: 824,
            weightOrSizeLabel: "1 pc",
            imageSystemName: "bell.fill",
            tintHex: "D4AF37",
            referenceDimensionsCM: (width: 11.4, height: 22.9, depth: 7.6),
            referenceShape: .box,
            requiredSurface: .wall,
            mrpRupees: 1_999,
            rating: 4.5,
            reviewCount: 198,
            deliveryTimeLabel: "9 mins",
            cardImageAssetName: "hanger",
            polishedPageContent: .ganeshaDeepakHanger
        ),
        MockProduct(
            name: "Mahal Karigari Ceramic Wall Plate (Multicolour)",
            category: "Home Decor",
            priceRupees: 815,
            weightOrSizeLabel: "1 pc",
            imageSystemName: "circle.fill",
            tintHex: "D96C3F",
            referenceDimensionsCM: (width: 20, height: 20, depth: 2),
            referenceShape: .cylinder,
            requiredSurface: .wall,
            mrpRupees: 1_295,
            rating: 4.5,
            reviewCount: 154,
            deliveryTimeLabel: "13 mins",
            cardImageAssetName: "walldecor2",
            polishedPageContent: .mahalKarigariWallPlate
        ),
        MockProduct(
            name: "Owl Pyrite Stone by Astrotalk",
            category: "Home Decor",
            priceRupees: 999,
            weightOrSizeLabel: "1 pc",
            imageSystemName: "diamond.fill",
            tintHex: "6E6E6E",
            referenceDimensionsCM: (width: 7, height: 8, depth: 7),
            referenceShape: .box,
            mrpRupees: 1_700,
            rating: 4.5,
            reviewCount: 112,
            deliveryTimeLabel: "17 mins",
            cardImageAssetName: "walldecor3",
            polishedPageContent: .owlPyriteStone
        )
    ]

    /// Just the table/furniture SKUs, kept as a convenience filter for
    /// anything that specifically wants furniture only.
    static var tableCatalog: [MockProduct] {
        all.filter { $0.category == "Furniture" }
    }
}
