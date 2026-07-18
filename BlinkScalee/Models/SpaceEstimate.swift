//
//  SpaceEstimate.swift
//  BlinkScalee
//
//  The AI contract for the "Find a table for my space" flow — the reverse
//  of ProductDimensions. Instead of sizing a known product, this estimates
//  the SIZE OF THE GAP visible in a room photo, with no stated measurement
//  to anchor on. That's inherently fuzzier than measuring a product against
//  its own silhouette, so `reasoning` is not optional here — the UI always
//  shows what visual cues the model used, so the user can sanity-check an
//  estimate that's necessarily a guess.
//

import Foundation
import FoundationModels

@Generable
struct SpaceEstimate: Codable, Equatable {
    @Guide(description: "Estimated available width of the empty space in centimeters, based on visual reference cues in the photo (doorways, floor tiles, furniture, wall outlets, or people)", .range(10...400))
    var availableWidthCM: Double

    @Guide(description: "Estimated available depth (front-to-back) of the empty space in centimeters, using the same visual reasoning")
    var availableDepthCM: Double

    @Guide(description: "How confident you are in this estimate given the strength of visual reference cues present")
    var confidence: DimensionConfidence

    @Guide(description: "One or two sentences on what visual cues you used to estimate scale, e.g. 'Using the doorway width and floor tile spacing as reference.' Be honest if there were few reliable cues.")
    var reasoning: String

    var spaceLabel: String {
        let fmt: (Double) -> String = { $0.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", $0) : String(format: "%.1f", $0) }
        return "≈ \(fmt(availableWidthCM)) × \(fmt(availableDepthCM)) cm available"
    }
}
