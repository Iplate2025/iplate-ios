//
//  ProfileViewModel.swift
//  iPlate
//  Minimal placeholder — replace with your real implementation.
//

import Foundation

final class ProfileViewModel {
    static let shared = ProfileViewModel()
    private init() {}

    var userID: String? = nil
    var email: String? = nil
    var username: String? = nil

    func setUserSession(userID: String, email: String) {
        self.userID = userID
        self.email = email
    }
}
