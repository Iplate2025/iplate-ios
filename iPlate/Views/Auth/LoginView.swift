//
//  LoginView.swift
//  iPlate
//
//  Created by Lukesh D on 22/10/25.
//  Edited: unified login + verification handling (login endpoint is authoritative).
//

import SwiftUI


struct LoginView: View {

    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var showSignup = false
    @State private var showForgotPassword = false
    @State private var infoMessage = ""
    @State private var showHomeScreen = false
    @State private var showOnboarding = false
    @State private var didRetryLogoutAll = false
    @State private var showLogoutOthersAlert = false
    @State private var conflictUserId: String?
    @State private var conflictSessionId: String?



    @StateObject private var viewModel = AuthViewModel()

    var body: some View {
        VStack(spacing: 24) {

            Spacer(minLength: 40)

            // Header
            VStack(spacing: 6) {
                Text("Login to your account")
                    .font(.title2.bold())
                    .foregroundColor(.black)

                Text("Welcome back! Please enter your details.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            // Input fields
            VStack(spacing: 16) {

                TextField("Enter your email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                HStack {
                    if showPassword {
                        TextField("Enter your password", text: $password)
                    } else {
                        SecureField("Enter your password", text: $password)
                    }

                    Button(action: {
                        showPassword.toggle()
                    }) {
                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            .padding(.horizontal, 25)

            // Forgot password
            HStack {
                Spacer()
                Button(action: {
                    showForgotPassword = true
                }) {
                    Text("Forgot Password?")
                        .foregroundColor(.orange)
                        .font(.footnote)
                }
            }
            .padding(.trailing, 25)

            // Login button
            Button(action: handleLogin) {
                if viewModel.isLoading {
                    ProgressView("Please wait...")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange.opacity(0.6))
                        .cornerRadius(25)
                } else {
                    Text("Login now")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(25)
                }
            }
            .padding(.horizontal, 25)
            .padding(.top, 5)

            // Info message
            if !infoMessage.isEmpty {
                Text(infoMessage)
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 25)
            }

            // OR divider
            HStack {
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.gray.opacity(0.3))

                Text("OR")
                    .font(.footnote)
                    .foregroundColor(.gray)

                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.gray.opacity(0.3))
            }
            .padding(.horizontal, 25)
            .padding(.top, 5)

            // Google button (UI only)
            Button(action: handleGoogleLogin) {
                HStack(spacing: 10) {
                    Image("googleLogo")
                        .resizable()
                        .frame(width: 20, height: 20)

                    Text("Continue with Google")
                        .fontWeight(.medium)
                        .foregroundColor(.black)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray5).opacity(0.5))
                .cornerRadius(25)
            }
            .padding(.horizontal, 25)

            Spacer()

            // Signup redirect
            HStack(spacing: 4) {
                Text("Don't have an account?")
                    .foregroundColor(.gray)

                Button(action: {
                    showSignup = true
                }) {
                    Text("Sign up")
                        .foregroundColor(.orange)
                        .fontWeight(.semibold)
                }
            }
            .font(.footnote)
            .padding(.bottom, 25)
        }
        .background(Color.white.ignoresSafeArea())
        .alert(
            "End other sessions?",
            isPresented: $showLogoutOthersAlert
        ) {
            Button("Cancel", role: .cancel) {
                didRetryLogoutAll = false
            }

            Button("Log out others", role: .destructive) {
                guard
                    let userId = conflictUserId,
                    let sessionId = conflictSessionId
                else {
                    infoMessage = "Unable to resolve active session."
                    return
                }

                infoMessage = "Logging out other sessions..."

                AuthService.shared.logoutAllByUserId(
                    userId: userId
                ) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success:
                            infoMessage = "Other sessions terminated. Logging in..."
                            self.handleLogin()   // 🔁 retry login once
                        case .failure(let error):
                            infoMessage = error.localizedDescription
                            didRetryLogoutAll = false
                        }
                    }
                }
            }
        }
        // Navigation destinations
        .fullScreenCover(isPresented: $showSignup) {
            SignupView()
        }
        .fullScreenCover(isPresented: $showForgotPassword) {
            ForgotPasswordView()
        }
        .fullScreenCover(isPresented: $showHomeScreen) {
            HomeView()
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            NameInputView()
        }
    }

    

    // MARK: - Login flow (single endpoint checks verification and credentials)
    private func handleLogin() {

        infoMessage = ""
        

        guard !email.isEmpty, !password.isEmpty else {
            infoMessage = "Please enter both email and password."
            return
        }
        

        viewModel.isLoading = true
        infoMessage = "Logging in..."

        AuthService.shared.login(email: email, password: password) { result in
            DispatchQueue.main.async {
                self.viewModel.isLoading = false

                switch result {

                case .success(let json):

                    // ✅ Detect "already_logged_in_elsewhere" error code
                    let errorCode = json["error"] as? String ?? ""
                    let message = json["message"] as? String ?? ""

                    let isAlreadyLoggedInElsewhere =
                        errorCode == "already_logged_in_elsewhere" ||
                        message.lowercased().contains("already signed in") ||
                        message.lowercased().contains("active session") ||
                        message.lowercased().contains("another device")

                    if isAlreadyLoggedInElsewhere {

                        // prevent infinite retry loop
                        guard !didRetryLogoutAll else {
                            infoMessage = "Unable to resolve active session. Please try again later."
                            didRetryLogoutAll = false
                            return
                        }

                        guard let userId = json["user_id"] as? String else {
                            infoMessage = "Active session exists but user could not be identified."
                            return
                        }

                        didRetryLogoutAll = true
                        infoMessage = "Logging out from other devices..."
                        print("🔄 Detected login conflict for user: \(userId). Logging out all sessions...")

                        // Automatically logout all sessions and retry — no alert needed
                        AuthService.shared.logoutAllSessions(userId: userId) { result in
                            DispatchQueue.main.async {
                                switch result {
                                case .success:
                                    print("✅ All other sessions terminated. Retrying login...")
                                    self.infoMessage = "Other sessions terminated. Logging in..."
                                    self.handleLogin() // retry login ONCE

                                case .failure(let error):
                                    print("❌ Failed to logout all sessions: \(error.localizedDescription)")
                                    self.infoMessage = "❌ Could not terminate other sessions. Please try again."
                                    self.didRetryLogoutAll = false
                                }
                            }
                        }
                        return
                    }




                    print("[LoginView] login response:", json)

                    if let verified = json["verified"] as? Bool, !verified {
                        self.infoMessage = "⚠️ Email not verified. Please verify your email before logging in."
                        self.presentNotVerifiedAlert()
                        return
                    }

                    let lower = message.lowercased()
                    if lower.contains("not verified") ||
                       lower.contains("verify your email") ||
                       lower.contains("unverified") {
                        self.infoMessage = "⚠️ \(message)"
                        self.presentNotVerifiedAlert()
                        return
                    }

                    var didSucceed = false

                    if let success = json["success"] as? Bool {
                        didSucceed = success
                    } else {
                        didSucceed = lower.contains("success") ||
                                     lower.contains("logged in") ||
                                     lower.contains("welcome")
                    }

                    if !didSucceed {
                        if !message.isEmpty {
                            self.infoMessage = "❌ \(message)"
                        } else {
                            self.infoMessage = "❌ Login failed. Please check your credentials."
                        }
                        return
                    }

                    let userEmail = (json["email"] as? String) ?? self.email
                    var userId = json["user_id"] as? String

                    if userId == nil {
                        userId = "local_" + userEmail
                            .replacingOccurrences(of: "@", with: "_")
                            .replacingOccurrences(of: ".", with: "_")
                        print("⚠️ user_id missing — generated fallback: \(userId!)")
                    }

                    let sessionToken = json["session_token"] as? String

                    // 🔴 SESSION TOKEN IS MANDATORY
                    guard let token = sessionToken else {
                        self.infoMessage = "Session error. Please login again."
                        return
                    }

                    // ✅ SAVE SESSION PROPERLY (THIS WAS MISSING)
                    ProfileViewModel.shared.setUserSession(
                        userID: userId!,
                        email: userEmail,
                        sessionToken: token
                    )


                    if let isNew = json["is_new_user"] as? Bool {
                        isNew ? self.goToOnboarding() : self.goToHome()
                        return
                    }

                    if let backendOnboard = (json["is_onboarded"] as? Bool) ?? (json["onboarded"] as? Bool) {
                        backendOnboard ? self.goToHome() : self.goToOnboarding()
                        return
                    }

                    if let token = sessionToken {
                        self.infoMessage = "Checking profile..."
                        AuthService.shared.checkOnboardingStatus(sessionToken: token) { status in
                            DispatchQueue.main.async {
                                switch status {
                                case .success(let onboarded):
                                    onboarded ? self.goToHome() : self.goToOnboarding()
                                case .failure:
                                    // fallback to local cache
                                    let onboardKey = "hasCompletedOnboarding_\(userId!)"
                                    let hasOnboarded = UserDefaults.standard.bool(forKey: onboardKey)
                                    hasOnboarded ? self.goToHome() : self.goToOnboarding()
                                }
                            }
                        }
                        return
                    }

                    // Final fallback to local cache
                    let onboardKey = "hasCompletedOnboarding_\(userId!)"
                    let hasOnboarded = UserDefaults.standard.bool(forKey: onboardKey)
                    hasOnboarded ? self.goToHome() : self.goToOnboarding()

                case .failure(let error):
                    print("[LoginView] login error:", error)
                    self.infoMessage = "❌ \(error.localizedDescription)"
                }
            }
        }
    }

    // MARK: - Alerts & helpers
    private func presentNotVerifiedAlert() {

        let alert = UIAlertController(
            title: "Email Not Verified",
            message: "Please verify your email using the link sent to your inbox. Open Gmail to verify now?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Open Gmail", style: .default) { _ in
            if let url = URL(string: "https://mail.google.com") {
                UIApplication.shared.open(url)
            }
        })

        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        presentAlert(alert)
    }
    private func handleLogoutAllAndRetry(userId: String, sessionToken: String) {

        AuthService.shared.logoutAllSessions(
            userId: userId
        ) { result in

            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("✅ All sessions terminated")
                    self.handleLogin() // retry login ONCE

                case .failure(let error):
                    self.infoMessage = error.localizedDescription
                }
            }
        }
    }






    private func presentAlert(_ alert: UIAlertController) {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(alert, animated: true)
        }
    }

    private func goToOnboarding() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            showOnboarding = true
        }
    }

    private func goToHome() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            showHomeScreen = true
        }
    }

    private func handleGoogleLogin() {
        print("Google login tapped")
    }
    
    

}

#Preview {
    LoginView()
}
