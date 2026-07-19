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

enum ShapeBuilderError: LocalizedError {
    case modelNotFound(String)

    var errorDescription: String? {
        switch self {
        case .modelNotFound(let name):
            return "Couldn't find \(name).usdz in the app bundle."
        }
    }
}

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

    /// Loads a bundled `.usdz` and corrects its scale against known
    /// real-world dimensions. glTF→USDZ pipelines routinely disagree on
    /// units — USD's convention is 1 unit = 1 meter, but plenty of DCC
    /// tools/exporters default to centimeters, which comes out 100x too
    /// big once interpreted as meters. Rather than trust whatever scale the
    /// file happens to have baked in, this measures the loaded mesh's
    /// actual bounding box and rescales it to match the product's real
    /// dimensions exactly — correct regardless of how the source file was
    /// authored or converted.
    static func loadModelEntity(
        usdzNamed name: String,
        targetDimensionsCM dims: (width: Double, height: Double, depth: Double),
        rotationDegrees: (pitchX: Double, yawY: Double, rollZ: Double) = (0, 0, 0),
        usesGroundingShadows: Bool = true
    ) async throws -> Entity {
        guard let url = Bundle.main.url(forResource: name, withExtension: "usdz") else {
            throw ShapeBuilderError.modelNotFound(name)
        }
        let entity = try await Entity(contentsOf: url)

        let bounds = entity.visualBounds(relativeTo: nil)
        let targetWidthM = Float(dims.width) / 100
        let targetHeightM = Float(dims.height) / 100

        // Correct off whichever measured axis is largest/most reliable —
        // a thin, flat mesh can have a near-zero extent on one axis.
        if bounds.extents.x > 0.001 {
            applyScaleCorrection(to: entity, factor: targetWidthM / bounds.extents.x)
        } else if bounds.extents.y > 0.001 {
            applyScaleCorrection(to: entity, factor: targetHeightM / bounds.extents.y)
        }

        // Manual orientation fix — see `BlinkitProductPageContent.arModelRotationDegrees`
        // for why this is ever needed (export pipelines disagreeing on "up").
        if rotationDegrees != (0, 0, 0) {
            let pitch = simd_quatf(angle: Float(rotationDegrees.pitchX) * .pi / 180, axis: [1, 0, 0])
            let yaw = simd_quatf(angle: Float(rotationDegrees.yawY) * .pi / 180, axis: [0, 1, 0])
            let roll = simd_quatf(angle: Float(rotationDegrees.rollZ) * .pi / 180, axis: [0, 0, 1])
            entity.transform.rotation = yaw * pitch * roll
        }

        if usesGroundingShadows {
            applyGroundingShadowRecursively(to: entity)
        }
        entity.generateCollisionShapes(recursive: true)
        entity.components.set(InputTargetComponent())

        return entity
    }

    private static func applyScaleCorrection(to entity: Entity, factor: Float) {
        // Sanity bounds so a degenerate/near-zero measured bbox (e.g. a
        // malformed mesh) can't produce a nonsensical or infinite scale.
        guard factor.isFinite, factor > 0.001, factor < 1000 else { return }
        entity.scale = SIMD3<Float>(repeating: factor)
    }

    /// GroundingShadowComponent has to land on the entity that actually
    /// carries a ModelComponent (the mesh) — for a loaded .usdz that's
    /// usually a child several levels into the hierarchy, not the root
    /// wrapper Entity that `Entity(contentsOf:)` hands back.
    private static func applyGroundingShadowRecursively(to entity: Entity) {
        if entity.components[ModelComponent.self] != nil {
            entity.components.set(GroundingShadowComponent(castsShadow: true))
        }
        for child in entity.children {
            applyGroundingShadowRecursively(to: child)
        }
    }
}
