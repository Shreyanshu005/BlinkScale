//
//  ARViewContainer.swift
//  BlinkScalee
//
//  UIViewRepresentable bridge between SwiftUI and RealityKit's UIKit-based
//  ARView. Deliberately dumb: it creates the view and hands control to
//  ARCoordinator, which owns all session/gesture logic.
//

import SwiftUI
import RealityKit
import ARKit

struct ARViewContainer: UIViewRepresentable {
    let source: ARContentSource
    @ObservedObject var coordinator: ARCoordinator

    /// Without this, SwiftUI can't infer `Coordinator == ARCoordinator` and
    /// defaults it to `Void`, which then conflicts with the `ARCoordinator`
    /// parameter type in `dismantleUIView` below — that mismatch is what
    /// breaks the `UIViewRepresentable` conformance.
    func makeCoordinator() -> ARCoordinator {
        coordinator
    }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        // Grounding shadows are a floor-contact effect. RealityKit's shadow
        // compute pass is not appropriate for vertical AR planes and can hit
        // a Metal assertion for wall-mounted USDZ assets on current iOS
        // builds. Keep the normal shadow treatment for floor content.
        if source.requiredSurface == .wall {
            arView.renderOptions.insert(.disableGroundingShadows)
        }
        coordinator.setupARView(arView, source: source)
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        // Session lifecycle is owned by ARCoordinator; nothing to sync here.
        // SwiftUI state changes (pinch/rotate results, placement) flow the
        // other direction via @Published properties on the coordinator.
    }

    static func dismantleUIView(_ uiView: ARView, coordinator: ARCoordinator) {
        coordinator.tearDown()
    }
}
