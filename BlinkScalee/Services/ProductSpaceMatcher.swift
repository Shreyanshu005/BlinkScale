//
//  ProductSpaceMatcher.swift
//  BlinkScalee
//
//  Deterministic Swift matching, kept OUT of the AI prompt on purpose.
//  `ProductIntentResolver` already narrowed the catalog down to whatever the
//  user's free-text prompt is asking about (a table, a plant, an air fryer,
//  anything); this pure function's only job is deciding which of THOSE
//  candidates actually fit the estimated space, and ranking them. Splitting
//  "what do they want" from "what fits" keeps each step simple and keeps the
//  final result always grounded in real catalog data — never a hallucinated
//  product or a size mismatch.
//

import Foundation

enum ProductSpaceMatcher {

    /// Safety margin so a fit isn't knife's-edge — leaves ~10% breathing
    /// room around the product for walking space, opening a door, etc.
    private static let fitMarginRatio = 0.9

    /// Every candidate whose real footprint fits within `estimate`'s
    /// available space (after the safety margin), ranked largest-footprint
    /// first so the most generous fit surfaces at the top of the results.
    static func fittingMatches(for estimate: SpaceEstimate, candidates: [MockProduct]) -> [MockProduct] {
        let usableWidth = estimate.availableWidthCM * fitMarginRatio
        let usableDepth = estimate.availableDepthCM * fitMarginRatio

        let fitting = candidates.filter { product in
            product.referenceDimensionsCM.width <= usableWidth &&
            product.referenceDimensionsCM.depth <= usableDepth
        }

        return fitting.sorted { lhs, rhs in
            let lhsArea = lhs.referenceDimensionsCM.width * lhs.referenceDimensionsCM.depth
            let rhsArea = rhs.referenceDimensionsCM.width * rhs.referenceDimensionsCM.depth
            return lhsArea > rhsArea
        }
    }

    /// Convenience for callers that only want a single top pick (e.g. a
    /// demo-safety fallback) rather than the full ranked list.
    static func bestFit(for estimate: SpaceEstimate, candidates: [MockProduct] = MockProduct.all) -> MockProduct? {
        fittingMatches(for: estimate, candidates: candidates).first
    }
}
