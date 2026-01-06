//
//  SplashView.swift
//  iPlate
//
//  Created by Lukesh D on 21/10/25.
//

import SwiftUI

struct SplashView: View {
    @State private var animateLogo = false
    @State private var fadeOut = false
    @State private var showNextScreen = false

    var body: some View {
        ZStack {
            // Background color
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                // MARK: - Logo
                Image("splashLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 140)
                    .scaleEffect(animateLogo ? 1.05 : 0.8)
                    .opacity(fadeOut ? 0 : 1)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: animateLogo)

                Spacer()

                // MARK: - Tagline
                Text("Eat what you need")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.orange, Color.green.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .opacity(fadeOut ? 0 : 1)
                    .padding(.bottom, 50)
            }
        }
        // MARK: - On Appear Animations
        .onAppear {
            // Start pulsing animation
            animateLogo = true

            // Fade out before navigating
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeOut(duration: 1.0)) {
                    fadeOut = true
                }
            }

            // Navigate after splash
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                showNextScreen = true
            }
        }

        // MARK: - Navigation to Next View
        .fullScreenCover(isPresented: $showNextScreen) {
            LoginView() // 👈 or change to your next screen (e.g., SignupView)
        }
    }
}

#Preview {
    SplashView()
}

