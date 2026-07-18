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
                source: .usdzModel(resourceName: usdzResourceName, dimensionsCM: dimensionsCM),
                coordinator: coordinator
            )
            .ignoresSafeArea()

            VStack {
                topStatusBar
                Spacer()
                if let errorMessage = coordinator.placementErrorMessage {
                    errorCard(errorMessage)
                } else if coordinator.isPlaced {
                    infoCard
                }
                controlBar
            }
            .padding()
        }
    }

    private var topStatusBar: some View {
        HStack {
            Image(systemName: coordinator.isFloorDetected ? "checkmark.circle.fill" : "arrow.triangle.2.circlepath")
                .foregroundStyle(coordinator.isFloorDetected ? .green : .white)
            Text(coordinator.scanningStatusText)
                .fontWeight(.medium)
            Spacer()
            Button(action: onDone) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
            }
        }
        .foregroundStyle(.white)
        .padding()
        .background(.black.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 14))
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
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func errorCard(_ message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message)
                .font(.footnote)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var controlBar: some View {
        HStack(spacing: 12) {
            controlPill(icon: "rotate.3d", label: "Twist to rotate")
            controlPill(icon: "hand.tap.fill", label: "Hold to re-place")
        }
        .font(.caption)
        .foregroundStyle(.white)
        .opacity(coordinator.isPlaced ? 1 : 0)
    }

    private func controlPill(icon: String, label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(label)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.black.opacity(0.35))
        .clipShape(Capsule())
    }
}
