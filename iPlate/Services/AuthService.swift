
// AuthService.swift
// iPlate
// Created by Lukesh D

//import Foundation

//final class AuthService {
//    static let shared = AuthService()
//    private init() {}
//
//    private let baseURL = "https://server-dev-161863711321.asia-south1.run.app/auth"
//
//    // MARK: - Signup (send verification + create account)
//    func signup(email: String, password: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
//        guard let url = URL(string: "\(baseURL)/signup") else {
//            completion(.failure(makeError("Invalid signup URL")))
//            return
//        }
//
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//
//        let body: [String: Any] = ["email": email, "password": password]
//        do { request.httpBody = try JSONSerialization.data(withJSONObject: body) } catch {
//            completion(.failure(error)); return
//        }
//
//        URLSession.shared.dataTask(with: request) { data, response, error in
//            if let err = error { completion(.failure(err)); return }
//            guard let data = data else { completion(.failure(self.makeError("No data"))); return }
//
//            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
//                completion(.success(json))
//            } else {
//                completion(.failure(self.makeError(String(data: data, encoding: .utf8) ?? "Unreadable")))
//            }
//        }.resume()
//    }
//
//    // MARK: - Login (returns raw json as dictionary)
//    func login(email: String, password: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
//        guard let url = URL(string: "\(baseURL)/login") else {
//            completion(.failure(makeError("Invalid login URL"))); return
//        }
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        let body: [String: Any] = ["email": email, "password": password]
//        do { request.httpBody = try JSONSerialization.data(withJSONObject: body) } catch {
//            completion(.failure(error)); return
//        }
//
//        print("📤 Login -> \(url) body:", body)
//        URLSession.shared.dataTask(with: request) { data, response, error in
//            if let err = error { completion(.failure(err)); return }
//            guard let data = data else { completion(.failure(self.makeError("No data"))); return }
//
//            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
//                completion(.success(json))
//            } else {
//                completion(.failure(self.makeError(String(data: data, encoding: .utf8) ?? "Unreadable")))
//            }
//        }.resume()
//    }
//
//    // MARK: - Request verification email (trigger sending verification email)
//    // Some backends expose this as /request-verification or /auth/request-verification
//    func requestVerification(email: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
//        guard let url = URL(string: "\(baseURL)/request-verification") else {
//            completion(.failure(makeError("Invalid request-verification URL"))); return
//        }
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        let body = ["email": email]
//        do { request.httpBody = try JSONSerialization.data(withJSONObject: body) } catch {
//            completion(.failure(error)); return
//        }
//
//        URLSession.shared.dataTask(with: request) { data, _, error in
//            if let err = error { completion(.failure(err)); return }
//            guard let data = data else { completion(.failure(self.makeError("No data"))); return }
//            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
//                completion(.success(json))
//            } else {
//                completion(.failure(self.makeError(String(data: data, encoding: .utf8) ?? "Unreadable")))
//            }
//        }.resume()
//    }
//
//    // MARK: - Check verification status (should return JSON { "verified": true/false } )
//    func checkVerification(email: String, completion: @escaping (Result<Bool, Error>) -> Void) {
//        guard let url = URL(string: "\(baseURL)/check-verification") else {
//            completion(.failure(makeError("Invalid check-verification URL"))); return
//        }
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        let body = ["email": email]
//        do { request.httpBody = try JSONSerialization.data(withJSONObject: body) } catch {
//            completion(.failure(error)); return
//        }
//
//        URLSession.shared.dataTask(with: request) { data, _, error in
//            if let err = error { completion(.failure(err)); return }
//            guard let data = data else { completion(.failure(self.makeError("No data"))); return }
//            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
//               let verified = json["verified"] as? Bool {
//                completion(.success(verified))
//            } else {
//                // sometimes backend returns { "message":"Verified" } — handle that
//                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
//                   let message = (json["message"] as? String)?.lowercased() {
//                    if message.contains("verified") || message.contains("already verified") {
//                        completion(.success(true)); return
//                    } else {
//                        completion(.success(false)); return
//                    }
//                }
//                completion(.failure(self.makeError("Unexpected check-verification response")))
//            }
//        }.resume()
//    }
//
//    // MARK: - Reset Password
//    func resetPassword(email: String, newPassword: String? = nil, completion: @escaping (Result<[String: Any], Error>) -> Void) {
//        // If your backend expects a separate flow, adapt accordingly.
//        guard let url = URL(string: "\(baseURL)/reset-password") else {
//            completion(.failure(makeError("Invalid reset-password URL"))); return
//        }
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//
//        var body: [String: Any] = ["email": email]
//        if let p = newPassword { body["password"] = p }
//
//        do { request.httpBody = try JSONSerialization.data(withJSONObject: body) } catch {
//            completion(.failure(error)); return
//        }
//
//        URLSession.shared.dataTask(with: request) { data, _, error in
//            if let err = error { completion(.failure(err)); return }
//            guard let data = data else { completion(.failure(self.makeError("No data"))); return }
//
//            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
//                completion(.success(json))
//            } else {
//                completion(.failure(self.makeError(String(data: data, encoding: .utf8) ?? "Unreadable")))
//            }
//        }.resume()
//    }
//
//    // MARK: - Helpers
//    private func makeError(_ text: String) -> NSError {
//        NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: text])
//    }
//}
//

