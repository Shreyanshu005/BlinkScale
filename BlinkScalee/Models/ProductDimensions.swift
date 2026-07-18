//
//  ProductDimensions.swift
//  BlinkScalee
//
//  The AI contract. Every downstream layer (AR geometry, UI cards, retry
//  flow) derives from this single struct, so its shape needs to be both
//  strict (for RealityKit) and self-describing (for the LLM prompt via
//  @Guide descriptions).
//

import Foundation
import FoundationModels

/// Confidence the model has in its own estimate. Surfaced directly in the UI
/// as a green/yellow/red badge — an enum (not a raw Double score) keeps the
/// language model's output calibrated to something a shopper can read at a
/// glance.
@Generable
enum DimensionConfidence: String, CaseIterable, Codable, Equatable {
    case high
    case medium
    case low
}

/// Structured output from `DimensionAnalyzer`. `@Generable` guarantees the
/// language model returns exactly this shape — no JSON parsing, no partial
/// responses, no "the model said something slightly different" bugs.
@Generable
struct ProductDimensions: Codable, Equatable {
    @Guide(description: "The closest matching primitive shape for this product's silhouette")
    var shape: ProductShape

    @Guide(description: "Width in centimeters, i.e. the left-to-right extent as photographed", .range(1...500))
    var widthCM: Double

    @Guide(description: "Height in centimeters, i.e. the vertical extent", .range(1...500))
    var heightCM: Double

    @Guide(description: "Depth in centimeters, i.e. the front-to-back extent", .range(1...500))
    var depthCM: Double

    @Guide(description: "How confident you are in this estimate given the image quality and product familiarity")
    var confidence: DimensionConfidence

    /// Meters, for direct use in RealityKit (`MeshResource.generate*` all
    /// expect meters). Centimeters are what the model reasons in and what the
    /// UI displays; meters are purely an AR-layer implementation detail.
    var widthM: Float { Float(widthCM) / 100 }
    var heightM: Float { Float(heightCM) / 100 }
    var depthM: Float { Float(depthCM) / 100 }

    /// "120 × 85 × 30 cm" style label for the AR overlay card.
    var dimensionLabel: String {
        let fmt: (Double) -> String = { $0.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", $0) : String(format: "%.1f", $0) }
        return "\(fmt(widthCM)) × \(fmt(heightCM)) × \(fmt(depthCM)) cm"
    }
}
