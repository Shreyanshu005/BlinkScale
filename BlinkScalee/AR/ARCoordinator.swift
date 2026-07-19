//
//  ARCoordinator.swift
//  BlinkScalee
//
//  Owns the ARSession lifecycle: floor detection, raycast placement, and
//  post-placement gestures (one-finger rotation and long-press re-place).
//  Published state drives the SwiftUI overlay in ARPreviewView/
//  PolishedARPreviewView — the view itself never touches ARKit/RealityKit
//  types directly.
//

import ARKit
import RealityKit
import SwiftUI
import Combine

/// Where the placed entity comes from. `.parametric` is the live-AI path
/// (a RealityKit primitive sized to an AI-estimated ProductDimensions);
/// `.usdzModel` is the pre-baked demo path (a real bundled model, scale-
/// corrected against known real dimensions). One coordinator handles both
/// so gesture handling, floor scanning, and placement logic aren't
/// duplicated between the two.
enum ARContentSource {
    case parametric(ProductDimensions, requiredSurface: PlacementSurface = .floor)
    case usdzModel(
        resourceName: String,
        dimensionsCM: (width: Double, height: Double, depth: Double),
        requiredSurface: PlacementSurface = .floor,
        rotationDegrees: (pitchX: Double, yawY: Double, rollZ: Double) = (0, 0, 0)
    )

    /// Which real-world surface this item needs. Drives both which planes
    /// `ARCoordinator` scans for and the mismatch warning if the user points
    /// at the wrong kind of surface (e.g. tapping the floor for a curtain).
    var requiredSurface: PlacementSurface {
        switch self {
        case .parametric(_, let requiredSurface): return requiredSurface
        case .usdzModel(_, _, let requiredSurface, _): return requiredSurface
        }
    }
}

@MainActor
final class ARCoordinator: NSObject, ObservableObject, ARSessionDelegate {

    // MARK: Published state consumed by the SwiftUI overlay

    @Published var isFloorDetected: Bool = false
    @Published var isPlaced: Bool = false
    @Published var scanningStatusText: String = "Scanning for floor…"

    private weak var arView: ARView?
    private var contentSource: ARContentSource?
    private var productEntity: Entity?
    private var placementIndicator: ModelEntity?
    private var floorAnchor: AnchorEntity?

    private let hapticImpact = UIImpactFeedbackGenerator(style: .medium)
    private var pulseTimer: Timer?
    private var pulseGrown = false

    // Gesture-tracked state
    private var currentScale: Float = 1.0
    private let minScale: Float = 0.8
    private let maxScale: Float = 1.2

    // Frame throttling: `session(_:didUpdate:)` fires on every camera frame
    // (~60/sec). Doing a raycast on every single one is unnecessary work
    // competing with ARKit's own world-tracking for the main thread/GPU —
    // this was the root cause of the "delegate is retaining N ARFrames" /
    // "world tracking performance affected by resource constraints"
    // warnings. Only reticle-tracking during the pre-placement scan needs
    // this at all, and ~12 updates/sec is visually indistinguishable from
    // 60 for a slow-moving reticle.
    private var frameCounter = 0
    private let raycastEveryNFrames = 5

    // MARK: Setup

    func setupARView(_ arView: ARView, source: ARContentSource) {
        self.arView = arView
        self.contentSource = source
        arView.session.delegate = self

        let config = ARWorldTrackingConfiguration()
        // Track both floors AND walls — even though most catalog items are
        // floor-only, scanning both means a wall item's own scan phase
        // works too, and (more importantly) it means a floor-only item can
        // still detect "the user tapped a wall" at placement time and warn,
        // rather than that surface simply never having been tracked at all.
        config.planeDetection = [.horizontal, .vertical]
        // .automatic environment texturing builds reflection probes for
        // photorealistic materials — pure overhead here since our product
        // entities use flat semi-transparent PBR materials, not reflective
        // ones. Turning it off cuts real per-frame GPU cost (and silences
        // the "EnvironmentResource with no skybox texture" log spam, which
        // comes from that same reflection-probe pipeline).
        config.environmentTexturing = .none
        arView.session.run(config)

        scanningStatusText = source.requiredSurface == .wall ? "Scanning for a wall…" : "Scanning for floor…"
        ToastCenter.shared.loading("Scanning for a place to put your product…")

        addGestureRecognizers(to: arView)
        showPlacementIndicator()
    }

