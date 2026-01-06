//
////
////  SignupView.swift
////  iPlate
////
////  Created by Lukesh D on 21/10/25.
////
//
//import SwiftUI
//
//struct SignupView: View {
//    @State private var email = ""
//    @State private var password = ""
//    @State private var agreeToTerms = false
//    @State private var showLogin = false
//    @State private var infoMessage = ""
//    @State private var isLoading = false
//
//    var body: some View {
//        VStack(spacing: 25) {
//            Spacer(minLength: 40)
//
//            // MARK: - Header
//            VStack(spacing: 6) {
//                Text("Create an account")
//                    .font(.title2.bold())
//                    .foregroundColor(.black)
//                Text("Join us and explore new possibilities!")
//                    .font(.subheadline)
//                    .foregroundColor(.gray)
//            }
//
//            // MARK: - Input Fields
//            VStack(spacing: 15) {
//                TextField("Enter your email", text: $email)
//                    .keyboardType(.emailAddress)
//                    .textInputAutocapitalization(.never)
//                    .padding()
//                    .background(Color(.systemGray6))
//                    .cornerRadius(10)
//
//                SecureField("Enter your password", text: $password)
//                    .padding()
//                    .background(Color(.systemGray6))
//                    .cornerRadius(10)
//            }
//            .padding(.horizontal, 25)
//
//            // MARK: - Create Account Button
//            Button(action: handleSignup) {
//                if isLoading {
//                    ProgressView("Creating account...")
//                        .frame(maxWidth: .infinity)
//                        .padding()
//                        .background(Color.orange.opacity(0.6))
//                        .cornerRadius(25)
//                } else {
//                    Text("Create account")
//                        .fontWeight(.semibold)
//                        .foregroundColor(.white)
//                        .frame(maxWidth: .infinity)
//                        .padding()
//                        .background(Color.orange)
//                        .cornerRadius(25)
//                }
//            }
//            .padding(.horizontal, 25)
//            .padding(.top, 5)
//
//            // MARK: - Terms Checkbox
//            HStack {
//                Button(action: { agreeToTerms.toggle() }) {
//                    Image(systemName: agreeToTerms ? "checkmark.square.fill" : "square")
//                        .foregroundColor(.orange)
//                        .font(.system(size: 20))
//                }
//
//                (
//                    Text("I agree to the ")
//                        .foregroundColor(.gray)
//                    + Text("Privacy Policy")
//                        .foregroundColor(.orange)
//                        .underline()
//                    + Text(" and ")
//                        .foregroundColor(.gray)
//                    + Text("Terms of Service")
//                        .foregroundColor(.orange)
//                        .underline()
//                )
//                .font(.footnote)
//            }
//            .padding(.horizontal, 25)
//
//            // MARK: - Info Message
//            if !infoMessage.isEmpty {
//                Text(infoMessage)
//                    .font(.footnote)
//                    .foregroundColor(.gray)
//                    .multilineTextAlignment(.center)
//                    .padding(.horizontal, 25)
//            }
//
//            Spacer()
//        }
//        .background(Color.white.ignoresSafeArea())
//        .fullScreenCover(isPresented: $showLogin) {
//            LoginView()
//        }
//    }
//
//    // MARK: - Signup Logic
//    private func handleSignup() {
//        guard !email.isEmpty, !password.isEmpty else {
//            infoMessage = "Please fill in all fields."
//            return
//        }
//
//        guard agreeToTerms else {
//            infoMessage = "Please agree to the terms first."
//            return
//        }
//
//        isLoading = true
//        infoMessage = "Signing up..."
//
//        AuthService.shared.signup(email: email, password: password) { result in
//            DispatchQueue.main.async {
//                isLoading = false
//                switch result {
//                case .success(let message):
//                    print("✅ Signup success:", message)
//                    infoMessage = "✅ \(message)"
//                    sendVerificationMail()
//
//                case .failure(let error):
//                    print("❌ Signup failed:", error.localizedDescription)
//                    infoMessage = "❌ \(error.localizedDescription)"
//                }
//            }
//        }
//    }
//
//    // MARK: - Send Verification
//    private func sendVerificationMail() {
//        AuthService.shared.requestVerification(email: email) { result in
//            DispatchQueue.main.async {
//                switch result {
//                case .success(let json):
//                    let message = json["message"] as? String ?? "Verification email sent successfully."
//                    print("📩 \(message)")
//                    infoMessage = message
//                    showVerificationAlert()
//                case .failure(let error):
//                    infoMessage = "❌ \(error.localizedDescription)"
//                }
//            }
//        }
//    }
//
//    // MARK: - Popup
//    private func showVerificationAlert() {
//        let alert = UIAlertController(
//            title: "Verification Sent",
//            message: "A verification link has been sent to your email. Please check your inbox to verify your account.",
//            preferredStyle: .alert
//        )
//
//        alert.addAction(UIAlertAction(title: "Open Gmail", style: .default, handler: { _ in
//            if let gmailURL = URL(string: "https://mail.google.com") {
//                UIApplication.shared.open(gmailURL)
//            }
//        }))
//
//        alert.addAction(UIAlertAction(title: "Done", style: .default, handler: { _ in
//            showLogin = true
//        }))
//
//        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
//           let root = scene.windows.first?.rootViewController {
//            root.present(alert, animated: true)
//        }
//    }
//}


