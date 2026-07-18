//
//  HomePlaceholderView.swift
//  BlinkScalee
//
//  Placeholder homepage reached after onboarding. Offers an entry point into
//  the full product catalog (every polished product page).
//

import SwiftUI

struct HomePlaceholderView: View {
    var onBrowseProducts: () -> Void = {}

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

                Button(action: onBrowseProducts) {
                    Text("Browse all products")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.blinkitOrange)
                        )
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
            }
            .padding(.horizontal, 24)
        }
    }
}

#Preview {
    HomePlaceholderView()
}
