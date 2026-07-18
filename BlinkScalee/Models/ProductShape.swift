//
//  ProductShape.swift
//  BlinkScalee
//
//  Parametric shape vocabulary the AI is allowed to choose from, plus the
//  RealityKit geometry factory for each case. Keeping this as its own type
//  (rather than a raw String on ProductDimensions) means the @Generable
//  layer, the AR layer, and the UI layer all share one source of truth for
//  "what shapes exist."
//

import Foundation
import RealityKit
import FoundationModels

/// `@Generable` lets Foundation Models pick this case directly as structured
/// output — no free-text parsing, no invalid-shape edge cases to guard against.
@Generable
enum ProductShape: String, CaseIterable, Codable, Equatable {
    case box
    case cylinder
    case sphere
    case lShape

    /// Friendly label for UI (e.g. confidence card, debug overlays).
    var displayName: String {
        switch self {
        case .box: return "Box"
        case .cylinder: return "Cylinder"
        case .sphere: return "Sphere"
        case .lShape: return "L-Shape"
        }
    }

    /// SF Symbol used as a lightweight stand-in icon before the real mesh renders.
    var iconSystemName: String {
        switch self {
        case .box: return "shippingbox.fill"
        case .cylinder: return "cylinder.fill"
        case .sphere: return "circle.fill"
        case .lShape: return "square.stack.3d.up.fill"
        }
    }

    /// Builds the RealityKit geometry for this shape at the given real-world
    /// dimensions (in meters). `lShape` degrades gracefully to a box union
    /// approximation since RealityKit has no native L-prism primitive —
    /// good enough for scale judgment, which is the whole point.
    func makeMesh(widthM: Float, heightM: Float, depthM: Float) throws -> MeshResource {
        switch self {
        case .box:
            return try .generateBox(width: widthM, height: heightM, depth: depthM, cornerRadius: 0.01)
        case .cylinder:
            return .generateCylinder(height: heightM, radius: widthM / 2)
        case .sphere:
            return .generateSphere(radius: widthM / 2)
        case .lShape:
            // Approximate an L-shaped footprint as a box for v1 — true composite
            // geometry is a stretch goal, not a hackathon blocker.
            return try .generateBox(width: widthM, height: heightM, depth: depthM, cornerRadius: 0.005)
        }
    }
}
