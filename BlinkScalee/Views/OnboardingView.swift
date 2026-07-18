//
//  OnboardingView.swift
//  BlinkScalee
//
//  Placeholder onboarding screen. Uses the animated Aurora shader as a
//  blurred, dimmed background, with placeholder copy and a "Next" button
//  that advances to the homepage placeholder.
//

import SwiftUI

struct OnboardingView: View {
    var onNext: () -> Void

    var body: some View {
        ZStack {
            // Solid base so transparent aurora regions stay dark.
            Color.black
                .ignoresSafeArea()

            // Animated aurora, blurred and pushed back behind a scrim.
            AuroraView()
                .blur(radius: 40)
                .opacity(0.9)
                .ignoresSafeArea()

            // Darkening scrim for legible foreground content.
            LinearGradient(
                colors: [.black.opacity(0.1), .black.opacity(0.55)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Foreground placeholder content.
            VStack(spacing: 16) {
                Spacer()

                Image(systemName: "sparkles")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(.white.opacity(0.9))

                Text("Welcome to BlinkScalee")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("Onboarding placeholder")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.7))

                Spacer()

                Button(action: onNext) {
                    Text("Next")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(.white)
                        )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 24)
        }
    }
}

#Preview {
    OnboardingView(onNext: {})
}
