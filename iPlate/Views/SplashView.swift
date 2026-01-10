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

    // Navigation states
    @State private var showLogin = false
    @State private var showHome = false
    @State private var showOnboarding = false

    @State private var isCheckingSession = false

    var body: some View {
        ZStack {

            Color.white.ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                // MARK: - Logo
                Image("splashLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 140)
                    .scaleEffect(animateLogo ? 1.05 : 0.8)
                    .opacity(fadeOut ? 0 : 1)
                    .animation(
                        .easeInOut(duration: 1.2)
                            .repeatForever(autoreverses: true),
                        value: animateLogo
                    )

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
        .onAppear {
            startSplashFlow()
        }

        // MARK: - Navigation
        .fullScreenCover(isPresented: $showLogin) {
            LoginView()
        }
        .fullScreenCover(isPresented: $showHome) {
            HomeView()
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            NameInputView()
        }
    }

    // MARK: - Splash + Session Logic
    private func startSplashFlow() {

        // Start logo animation
        animateLogo = true

        // Fade out animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 1.0)) {
                fadeOut = true
            }
        }

        // After splash → check session
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            checkSessionAndRoute()
        }
    }

    // MARK: - Session Verification
    private func checkSessionAndRoute() {

        // 1️⃣ No stored session → Login
        guard let sessionToken = ProfileViewModel.shared.sessionToken else {
            showLogin = true
            return
        }

        // 2️⃣ Verify session
        AuthService.shared.verifySession(sessionToken: sessionToken) { result in
            DispatchQueue.main.async {
                switch result {

                case .success(let json):

                    guard
                        let userId = json["user_id"] as? String,
                        let email = json["email"] as? String
                    else {
                        ProfileViewModel.shared.clear()
                        showLogin = true
                        return
                    }

                    // Restore session
                    ProfileViewModel.shared.setUserSession(
                        userID: userId,
                        email: email,
                        sessionToken: sessionToken
                    )

                    // 3️⃣ Check onboarding status (BACKEND AUTHORITATIVE)
                    AuthService.shared.checkOnboardingStatus(sessionToken: sessionToken) { onboardResult in
                        DispatchQueue.main.async {
                            switch onboardResult {
                            case .success(let isOnboarded):
                                isOnboarded ? (showHome = true) : (showOnboarding = true)

                            case .failure:
                                showLogin = true
                            }
                        }
                    }

                case .failure:
                    // Invalid / expired session
                    ProfileViewModel.shared.clear()
                    showLogin = true
                }
            }
        }
    }
}

#Preview {
    SplashView()
}
