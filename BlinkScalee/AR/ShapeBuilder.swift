//
//  ShapeBuilder.swift
//  BlinkScalee
//
//  Pure geometry/material factory. Takes a ProductDimensions and produces
//  RealityKit entities — no ARSession, no gesture handling, no state. Kept
//  separate from ARCoordinator so the shape-building logic can be unit
//  tested with a static ProductDimensions value, no simulator required.
//

import RealityKit
import UIKit

enum ShapeBuilder {

    /// The main product entity: parametric mesh sized to real-world
    /// dimensions, semi-transparent Blinkit-orange material so the shape
    /// reads as "preview" rather than a photoreal object, plus a grounding
    /// shadow so it feels anchored to the real floor instead of floating.
    static func buildProductEntity(from dims: ProductDimensions) throws -> ModelEntity {
        let mesh = try dims.shape.makeMesh(
            widthM: dims.widthM,
            heightM: max(dims.heightM, 0.005), // avoid degenerate flat meshes (e.g. yoga mat)
            depthM: dims.depthM
        )

        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: UIColor(named: "BlinkitOrange") ?? UIColor(red: 0.94, green: 0.71, blue: 0.16, alpha: 0.65))
        material.roughness = .init(floatLiteral: 0.4)
        material.metallic = .init(floatLiteral: 0.1)
        material.blending = .transparent(opacity: .init(floatLiteral: 0.72))

        let entity = ModelEntity(mesh: mesh, materials: [material])

        // RealityKit casts shadows onto detected planes automatically when
        // the entity has collision + a receiving surface, but we also opt
        // into GroundingShadowComponent explicitly for reliability across
        // varying scene lighting (the "Grounding shadow" spec item).
        entity.components.set(GroundingShadowComponent(castsShadow: true))
        entity.generateCollisionShapes(recursive: false)
        entity.components.set(InputTargetComponent())

        // Center the mesh on its own anchor origin so scale/rotation pivot
        // around the object's middle rather than a corner.
        entity.position.y = dims.heightM / 2

        return entity
    }

    /// Thin pulsing ring shown while scanning, and solid once a valid floor
    /// hit is available to place at. Built from a flattened cylinder rather
    /// than a custom mesh since RealityKit's generatePlane doesn't support a
    /// ring/annulus directly — a very short cylinder reads visually the same
    /// from the top-down angle the camera sees it at.
    static func buildPlacementIndicator(radius: Float = 0.25) -> ModelEntity {
        let mesh = MeshResource.generateCylinder(height: 0.002, radius: radius)
        var material = UnlitMaterial(color: UIColor(red: 0.94, green: 0.71, blue: 0.16, alpha: 0.85))
        material.blending = .transparent(opacity: .init(floatLiteral: 0.85))
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.name = "placementIndicator"
        return entity
    }

    /// Attaches a looping scale-pulse animation to the placement indicator
    /// while the user is scanning but hasn't tapped to place yet.
    static func applyScanPulse(to entity: ModelEntity) {
        var transform = entity.transform
        transform.scale = SIMD3<Float>(repeating: 1.15)
        entity.move(
            to: transform,
            relativeTo: entity.parent,
            duration: 0.9,
            timingFunction: .easeInOut
        )
    }
}