    /// ARKit only exposes `.horizontal`/`.vertical` plane alignment — wall
    /// items need a vertical plane found before tap-to-place is enabled;
    /// floor and ceiling items (ARKit doesn't distinguish the two at the
    /// plane-detection level) both need a horizontal one.
    private var requiredPlaneAlignment: ARPlaneAnchor.Alignment {
        contentSource?.requiredSurface == .wall ? .vertical : .horizontal
    }

    private func showPlacementIndicator() {
        guard let arView else { return }
        let indicator = ShapeBuilder.buildPlacementIndicator()
        indicator.isEnabled = false // hidden until we have a real floor anchor
        let anchor = AnchorEntity(world: .zero)
        anchor.addChild(indicator)
        arView.scene.addAnchor(anchor)
        placementIndicator = indicator
    }

    /// Continuous scale pulse for the placement reticle while scanning, per
    /// the "animated scale pulse while scanning" spec. Stops automatically
    /// once the object is placed.
    private func startPulseAnimation() {
        pulseTimer?.invalidate()
        pulseTimer = Timer.scheduledTimer(withTimeInterval: 0.9, repeats: true) { [weak self] _ in
            guard let self, let indicator = self.placementIndicator, !self.isPlaced else { return }
            self.pulseGrown.toggle()
            var transform = indicator.transform
            transform.scale = SIMD3<Float>(repeating: self.pulseGrown ? 1.15 : 1.0)
            indicator.move(to: transform, relativeTo: indicator.parent, duration: 0.85, timingFunction: .easeInOut)
        }
    }

    private func stopPulseAnimation() {
        pulseTimer?.invalidate()
        pulseTimer = nil
    }

    /// Tracks the floor under the camera's forward ray so the placement
    /// reticle follows the user's aim, like a standard AR reticle, rather
    /// than sitting fixed at world origin. Throttled — see `frameCounter`.
    ///
    /// Important: this method must return almost immediately and must never
    /// retain `frame` (store it, capture it in a Task/closure, etc.). ARKit
    /// warns/aborts frame delivery if its delegate holds onto ARFrames
    /// longer than the callback's scope, and holding the main thread here
    /// too long has the same visible symptom even without literally storing
    /// the frame — the queue backs up either way.
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard !isPlaced, isFloorDetected, let arView, let indicator = placementIndicator else { return }

        frameCounter += 1
        guard frameCounter % raycastEveryNFrames == 0 else { return }

