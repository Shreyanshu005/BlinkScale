//
//  TableMatcher.swift
//  BlinkScalee
//
//  Deterministic Swift matching, kept OUT of the AI prompt on purpose.
//  Asking the model to pick a product by name from a list risks it
//  hallucinating a name that doesn't exist in the catalog or mismatching
//  case/spelling. Instead the model's only job is estimating the space
//  (SpaceEstimate); this pure function does the actual selection so the
//  result is always a real, valid catalog entry.
//

import Foundation

enum TableMatcher {

    /// Safety margin so a recommended table isn't a knife's-edge fit —
    /// leaves ~10% breathing room around the table for walking space,
    /// pulling out a chair, etc.
    private static let fitMarginRatio = 0.9

    /// Picks the largest table from `candidates` that still fits within
    /// `estimate`'s available space (after the safety margin). Preferring
    /// the largest fit — rather than just any fit — maximizes usable
    /// furniture size for the user rather than defaulting to the smallest
    /// option every time.
    static func bestFit(for estimate: SpaceEstimate, candidates: [MockProduct] = MockProduct.tableCatalog) -> MockProduct? {
        let usableWidth = estimate.availableWidthCM * fitMarginRatio
        let usableDepth = estimate.availableDepthCM * fitMarginRatio

        let fitting = candidates.filter { product in
            product.referenceDimensionsCM.width <= usableWidth &&
            product.referenceDimensionsCM.depth <= usableDepth
        }

        // Largest by footprint area, so we recommend the most generous
        // table that still comfortably fits rather than the smallest.
        return fitting.max { lhs, rhs in
            let lhsArea = lhs.referenceDimensionsCM.width * lhs.referenceDimensionsCM.depth
            let rhsArea = rhs.referenceDimensionsCM.width * rhs.referenceDimensionsCM.depth
            return lhsArea < rhsArea
        }
    }
}
