//
//  ProductSpaceMatcher.swift
//  BlinkScalee
//
//  Deterministic final validation for recommendations. The language model can
//  reason about style, but this is the authority on whether an item fits the
//  ARKit-measured surface.
//

import Foundation

enum ProductSpaceMatcher {
    private static let fitMarginRatio = 0.9

    static func fittingMatches(
        availableWidthCM: Double,
        availableDepthCM: Double,
        candidates: [MockProduct]
    ) -> [MockProduct] {
        let usableWidth = availableWidthCM * fitMarginRatio
        let usableDepth = availableDepthCM * fitMarginRatio

        return candidates.filter { product in
            switch product.requiredSurface {
            case .floor:
                return product.referenceDimensionsCM.width <= usableWidth
                    && product.referenceDimensionsCM.depth <= usableDepth
            case .wall:
                return product.referenceDimensionsCM.width <= usableWidth
                    && product.referenceDimensionsCM.height <= usableDepth
            case .ceiling:
                return false
            }
        }
    }
}
