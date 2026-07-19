//
//  PolishedARPreviewView.swift
//  BlinkScalee
//
//  Custom AR viewer for the pre-baked demo path — replaces the system AR
//  Quick Look viewer (QLPreviewController) used previously. Quick Look gave
//  us no way to correct a usdz's baked-in scale and only the generic system
//  gesture set; this reuses the same ARCoordinator/ARViewContainer built
//  for the live-AI flow, so pinch-resize, rotate, and long-press-to-replace
//  all work identically, plus the model gets scale-corrected against the
//  product's known real dimensions before it's ever placed.
//

import SwiftUI

struct PolishedARPreviewView: View {
    let productName: String
    let productImageSystemName: String
    let usdzResourceName: String
    let dimensionsCM: (width: Double, height: Double, depth: Double)
    var requiredSurface: PlacementSurface = .floor
    var rotationDegrees: (pitchX: Double, yawY: Double, rollZ: Double) = (0, 0, 0)
    let onDone: () -> Void

    @StateObject private var coordinator = ARCoordinator()

    private var dimensionsLabel: String {
        let fmt: (Double) -> String = {
            $0.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", $0) : String(format: "%.1f", $0)
        }
        return "\(fmt(dimensionsCM.width)) × \(fmt(dimensionsCM.height)) × \(fmt(dimensionsCM.depth)) cm"
    }

    var body: some View {
        ZStack {
            ARViewContainer(
                source: .usdzModel(
                    resourceName: usdzResourceName,
                    dimensionsCM: dimensionsCM,
                    requiredSurface: requiredSurface,
                    rotationDegrees: rotationDegrees
                ),
                coordinator: coordinator
            )
            .ignoresSafeArea()

            // Gradients alone bleed under the Dynamic Island/home indicator
            // for a seamless look — the actual text sits in a SEPARATE layer
            // below that respects the safe area, so it never renders behind
            // the island itself (this matters most for wall items, whose
            // longer "Scanning for a wall…" status text is more likely to
            // sit right under the island if it isn't kept clear of it).
            VStack(spacing: 0) {
                topScrim
                Spacer()
                bottomScrim
            }
            .ignoresSafeArea()

            VStack {
                topStatusBar
                Spacer()
                VStack(spacing: 16) {
                    if coordinator.isPlaced {
                        infoCard
                    }
                    controlBar
                }
            }
            .padding()
        }
        // Now pushed via NavigationStack (see BlinkitProductPageView) rather
        // than `.fullScreenCover` — hiding the bar keeps the minimal
        // gradient look with no boxed nav chrome, but the interactive
        // edge-swipe-to-pop gesture is driven by the navigation controller
        // itself, independent of the bar's own visibility, so it still
        // works here for free alongside the visible back button below.
        .toolbar(.hidden, for: .navigationBar)
        // This screen used to be presented via `.fullScreenCover` — a
        // separate UIKit presentation layer that sits on top of everything
        // below it, including ContentView's root-level `.toastHost()`. Now
        // that it's pushed via NavigationStack it's arguably no longer
        // strictly necessary, but keeping a local host here is harmless and
        // future-proofs against this view ever being presented modally again.
        .toastHost()
    }

    private var topScrim: some View {
        LinearGradient(colors: [.black.opacity(0.55), .clear], startPoint: .top, endPoint: .bottom)
            .frame(height: 150)
            .allowsHitTesting(false)
    }

    private var bottomScrim: some View {
        LinearGradient(colors: [.clear, .black.opacity(0.6)], startPoint: .top, endPoint: .bottom)
            .frame(height: 220)
            .allowsHitTesting(false)
    }

    private var topStatusBar: some View {
        HStack {
            Image(systemName: coordinator.isFloorDetected ? "checkmark.circle.fill" : "arrow.triangle.2.circlepath")
                .foregroundStyle(coordinator.isFloorDetected ? .green : .white)
            Text(coordinator.scanningStatusText)
                .fontWeight(.medium)
            Spacer()
            Button(action: onDone) {
                Image(systemName: "chevron.backward.circle.fill")
                    .font(.title2)
            }
        }
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.5), radius: 6)
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: productImageSystemName)
                Text(productName)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                Spacer()
            }
            Text(dimensionsLabel)
                .font(.title3.weight(.bold))
            Label("Walk around it", systemImage: "figure.walk")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.7))
        }
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.5), radius: 6)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var controlBar: some View {
        HStack(spacing: 16) {
            controlPill(icon: "rotate.3d", label: "Twist to rotate")
            controlPill(icon: "hand.tap.fill", label: "Hold to re-place")
        }
        .font(.caption)
        .foregroundStyle(.white.opacity(0.9))
        .shadow(color: .black.opacity(0.5), radius: 4)
        .opacity(coordinator.isPlaced ? 1 : 0)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func controlPill(icon: String, label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(label)
        }
    }
}
