//
//  MockProduct.swift
//  BlinkScalee
//
//  Fake Blinkit catalog for the demo. Real product photos aren't needed for
//  the "aha moment" to land — Foundation Models reasons just fine over an
//  SF Symbol rendered to a CGImage, and it keeps the app dependency-free
//  (no bundled JPEGs, no network fetch, nothing that can fail on stage).
//

import SwiftUI
import UIKit
import CoreGraphics

struct MockProduct: Identifiable, Equatable {
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

    /// When set, this product has real, pre-supplied assets (photo +
    /// converted .usdz) and should route straight to the polished
    /// BlinkitProductPageView + native AR Quick Look instead of the live
    /// AI-analysis flow. `nil` (the default) means "no demo assets yet" —
    /// the product falls through to ProductDetailView/AnalysisView/
    /// ARPreviewView, i.e. the real on-device-AI implementation.
    var polishedPageContent: BlinkitProductPageContent? = nil

    // Tuples aren't Equatable, so `referenceDimensionsCM` can't be
    // auto-synthesized into the conformance. Every mock product has a
    // unique UUID, so identity equality is exactly what we want here anyway
    // (two products are "equal" iff they're the same catalog entry).
    static func == (lhs: MockProduct, rhs: MockProduct) -> Bool {
        lhs.id == rhs.id
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
            name: "43\" Smart LED TV",
            category: "Electronics",
            priceRupees: 24_999,
            weightOrSizeLabel: "1 unit",
            imageSystemName: "tv.fill",
            tintHex: "1A1A2E",
            referenceDimensionsCM: (width: 97, height: 58, depth: 8),
            referenceShape: .box
        ),
        MockProduct(
            name: "Steel Water Bottle 1L",
            category: "Home & Kitchen",
            priceRupees: 499,
            weightOrSizeLabel: "1 L",
            imageSystemName: "drop.fill",
            tintHex: "2E86AB",
            referenceDimensionsCM: (width: 8, height: 27, depth: 8),
            referenceShape: .cylinder
        ),
        MockProduct(
            name: "Yoga Mat Premium",
            category: "Fitness",
            priceRupees: 899,
            weightOrSizeLabel: "6mm thick",
            imageSystemName: "figure.yoga",
            tintHex: "6A4C93",
            referenceDimensionsCM: (width: 61, height: 0.6, depth: 173),
            referenceShape: .box
        ),
        MockProduct(
            name: "20L Microwave Oven",
            category: "Appliances",
            priceRupees: 8_499,
            weightOrSizeLabel: "1 unit",
            imageSystemName: "microwave.fill",
            tintHex: "F0B429",
            referenceDimensionsCM: (width: 46, height: 28, depth: 36),
            referenceShape: .box
        ),
        MockProduct(
            name: "Compact Side Table",
            category: "Furniture",
            priceRupees: 1_499,
            weightOrSizeLabel: "1 unit",
            imageSystemName: "studentdesk",
            tintHex: "8D6E63",
            referenceDimensionsCM: (width: 45, height: 50, depth: 45),
            referenceShape: .box
        ),
        MockProduct(
            name: "Study Table Medium",
            category: "Furniture",
            priceRupees: 3_999,
            weightOrSizeLabel: "1 unit",
            imageSystemName: "studentdesk",
            tintHex: "6D4C41",
            referenceDimensionsCM: (width: 90, height: 75, depth: 60),
            referenceShape: .box
        ),
        MockProduct(
            name: "Dining Table Large",
            category: "Furniture",
            priceRupees: 12_999,
            weightOrSizeLabel: "1 unit",
            imageSystemName: "studentdesk",
            tintHex: "4E342E",
            referenceDimensionsCM: (width: 150, height: 75, depth: 90),
            referenceShape: .box
        ),
        MockProduct(
            name: "Portronics My Buddy D Adjustable Laptop Table (Crimson Red)",
            category: "Furniture",
            priceRupees: 1_605,
            weightOrSizeLabel: "1 pc",
            imageSystemName: "studentdesk",
            tintHex: "B33A2E",
            referenceDimensionsCM: (width: 60, height: 75, depth: 40),
            referenceShape: .box,
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
            polishedPageContent: .solaraAirFryer
        )
    ]

    /// Just the table SKUs — the candidate pool `TableMatcher` picks from.
    static var tableCatalog: [MockProduct] {
        all.filter { $0.category == "Furniture" }
    }
}
