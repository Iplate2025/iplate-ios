//
//  ProfileViewModel.swift
//  iPlate
//  Minimal placeholder — replace with your real implementation.
//

import Foundation

final class ProfileViewModel {
    static let shared = ProfileViewModel()

    private init() {}

    private let tokenKey = "session_token"
    private let userIdKey = "user_id"
    private let emailKey = "user_email"

    var userID: String?
    var email: String?
    var sessionToken: String?
    var username: String?

    // 🔹 SAVE SESSION (called ONLY after login)
    func setUserSession(userID: String, email: String, sessionToken: String?) {
            self.userID = userID
            self.email = email
            self.sessionToken = sessionToken

            UserDefaults.standard.set(userID, forKey: "user_id")
            UserDefaults.standard.set(email, forKey: "user_email")

            if let token = sessionToken {
                UserDefaults.standard.set(token, forKey: "session_token")
            }
        }

    // 🔹 LOAD SESSION (called on app launch / splash)
    func loadSession() {
        self.userID = UserDefaults.standard.string(forKey: userIdKey)
        self.email = UserDefaults.standard.string(forKey: emailKey)
        self.sessionToken = UserDefaults.standard.string(forKey: tokenKey)
    }

    // 🔹 CLEAR SESSION (called ONLY after /auth/logout success)
    func clear() {
        userID = nil
        email = nil
        sessionToken = nil

        UserDefaults.standard.removeObject(forKey: userIdKey)
        UserDefaults.standard.removeObject(forKey: emailKey)
        UserDefaults.standard.removeObject(forKey: tokenKey)
    }
    func clearSession() {
            userID = nil
            email = nil
            sessionToken = nil
            username = nil

            UserDefaults.standard.removeObject(forKey: "session_token")
            UserDefaults.standard.removeObject(forKey: "user_id")
            UserDefaults.standard.removeObject(forKey: "user_email")
        }
    
}
