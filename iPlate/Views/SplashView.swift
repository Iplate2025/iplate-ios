import SwiftUI

struct SplashView: View {

    @State private var animateLogo = false
    @State private var fadeOut = false
    @State private var nextScreen: NextScreen = .login

    enum NextScreen {
        case login
        case home
    }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

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
            animateLogo = true
            checkSessionAndRoute()
        }
        .fullScreenCover(isPresented: .constant(fadeOut)) {
            if nextScreen == .home {
                HomeView()
            } else {
                LoginView()
            }
        }
    }

    // MARK: - SESSION CHECK LOGIC
    private func checkSessionAndRoute() {

        // Small delay to show splash animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {

            guard let token = UserDefaults.standard.string(forKey: "session_token"),
                  !token.isEmpty else {
                routeTo(.login)
                return
            }

            // Verify with backend
            AuthService.shared.verifySession(sessionToken: token) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let json):
                        print("[SplashView] verify-session:", json)

                        // Restore session
                        let userId = json["user_id"] as? String
                        let email = json["email"] as? String
                        let username = json["username"] as? String

                        if let userId, let email {
                            ProfileViewModel.shared.setUserSession(
                                userID: userId,
                                email: email,
                                sessionToken: token
                            )
                            ProfileViewModel.shared.username = username
                            routeTo(.home)
                        } else {
                            clearSessionAndGoLogin()
                        }

                    case .failure:
                        clearSessionAndGoLogin()
                    }
                }
            }
        }
    }

    private func routeTo(_ screen: NextScreen) {
        withAnimation(.easeOut(duration: 0.8)) {
            fadeOut = true
            nextScreen = screen
        }
    }

    private func clearSessionAndGoLogin() {
        ProfileViewModel.shared.clearSession()
        routeTo(.login)
    }
}
