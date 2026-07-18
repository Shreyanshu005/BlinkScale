//
//  ARCoordinator.swift
//  BlinkScalee
//
//  Owns the ARSession lifecycle: floor detection, raycast placement, and
//  post-placement gestures (pinch scale, rotate, long-press re-place).
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
    case parametric(ProductDimensions)
    case usdzModel(resourceName: String, dimensionsCM: (width: Double, height: Double, depth: Double))
}

@MainActor
final class ARCoordinator: NSObject, ObservableObject, ARSessionDelegate {

    // MARK: Published state consumed by the SwiftUI overlay

    @Published var isFloorDetected: Bool = false
    @Published var isPlaced: Bool = false
    @Published var scanningStatusText: String = "Scanning for floor…"
    @Published var placementErrorMessage: String?

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
        config.planeDetection = [.horizontal]
        // .automatic environment texturing builds reflection probes for
        // photorealistic materials — pure overhead here since our product
        // entities use flat semi-transparent PBR materials, not reflective
        // ones. Turning it off cuts real per-frame GPU cost (and silences
        // the "EnvironmentResource with no skybox texture" log spam, which
        // comes from that same reflection-probe pipeline).
        config.environmentTexturing = .none
        arView.session.run(config)

        addGestureRecognizers(to: arView)
        showPlacementIndicator()
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
        guard let result = arView.raycast(from: center, allowing: .estimatedPlane, alignment: .horizontal).first else { return }
        indicator.transform.matrix = result.worldTransform
    }

    /// Called after a "Doesn't look right?" refinement returns a new
    /// estimate. Only meaningful for the `.parametric` (live-AI) path — the
    /// usdz path shows a real model, so there's nothing to refine. If the
    /// object is already placed, rebuild the entity in place at the same
    /// anchor so the user doesn't have to re-scan or re-tap.
    func updateDimensions(_ newDimensions: ProductDimensions) {
        contentSource = .parametric(newDimensions)
        guard isPlaced, let floorAnchor, let newEntity = try? ShapeBuilder.buildProductEntity(from: newDimensions) else { return }
        productEntity?.removeFromParent()
        newEntity.scale = SIMD3<Float>(repeating: currentScale)
        floorAnchor.addChild(newEntity)
        productEntity = newEntity
    }

    // MARK: ARSessionDelegate — floor detection

    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        handleFloorAnchors(anchors)
    }

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        handleFloorAnchors(anchors)
    }

    private func handleFloorAnchors(_ anchors: [ARAnchor]) {
        guard !isFloorDetected else { return }
        let hasFloor = anchors.contains { anchor in
            guard let plane = anchor as? ARPlaneAnchor else { return false }
            return plane.alignment == .horizontal
        }
        if hasFloor {
            isFloorDetected = true
            scanningStatusText = "Tap to place"
            placementIndicator?.isEnabled = true
            startPulseAnimation()
            hapticImpact.impactOccurred()
        }
    }

    // MARK: Tap to place

    private func addGestureRecognizers(to arView: ARView) {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        arView.addGestureRecognizer(tap)

        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        arView.addGestureRecognizer(pinch)

        let rotate = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
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

    private func place(at point: CGPoint, in arView: ARView) async {
        guard let contentSource else { return }
        let results = arView.raycast(from: point, allowing: .estimatedPlane, alignment: .horizontal)
        guard let firstResult = results.first else { return }

        // Clear any error from a previous failed attempt — otherwise a
        // later successful placement would still show the stale error
        // card in PolishedARPreviewView, since it renders the error over
        // isPlaced unconditionally.
        placementErrorMessage = nil

        let entity: Entity
        do {
            switch contentSource {
            case .parametric(let dims):
                entity = try ShapeBuilder.buildProductEntity(from: dims)
            case .usdzModel(let name, let dims):
                entity = try await ShapeBuilder.loadModelEntity(usdzNamed: name, targetDimensionsCM: dims)
            }
        } catch {
            placementErrorMessage = error.localizedDescription
            return
        }

        // A raycast/session state change may have arrived while the usdz
        // was loading (async gap) — bail rather than placing into a stale
        // or already-placed scene.
        guard !isPlaced else { return }

        let anchor = AnchorEntity(world: firstResult.worldTransform)
        anchor.addChild(entity)
        arView.scene.addAnchor(anchor)

        floorAnchor = anchor
        productEntity = entity
        placementIndicator?.isEnabled = false
        isPlaced = true
        scanningStatusText = "Walk around it"
        stopPulseAnimation()
        hapticImpact.impactOccurred()
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

    @objc private func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        guard let entity = productEntity else { return }
        switch gesture.state {
        case .changed:
            let yaw = simd_quatf(angle: Float(-gesture.rotation), axis: [0, 1, 0])
            entity.transform.rotation = entity.transform.rotation * yaw
            gesture.rotation = 0
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
        scanningStatusText = "Tap to place"
        placementIndicator?.isEnabled = true
        startPulseAnimation()
        hapticImpact.impactOccurred()
    }

    // MARK: Teardown

    func tearDown() {
        stopPulseAnimation()
        arView?.session.pause()
    }
}