        let center = CGPoint(x: arView.bounds.midX, y: arView.bounds.midY)
        let queryAlignment: ARRaycastQuery.TargetAlignment = requiredPlaneAlignment == .vertical ? .vertical : .horizontal
        guard let result = arView.raycast(from: center, allowing: .estimatedPlane, alignment: queryAlignment).first else { return }
        indicator.transform.matrix = result.worldTransform
    }

    /// Called after a "Doesn't look right?" refinement returns a new
    /// estimate. Only meaningful for the `.parametric` (live-AI) path — the
    /// usdz path shows a real model, so there's nothing to refine. If the
    /// object is already placed, rebuild the entity in place at the same
    /// anchor so the user doesn't have to re-scan or re-tap.
    func updateDimensions(_ newDimensions: ProductDimensions) {
        contentSource = .parametric(newDimensions, requiredSurface: contentSource?.requiredSurface ?? .floor)
        guard isPlaced, let floorAnchor, let newEntity = try? ShapeBuilder.buildProductEntity(from: newDimensions) else { return }
        productEntity?.removeFromParent()
        newEntity.scale = SIMD3<Float>(repeating: currentScale)
        floorAnchor.addChild(newEntity)
        productEntity = newEntity
    }

    // MARK: ARSessionDelegate — floor/wall detection

    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        handleFloorAnchors(anchors)
    }

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        handleFloorAnchors(anchors)
    }

    /// Gates tap-to-place on finding a plane matching whatever surface THIS
    /// item needs (floor/ceiling → horizontal, wall → vertical) — a wall
    /// item can't be tapped-to-place until a wall is actually tracked.
    private func handleFloorAnchors(_ anchors: [ARAnchor]) {
        guard !isFloorDetected else { return }
        let alignment = requiredPlaneAlignment
        let hasMatch = anchors.contains { anchor in
            guard let plane = anchor as? ARPlaneAnchor else { return false }
            return plane.alignment == alignment
        }
        if hasMatch {
            isFloorDetected = true
            let prompt = alignment == .vertical ? "Tap the wall to place" : "Tap to place"
            scanningStatusText = prompt
            placementIndicator?.isEnabled = true
            startPulseAnimation()
            hapticImpact.impactOccurred()
            ToastCenter.shared.show(prompt, duration: .seconds(1.5))
        }
    }

    // MARK: Tap to place

    private func addGestureRecognizers(to arView: ARView) {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        arView.addGestureRecognizer(tap)

        // A one-finger horizontal drag is easy to discover while holding the
        // phone. Scale remains locked to the product's real dimensions.
        let rotate = UIPanGestureRecognizer(target: self, action: #selector(handlePanRotation(_:)))
        rotate.minimumNumberOfTouches = 1
        rotate.maximumNumberOfTouches = 1
        arView.addGestureRecognizer(rotate)

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        arView.addGestureRecognizer(longPress)
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard !isPlaced, isFloorDetected, let arView else { return }
        let point = gesture.location(in: arView)
        // Loading a usdz is async (disk read + parse); placement overall
        // needs to stay async-capable for that case, so both paths route
        // through the same Task-wrapped call.
        Task { await place(at: point, in: arView) }
    }

    /// Classifies a raycast hit as floor, wall, or ceiling — purely from
    /// geometry, since `.estimatedPlane` hits aren't guaranteed to carry a
    /// tracked `ARPlaneAnchor` with its own `.alignment`. A plane's normal
    /// (its transform's Y-axis) points straight up for a horizontal surface
    /// and sideways for a vertical one, so comparing it against world "up"
    /// distinguishes floor/ceiling from wall. Horizontal hits are further
    /// split into floor vs. ceiling by comparing height against the camera —
    /// a best-effort heuristic, since ARKit has no native "ceiling" concept.
    private func surfaceKind(for worldTransform: simd_float4x4, in arView: ARView) -> PlacementSurface {
        let yAxis = SIMD3<Float>(worldTransform.columns.1.x, worldTransform.columns.1.y, worldTransform.columns.1.z)
        let verticalness = abs(simd_normalize(yAxis).y)

        guard verticalness > 0.5 else { return .wall }

        let hitHeight = worldTransform.columns.3.y
        if let cameraHeight = arView.session.currentFrame?.camera.transform.columns.3.y,
           hitHeight > cameraHeight + 0.3 {
            return .ceiling
        }
        return .floor
    }

    /// Rebuilds a wall raycast hit's transform so the placed entity stands
    /// upright against the wall instead of inheriting the hit's own
    /// orientation (whose Y-axis is the wall's horizontal outward normal,
    /// not gravity-up). Keeps the hit's position; reconstructs the
    /// rotation so local Y = world up and local Z = the wall's outward
    /// normal (where the hit's Y used to point), with local X completing a
    /// right-handed basis.
    private func uprightWallTransform(from hitTransform: simd_float4x4) -> simd_float4x4 {
        let position = hitTransform.columns.3
        let wallNormal = simd_normalize(
            SIMD3<Float>(hitTransform.columns.1.x, hitTransform.columns.1.y, hitTransform.columns.1.z)
        )
        let worldUp = SIMD3<Float>(0, 1, 0)

        var right = simd_cross(worldUp, wallNormal)
        if simd_length(right) < 0.0001 {
            // Degenerate case (normal nearly parallel to world up) — pick an
            // arbitrary right vector rather than producing a NaN basis.
            right = SIMD3<Float>(1, 0, 0)
        }
        right = simd_normalize(right)
        let up = simd_cross(wallNormal, right)

        return simd_float4x4(
            SIMD4<Float>(right.x, right.y, right.z, 0),
            SIMD4<Float>(up.x, up.y, up.z, 0),
            SIMD4<Float>(wallNormal.x, wallNormal.y, wallNormal.z, 0),
            position
        )
    }

    private func place(at point: CGPoint, in arView: ARView) async {
        guard let contentSource else { return }
        // `.any` so we can see WHATEVER surface the user actually tapped —
        // not just the one this item needs — so a mismatch (tapping the
        // floor for a wall item, or vice versa) can be detected and
        // explained, rather than the raycast simply coming back empty.
        let results = arView.raycast(from: point, allowing: .estimatedPlane, alignment: .any)
        guard let firstResult = results.first else { return }

        let requiredSurface = contentSource.requiredSurface
        let detectedSurface = surfaceKind(for: firstResult.worldTransform, in: arView)
        guard detectedSurface == requiredSurface else {
            ToastCenter.shared.show(
                "This looks like a \(requiredSurface.displayName) item — point your camera at a \(requiredSurface.displayName) instead of the \(detectedSurface.displayName) to place it.",
                style: .error,
                duration: .seconds(1.8)
            )
            return
        }

        let entity: Entity
        do {
            switch contentSource {
            case .parametric(let dims, _):
                entity = try ShapeBuilder.buildProductEntity(from: dims)
            case .usdzModel(let name, let dims, _, let rotationDegrees):
                entity = try await ShapeBuilder.loadModelEntity(
                    usdzNamed: name,
                    targetDimensionsCM: dims,
                    rotationDegrees: rotationDegrees,
                    usesGroundingShadows: requiredSurface != .wall
                )
            }
        } catch {
            ToastCenter.shared.error(error.localizedDescription)
            return
        }

        // A raycast/session state change may have arrived while the usdz
        // was loading (async gap) — bail rather than placing into a stale
        // or already-placed scene.
        guard !isPlaced else { return }

        // For a wall hit, ARKit's Y-axis convention (Y = surface normal)
        // points horizontally out of the wall — anchoring directly to that
        // makes every model's authored "up" axis point sideways, which is
        // why wall items came in lying flat. Floor hits don't need this: a
        // floor's normal already points straight up, matching the models.
        let anchorTransform = requiredSurface == .wall
            ? uprightWallTransform(from: firstResult.worldTransform)
            : firstResult.worldTransform
        let anchor = AnchorEntity(world: anchorTransform)
        anchor.addChild(entity)
        arView.scene.addAnchor(anchor)

        floorAnchor = anchor
        productEntity = entity
        placementIndicator?.isEnabled = false
        isPlaced = true
        scanningStatusText = "Walk around it"
        stopPulseAnimation()
        hapticImpact.impactOccurred()
        ToastCenter.shared.show(
            "Placed. Drag one finger left or right to rotate.",
            style: .success,
            duration: .seconds(1.8)
        )
    }

    // MARK: Post-placement gestures

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let entity = productEntity else { return }
        switch gesture.state {
        case .changed:
            let proposed = currentScale * Float(gesture.scale)
            let clamped = min(max(proposed, minScale), maxScale)
            entity.scale = SIMD3<Float>(repeating: clamped)
            gesture.scale = 1.0
            currentScale = clamped
        default:
            break
        }
    }

    @objc private func handlePanRotation(_ gesture: UIPanGestureRecognizer) {
        guard let entity = productEntity else { return }
        switch gesture.state {
        case .changed:
            let translation = gesture.translation(in: gesture.view)
            guard abs(translation.x) > 0 else { return }
            let yaw = simd_quatf(angle: Float(translation.x) * 0.01, axis: [0, 1, 0])
            entity.transform.rotation = entity.transform.rotation * yaw
            gesture.setTranslation(.zero, in: gesture.view)
        default:
            break
        }
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began, let arView else { return }
        // Lift and re-place: drop the current anchor, go back to indicator
        // mode. `contentSource` is left untouched so the next tap-to-place
        // uses the same (possibly-refined, for the parametric path) source.
        if let floorAnchor {
            arView.scene.removeAnchor(floorAnchor)
        }
        productEntity = nil
        self.floorAnchor = nil
        isPlaced = false
        currentScale = 1.0
        scanningStatusText = requiredPlaneAlignment == .vertical ? "Tap the wall to place" : "Tap to place"
        placementIndicator?.isEnabled = true
        startPulseAnimation()
        hapticImpact.impactOccurred()
        ToastCenter.shared.show(scanningStatusText, duration: .seconds(1.5))
    }

    // MARK: Teardown

    func tearDown() {
        stopPulseAnimation()
        ToastCenter.shared.dismissLoading()
        arView?.session.pause()
    }
}
