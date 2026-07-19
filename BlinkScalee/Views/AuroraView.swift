//
//  AuroraView.swift
//  BlinkScalee
//
//  SwiftUI wrapper around the `aurora` Metal color effect. Drives the shader's
//  time uniform with a TimelineView so it animates continuously, and applies it
//  to a filled rectangle. Mirrors the props of the original React/OGL component.
//

import Foundation
import SwiftUI

struct AuroraView: View {
    /// Three color stops (start, middle, end), same defaults as the web version.
    var colorStops: [Color] = [
        Color(red: 216 / 255, green: 91 / 255, blue: 41 / 255), // #D85B29
        Color(red: 216 / 255, green: 91 / 255, blue: 41 / 255), // #D85B29
        Color(red: 216 / 255, green: 91 / 255, blue: 41 / 255)  // #D85B29
    ]
    var amplitude: Double = 1.0
    var blend: Double = 0.5
    var speed: Double = 1.0
    /// Home and Category use this to drift between blue, yellow, orange, and
    /// red without changing the calmer onboarding treatment.
    var cyclesWarmPalette = false

    // Fixed start reference so `time` is stable across redraws.
    private let start = Date()

    var body: some View {
        TimelineView(.animation) { timeline in
            let elapsed = timeline.date.timeIntervalSince(start)
            // Matches the web pacing: time * speed * 0.1, with time ~ t * 0.01
            // rolled into a plain seconds value scaled here.
            let t = elapsed * speed
            let colors = cyclesWarmPalette ? cyclingColors(at: elapsed) : colorStops

            GeometryReader { geo in
                let size = geo.size
                Rectangle()
                    .fill(AppPalette.background)
                    .colorEffect(
                        ShaderLibrary.aurora(
                            .float2(Float(size.width), Float(size.height)),
                            .float(Float(t)),
                            .float(Float(amplitude)),
                            .float(Float(blend)),
                            .color(colors.indices.contains(0) ? colors[0] : .purple),
                            .color(colors.indices.contains(1) ? colors[1] : .green),
                            .color(colors.indices.contains(2) ? colors[2] : .purple)
                        )
                    )
            }
        }
        .ignoresSafeArea()
    }

    private func cyclingColors(at time: TimeInterval) -> [Color] {
        let palette: [SIMD3<Double>] = [
            SIMD3(0.16, 0.38, 0.95), // blue
            SIMD3(1.00, 0.76, 0.16), // yellow
            SIMD3(0.94, 0.32, 0.10), // orange
            SIMD3(0.82, 0.12, 0.18)  // red
        ]

        func color(offset: Double) -> Color {
            let phase = (time * 0.045 + offset).truncatingRemainder(dividingBy: 1)
            let scaled = phase * Double(palette.count)
            let index = Int(scaled) % palette.count
            let next = (index + 1) % palette.count
            let progress = scaled - floor(scaled)
            let value = palette[index] + (palette[next] - palette[index]) * progress
            return Color(red: value.x, green: value.y, blue: value.z)
        }

        return [color(offset: 0), color(offset: 0.33), color(offset: 0.66)]
    }
}

#Preview {
    AuroraView()
        .background(AppPalette.background)
}
