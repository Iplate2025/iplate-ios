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

    // Production base URL (adjust for other environments as needed)
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
        guard let url = URL(string: baseURL)?.appendingPathComponent("login") else {
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
        guard let url = URL(string: baseURL)?.appendingPathComponent("signup") else {
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
        guard let url = URL(string: baseURL)?.appendingPathComponent("request-verification") else {
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
        guard let url = URL(string: baseURL)?.appendingPathComponent("reset-password") else {
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

    // MARK: - Logout (invalidate current session)
    // POST /auth/logout { session_token }
    // MARK: - Logout (invalidate current session only)
    // POST /auth/logout { session_token }
    func logout(
        sessionToken: String,
        completion: @escaping (Result<[String: Any], Error>) -> Void
    ) {
        guard let url = URL(string: baseURL)?.appendingPathComponent("logout") else {
            completion(.failure(authError("Invalid logout URL")))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["session_token": sessionToken]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(self.authError("No data from logout")))
                return
            }

            if let txt = String(data: data, encoding: .utf8) {
                print("[AuthService.logout] raw:", txt)
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                completion(.success(json))
            } else {
                completion(.failure(self.authError("Invalid logout response")))
            }
        }.resume()
    }


    // MARK: - Logout All Sessions (used only on active-session conflict)
    // POST /auth/logout-all { session_token }
    func logoutAllSessions(
        sessionToken: String,
        completion: @escaping (Result<[String: Any], Error>) -> Void
    ) {
        guard let url = URL(string: baseURL)?.appendingPathComponent("logout-all") else {
            completion(.failure(authError("Invalid logout-all URL")))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["session_token": sessionToken]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(self.authError("No data from logout-all")))
                return
            }

            if let txt = String(data: data, encoding: .utf8) {
                print("[AuthService.logoutAllSessions] raw:", txt)
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                completion(.success(json))
            } else {
                completion(.failure(self.authError("Invalid logout-all response")))
            }
        }.resume()
    }


    // MARK: - Check Onboarding Status
    // POST /auth/onboard { session_token }
    func checkOnboardingStatus(
        sessionToken: String,
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {
        guard let url = URL(string: baseURL)?.appendingPathComponent("onboard") else {
            completion(.failure(authError("Invalid onboard URL")))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["session_token": sessionToken]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(self.authError("No data from onboard endpoint")))
                return
            }

            if let txt = String(data: data, encoding: .utf8) {
                print("[AuthService.checkOnboardingStatus] raw:", txt)
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let onboarded =
                    (json["is_onboarded"] as? Bool) ??
                    (json["onboarded"] as? Bool) {

                completion(.success(onboarded))
            } else {
                completion(.failure(self.authError("Invalid onboarding response")))
            }
        }.resume()
    }

    // MARK: - Verify Session
    // GET /auth/verify-session (X-Session-Token)
    func verifySession(sessionToken: String, completion: @escaping (Result<[String:Any], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/verify-session") else {
            completion(.failure(authError("Invalid verify-session URL")))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(sessionToken, forHTTPHeaderField: "X-Session-Token")

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(error)); return
            }
            guard let data = data else {
                completion(.failure(self.authError("No data from verify-session"))); return
            }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String:Any] {
                completion(.success(json))
            } else {
                completion(.failure(self.authError("Invalid verify-session response")))
            }
        }.resume()
    }

}

