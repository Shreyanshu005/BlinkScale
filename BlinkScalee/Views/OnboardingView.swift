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
            AppPalette.background
                .ignoresSafeArea()

            // Animated aurora, blurred and pushed back behind a scrim.
            AuroraView()
                .blur(radius: 40)
                .opacity(0.9)
                .ignoresSafeArea()

            // Darkening scrim for legible foreground content.
            LinearGradient(
                colors: [AppPalette.background.opacity(0.1), AppPalette.background.opacity(0.75)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Foreground placeholder content.
            VStack(spacing: 16) {
                Spacer()

                Image("mascothappy")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 160)

                VStack(spacing: 6) {
                    Text("Welcome to")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))

                    (
                        Text("Blink").fontWeight(.heavy)
                            + Text("Scalee").fontWeight(.heavy).foregroundStyle(Color.blinkitOrange)
                    )
                    .font(.system(size: 36, design: .rounded))
                    .foregroundStyle(.white)

                    Text("See it in your space before it's in your cart.")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .padding(.top, 6)
                }
                .padding(.top, 8)

                Spacer()

                Button(action: onNext) {
                    Text("Next")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .glassEffect(.regular.tint(Color.blinkitOrange).interactive(), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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
