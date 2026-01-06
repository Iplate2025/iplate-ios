
//
//  AuthViewModel.swift
//  iPlate
//
//  Created by Lukesh D on 21/10/25.
//

import Foundation
import Combine

final class AuthViewModel: ObservableObject {
    @Published var isLoading = false

    // MARK: - Signup
    func signup(email: String, password: String, completion: @escaping (String) -> Void) {
        isLoading = true
        AuthService.shared.signup(email: email, password: password) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let json):
                    if let message = json["message"] as? String {
                        completion("✅ \(message)")
                    } else {
                        completion("✅ Account created successfully.")
                    }
                case .failure(let error):
                    completion("❌ \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Login
    func login(email: String, password: String, completion: @escaping (String) -> Void) {
        isLoading = true
        AuthService.shared.login(email: email, password: password) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let json):
                    if let message = json["message"] as? String {
                        completion(message)
                    } else {
                        completion("✅ Login successful")
                    }
                case .failure(let error):
                    completion("❌ \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Request Email Verification (SEND verification link)
    func requestEmailVerification(for email: String, completion: @escaping (String) -> Void) {
        AuthService.shared.requestVerification(email: email) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let json):
                    if let message = json["message"] as? String {
                        completion("📩 \(message)")
                    } else {
                        completion("📩 Verification email triggered successfully.")
                    }
                case .failure(let error):
                    completion("❌ \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Reset Password
    func resetPassword(email: String, completion: @escaping (String) -> Void) {
        isLoading = true
        AuthService.shared.resetPassword(email: email) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let json):
                    if let message = json["message"] as? String {
                        completion(message)
                    } else {
                        completion("✅ Password reset instructions sent.")
                    }
                case .failure(let error):
                    completion("❌ \(error.localizedDescription)")
                }
            }
        }
    }
}
