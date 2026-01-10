//
//  SessionStore.swift
//  iPlate
//
//  Created by Lukesh D on 10/01/26.
//

import Foundation

enum SessionStore {

    private static let tokenKey = "session_token"

    // Save token after successful login
    static func save(token: String) {
        UserDefaults.standard.set(token, forKey: tokenKey)
    }

    // Read token on app launch / verify-session
    static func get() -> String? {
        UserDefaults.standard.string(forKey: tokenKey)
    }

    // Clear token ONLY after /auth/logout success
    static func clear() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
    }
}
