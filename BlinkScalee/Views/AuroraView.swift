//
//  AuroraView.swift
//  BlinkScalee
//
//  SwiftUI wrapper around the `aurora` Metal color effect. Drives the shader's
//  time uniform with a TimelineView so it animates continuously, and applies it
//  to a filled rectangle. Mirrors the props of the original React/OGL component.
//

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

    // Fixed start reference so `time` is stable across redraws.
    private let start = Date()

    var body: some View {
        TimelineView(.animation) { timeline in
            let elapsed = timeline.date.timeIntervalSince(start)
            // Matches the web pacing: time * speed * 0.1, with time ~ t * 0.01
            // rolled into a plain seconds value scaled here.
            let t = elapsed * speed

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
                            .color(colorStops.indices.contains(0) ? colorStops[0] : .purple),
                            .color(colorStops.indices.contains(1) ? colorStops[1] : .green),
                            .color(colorStops.indices.contains(2) ? colorStops[2] : .purple)
                        )
                    )
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    AuroraView()
        .background(AppPalette.background)
}
