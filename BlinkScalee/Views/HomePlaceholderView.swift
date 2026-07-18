//
//  HomePlaceholderView.swift
//  BlinkScalee
//
//  Placeholder homepage reached after onboarding.
//

import SwiftUI

struct HomePlaceholderView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Image(systemName: "house.fill")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(.secondary)

                Text("Home")
                    .font(.system(size: 28, weight: .bold, design: .rounded))

                Text("Homepage placeholder")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    HomePlaceholderView()
}
