//
//  EmailVerificationView.swift
//  iPlate
//
//  Created by Lukesh D on 22/10/25.
//
//  Updated to use AuthService.requestVerification(...) to both send the mail
//  and to detect verification status from the server response (message / verified flag).
//

import SwiftUI

struct EmailVerificationView: View {
    let email: String

    @State private var isVerified = false
    @State private var infoMessage = "We’ve sent a verification link to your email."
    @State private var isLoading = false
    @State private var timer: Timer?

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                Image(systemName: "envelope.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundColor(.orange)

                Text("Verify Your Email")
                    .font(.title2.bold())

                Text(infoMessage)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 25)

                if isLoading {
                    ProgressView("Checking verification...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                } else {
                    Button(action: {
                        checkVerificationStatus()
                    }) {
                        Text("I’ve verified my email")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .cornerRadius(25)
                    }
                    .padding(.horizontal, 40)
                }

                Spacer()
            }
        }
        .onAppear {
            sendVerificationEmail()    // trigger initial send
            startAutoCheck()           // start polling
        }
        .onDisappear {
            stopAutoCheck()
        }
        // when verified, go to onboarding
        .fullScreenCover(isPresented: $isVerified) {
            NameInputView()
        }
    }

    // MARK: - Send/Request verification email
    private func sendVerificationEmail() {
        isLoading = true
        infoMessage = "Sending verification email..."
        AuthService.shared.requestVerification(email: email) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let json):
                    // Preferred: server returns a "message" field or "success"
                    if let message = json["message"] as? String {
                        self.infoMessage = "📩 \(message)"
                        // If the server immediately says account is already verified, treat that as success:
                        if message.lowercased().contains("verified") || message.lowercased().contains("already verified") {
                            self.markVerified()
                        }
                    } else if let success = json["success"] as? Bool, success == true {
                        self.infoMessage = "📩 Verification email sent. Please check your inbox."
                    } else {
                        // fallback to raw JSON -> show as string
                        self.infoMessage = "📩 Verification email request completed."
                    }

                case .failure(let error):
                    self.infoMessage = "❌ \(error.localizedDescription)"
                }
            }
        }
    }

    // MARK: - Check verification status (uses requestVerification response as a probe)
    //
    // Reason: your current AuthService exposes `requestVerification(...)` which returns a
    // server message. Many backends will respond with text like "Email verified" once the
    // user has clicked the link. We try to detect that text or a "verified" field.
    private func checkVerificationStatus() {
        isLoading = true
        infoMessage = "Checking your verification status..."

        AuthService.shared.requestVerification(email: email) { result in
            DispatchQueue.main.async {
                self.isLoading = false

                switch result {
                case .success(let json):
                    // 1) Direct boolean field "verified"
                    if let verified = json["verified"] as? Bool {
                        if verified {
                            self.markVerified()
                        } else {
                            self.infoMessage = "❌ Email not verified yet. Please verify using your inbox link."
                        }
                        return
                    }

                    // 2) message field containing "verified"/"already verified"
                    if let message = json["message"] as? String {
                        let lower = message.lowercased()
                        if lower.contains("verified") || lower.contains("already verified") {
                            self.markVerified()
                        } else {
                            self.infoMessage = message
                        }
                        return
                    }

                    // 3) success + possible nested data
                    if let success = json["success"] as? Bool, success == true {
                        // Some backends may return success even if not verified — preserve a friendly message
                        self.infoMessage = "✅ Verification email resent. Please check your inbox."
                        return
                    }

                    // 4) try to look for any string values mentioning "verified"
                    var foundVerified = false
                    for (_, value) in json {
                        if let s = value as? String, s.lowercased().contains("verified") {
                            foundVerified = true
                            break
                        }
                    }
                    if foundVerified {
                        self.markVerified()
                        return
                    }

                    // fallback
                    self.infoMessage = "❌ Email not verified yet. Please check your inbox."

                case .failure(let error):
                    // show the server/network error
                    self.infoMessage = "⚠️ \(error.localizedDescription)"
                }
            }
        }
    }

    // MARK: - Polling (every 10s)
    private func startAutoCheck() {
        // ensure existing timer is invalidated first
        stopAutoCheck()

        // schedule timer on main run loop
        timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            if !self.isVerified {
                self.checkVerificationStatus()
            }
        }
    }

    private func stopAutoCheck() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Mark verified & clean up
    private func markVerified() {
        self.isVerified = true
        self.infoMessage = "✅ Email verified! Redirecting..."
        stopAutoCheck()
    }
}