//
//  SignupView.swift
//  iPlate
//
//  Created by Lukesh D on 21/10/25.
//  Updated: added Back button to return to LoginView
//

//
//  SignupView.swift
//  iPlate
//
//  Created by Lukesh D on 21/10/25.
//

import SwiftUI
import UIKit

struct SignupView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var agreeToTerms = false
    @State private var infoMessage = ""
    @State private var isLoading = false

    var body: some View {
        VStack {
            topBar

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header

                    // MARK: - Email Field (underline style)
                    VStack(spacing: 6) {
                        TextField("", text: $email, prompt: Text("xyz@gmail.com").foregroundColor(.gray))
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding(.vertical, 10)
                            .font(.system(size: 16, weight: .regular))
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(Color.gray.opacity(0.4))
                    }
                    .padding(.horizontal, 25)

                    // MARK: - Password Field (underline style with eye)
                    VStack(spacing: 6) {
                        HStack {
                            if showPassword {
                                TextField("", text: $password, prompt: Text("Enter your password").foregroundColor(.gray))
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                            } else {
                                SecureField("", text: $password, prompt: Text("Enter your password").foregroundColor(.gray))
                            }

                            Button(action: { showPassword.toggle() }) {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 10)
                        .font(.system(size: 16, weight: .regular))

                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(Color.gray.opacity(0.4))
                    }
                    .padding(.horizontal, 25)

                    // MARK: - Create account Button
                    Button(action: handleSignup) {
                        ZStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(height: 54)
                                    .frame(maxWidth: .infinity)
                            } else {
                                Text("Create account")
                                    .font(.system(size: 18, weight: .semibold))
                                    .frame(height: 54)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .foregroundColor(.white)
                        .background(buttonGradient)
                        .cornerRadius(27)
                        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 4)
                    }
                    .padding(.horizontal, 25)
                    .padding(.top, 8)

                    // MARK: - Terms checkbox & text
                    HStack(alignment: .center, spacing: 10) {
                        Button(action: { agreeToTerms.toggle() }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.gray.opacity(0.35), lineWidth: 1)
                                    .frame(width: 22, height: 22)
                                if agreeToTerms {
                                    Image(systemName: "checkmark")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 12, height: 12)
                                        .foregroundColor(.white)
                                        .background(
                                            RoundedRectangle(cornerRadius: 3)
                                                .fill(Color.orange)
                                                .frame(width: 18, height: 18)
                                        )
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())

                        (Text("I agree to the ").foregroundColor(.gray)
                            + Text("Privacy Policy").foregroundColor(.orange).underline()
                            + Text(" and ").foregroundColor(.gray)
                            + Text("Terms of Service").foregroundColor(.orange).underline()
                        )
                        .font(.footnote)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 25)
                    .padding(.top, 4)

                    // MARK: - Info Message
                    if !infoMessage.isEmpty {
                        Text(infoMessage)
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 25)
                            .padding(.top, 4)
                    }

                    // MARK: - OR Divider
                    HStack {
                        Rectangle().frame(height: 1).foregroundColor(Color.gray.opacity(0.25))
                        Text("OR").font(.footnote).foregroundColor(.gray)
                        Rectangle().frame(height: 1).foregroundColor(Color.gray.opacity(0.25))
                    }
                    .padding(.horizontal, 25)
                    .padding(.top, 8)

                    // MARK: - Social Buttons (circular)
                    HStack(spacing: 24) {
                        Spacer()
                        socialButton(imageName: "googleLogo") {
                            // Add Google login integration here if needed
                            print("Google tapped")
                        }
                        
                        Spacer()
                    }
                    .padding(.top, 8)

                    Spacer(minLength: 24)
                }
                .padding(.top, 8)
            }

            // MARK: - Footer 'Already have an account ? Log in'
            VStack {
                HStack {
                    Spacer()
                    Text("Already have an account ?")
                        .foregroundColor(Color.gray)
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Log in")
                            .foregroundColor(Color.orange)
                            .fontWeight(.semibold)
                    }
                    Spacer()
                }
                .font(.footnote)
                .padding(.vertical, 18)
            }
        }
        .background(Color.white.ignoresSafeArea())
    }

    // MARK: - Subviews / Helpers

    private var topBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.black)
                    .padding(8)
            }
            .padding(.leading, 12)

            Spacer()
        }
        .padding(.top, UIApplication.shared.windows.first?.safeAreaInsets.top ?? 12)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Create an account")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.black)
            Text("Join us and explore new possibilities!")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 25)
    }

    private var buttonGradient: LinearGradient {
        // soft orange gradient like screenshot
        LinearGradient(colors: [Color.orange.opacity(0.9), Color.orange], startPoint: .leading, endPoint: .trailing)
    }

    @ViewBuilder
    private func socialButton(imageName: String? = nil, systemName: String? = nil, action: @escaping ()->Void) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 58, height: 58)
                    .overlay(Circle().stroke(Color.gray.opacity(0.25), lineWidth: 1))
                if let imageName = imageName {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 28, height: 28)
                } else if let systemName = systemName {
                    Image(systemName: systemName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .foregroundColor(.black)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Actions

    private func handleSignup() {
        infoMessage = ""

        guard !email.trimmingCharacters(in: .whitespaces).isEmpty,
              !password.trimmingCharacters(in: .whitespaces).isEmpty else {
            infoMessage = "Please fill in all fields."
            return
        }

        guard agreeToTerms else {
            infoMessage = "Please agree to the terms first."
            return
        }

        isLoading = true
        infoMessage = "Creating account..."

        // Call signup -> then request verification email
        AuthService.shared.signup(email: email, password: password) { signupResult in
            DispatchQueue.main.async {
                switch signupResult {
                case .success(let json):
                    let message = (json["message"] as? String) ?? "Account created successfully."
                    infoMessage = "✅ \(message)"

                    // ask backend to send verification link
                    sendVerificationMail()

                case .failure(let error):
                    isLoading = false
                    infoMessage = "❌ \(error.localizedDescription)"
                }
            }
        }
    }

    private func sendVerificationMail() {
        AuthService.shared.requestVerification(email: email) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let json):
                    let message = json["message"] as? String ?? "Verification email sent. Please check your inbox."
                    infoMessage = message
                    showVerificationAlert()
                case .failure(let error):
                    infoMessage = "❌ \(error.localizedDescription)"
                }
            }
        }
    }

    private func showVerificationAlert() {
        let alert = UIAlertController(
            title: "Verification Sent",
            message: "A verification link has been sent to your email. Please check your inbox to verify your account.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Open Gmail", style: .default) { _ in
            if let gmailURL = URL(string: "https://mail.google.com") {
                UIApplication.shared.open(gmailURL)
            }
        })

        alert.addAction(UIAlertAction(title: "Done", style: .default) { _ in
            // close signup and return to LoginView
            dismiss()
        })

        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(alert, animated: true)
        }
    }
}

struct SignupView_Previews: PreviewProvider {
    static var previews: some View {
        SignupView()
    }
}
