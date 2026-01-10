//
//  OnboardingAPI.swift
//  iPlate
//
//  Small helper for onboarding-related server calls:
//  - POST /auth/set_username
//  - PUT  /user/details
//  - POST /auth/onboard
//

import Foundation

final class OnboardingAPI {
    static let shared = OnboardingAPI()
    private init() {}

    // NOTE: keep the same server root as your AuthService uses.
    // AuthService has baseURL = ".../auth", here we use the root then add paths.
    private let root = "https://server-dev-161863711321.asia-south1.run.app"

    private func makeError(_ text: String) -> NSError {
        NSError(domain: "OnboardingAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: text])
    }

    private func jsonDataToDictionary(_ data: Data) -> [String:Any]? {
        guard let dict = try? JSONSerialization.jsonObject(with: data) as? [String:Any] else { return nil }
        return dict
    }

    // MARK: - set_username
    // POST /auth/set_username
    func setUsername(userId: String, username: String, completion: @escaping (Result<[String:Any], Error>) -> Void) {
        guard let url = URL(string: root)?.appendingPathComponent("auth").appendingPathComponent("set_username") else {
            completion(.failure(makeError("Invalid set_username URL"))); return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String:Any] = ["user_id": userId, "username": username]
        do { request.httpBody = try JSONSerialization.data(withJSONObject: body) } catch {
            completion(.failure(error)); return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let e = error { completion(.failure(e)); return }
            guard let data = data else { completion(.failure(self.makeError("No data from set_username"))); return }
            if let http = response as? HTTPURLResponse {
                print("[OnboardingAPI] status:", http.statusCode)
                print("[OnboardingAPI] headers:", http.allHeaderFields)
            }
            if let txt = String(data: data, encoding: .utf8) {
                print("[OnboardingAPI] raw body:", txt)
            }

            if let dict = self.jsonDataToDictionary(data) {
                completion(.success(dict))
            } else {
                completion(.failure(self.makeError("Invalid JSON from set_username")))
            }
        }.resume()
    }

    // MARK: - update user details (PUT /user/details)
    // Headers: X-User-ID, X-User-Email
    func updateUserDetails(userId: String, userEmail: String, details: [String:Any], completion: @escaping (Result<[String:Any], Error>) -> Void) {
        guard let url = URL(string: root)?.appendingPathComponent("user").appendingPathComponent("details") else {
            completion(.failure(makeError("Invalid user/details URL"))); return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(userId, forHTTPHeaderField: "X-User-ID")
        request.addValue(userEmail, forHTTPHeaderField: "X-User-Email")

        do { request.httpBody = try JSONSerialization.data(withJSONObject: details) } catch {
            completion(.failure(error)); return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let e = error { completion(.failure(e)); return }
            guard let data = data else { completion(.failure(self.makeError("No data from user/details"))); return }
            if let http = response as? HTTPURLResponse {
                print("[OnboardingAPI] status:", http.statusCode)
                print("[OnboardingAPI] headers:", http.allHeaderFields)
            }
            if let txt = String(data: data, encoding: .utf8) {
                print("[OnboardingAPI] raw body:", txt)
            }

            if let dict = self.jsonDataToDictionary(data) {
                completion(.success(dict))
            } else {
                completion(.failure(self.makeError("Invalid JSON from user/details")))
            }
        }.resume()
    }

    // MARK: - check onboard (POST /auth/onboard)
    // Body: { "session_token": "..." } OR you could use GET with user_id depending on backend
    func checkOnboard(sessionToken: String, completion: @escaping (Result<[String:Any], Error>) -> Void) {
        guard let url = URL(string: root)?.appendingPathComponent("auth").appendingPathComponent("onboard") else {
            completion(.failure(makeError("Invalid /auth/onboard URL"))); return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["session_token": sessionToken]
        do { request.httpBody = try JSONSerialization.data(withJSONObject: body) } catch {
            completion(.failure(error)); return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let e = error { completion(.failure(e)); return }
            guard let data = data else { completion(.failure(self.makeError("No data from /auth/onboard"))); return }
            if let http = response as? HTTPURLResponse {
                print("[OnboardingAPI] status:", http.statusCode)
                print("[OnboardingAPI] headers:", http.allHeaderFields)
            }
            if let txt = String(data: data, encoding: .utf8) {
                print("[OnboardingAPI] raw body:", txt)
            }

            if let dict = self.jsonDataToDictionary(data) {
                completion(.success(dict))
            } else if let arr = try? JSONSerialization.jsonObject(with: data) as? [Any] {
                completion(.failure(self.makeError("Unexpected JSON type (array) from /auth/onboard: \(arr)")))
            } else {
                let snippet = String(data: data, encoding: .utf8) ?? "<non-UTF8 data>"
                completion(.failure(self.makeError("Invalid JSON from /auth/onboard. Raw: \(snippet)")))
            }
        }.resume()
    }
}