//
//  AuthService.swift
//  iPlate
//
//  Created by Lukesh D on 21/10/25.
//  Clean version without an explicit client-side verification-check endpoint:
//  the server's /login is responsible for rejecting unverified accounts.
//

import Foundation

final class AuthService {
    static let shared = AuthService()
    private init() {}

    private let baseURL = "https://server-dev-161863711321.asia-south1.run.app/auth"

    // Simple NSError builder for consistent local errors
    private func authError(_ message: String) -> NSError {
        NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: message])
    }

    // MARK: - Login
    // The login endpoint is expected to return JSON with fields like:
    // { "message": "Login successful", "user_id": "...", "email": "...", ... }
    // The server should enforce email verification and return a proper message/error if not verified.
    func login(email: String, password: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/login") else {
            completion(.failure(authError("Invalid login URL")))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["email": email, "password": password]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error)); return
            }
            guard let data = data else {
                completion(.failure(self.authError("No data from login"))); return
            }

            if let txt = String(data: data, encoding: .utf8) {
                print("[AuthService.login] raw response:", txt)
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                completion(.success(json))
            } else {
                completion(.failure(self.authError("Invalid login response format.")))
            }
        }.resume()
    }

    // MARK: - Signup (send account creation request)
    // Server typically creates user and returns message (and may trigger verification email)
    func signup(email: String, password: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/signup") else {
            completion(.failure(authError("Invalid signup URL"))); return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["email": email, "password": password]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error)); return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(self.authError("No data from signup"))); return }

            if let txt = String(data: data, encoding: .utf8) {
                print("[AuthService.signup] raw response:", txt)
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                completion(.success(json))
            } else {
                completion(.failure(self.authError("Invalid signup response.")))
            }
        }.resume()
    }

    // MARK: - Request Verification (trigger sending verification email)
    // Call when you want the backend to send a verification email to the provided address.
    func requestVerification(email: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/request-verification") else {
            completion(.failure(authError("Invalid verification URL"))); return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["email": email]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error)); return
        }

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(self.authError("No data from request-verification"))); return }

            if let txt = String(data: data, encoding: .utf8) {
                print("[AuthService.requestVerification] raw response:", txt)
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                completion(.success(json))
            } else {
                completion(.failure(self.authError("Invalid request-verification response.")))
            }
        }.resume()
    }

    // MARK: - Reset Password
    // Triggers a password reset flow (server should email reset link / token)
    func resetPassword(email: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/reset-password") else {
            completion(.failure(authError("Invalid reset-password URL"))); return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["email": email]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error)); return
        }

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(self.authError("No data from reset-password"))); return }

            if let txt = String(data: data, encoding: .utf8) {
                print("[AuthService.resetPassword] raw response:", txt)
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                completion(.success(json))
            } else {
                completion(.failure(self.authError("Invalid reset-password response.")))
            }
        }.resume()
    }

    // MARK: - Check Onboarding Status (convenience)
    // GET /onboard?user_id=<id> expected to return JSON { "onboarded": true/false }
    func checkOnboardingStatus(userId: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/onboard?user_id=\(userId)") else {
            completion(.failure(authError("Invalid onboard URL"))); return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(self.authError("No data from onboard endpoint"))); return }

            if let txt = String(data: data, encoding: .utf8) {
                print("[AuthService.checkOnboardingStatus] raw response:", txt)
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let onboarded = json["onboarded"] as? Bool {
                completion(.success(onboarded))
            } else {
                completion(.failure(self.authError("Invalid onboarding response.")))
            }
        }.resume()
    }
}
