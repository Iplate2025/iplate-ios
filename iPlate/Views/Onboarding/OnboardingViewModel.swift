//
//  OnboardingViewModel.swift
//  iPlate
//

import Foundation
import Combine

final class OnboardingViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var infoMessage: String = ""

    // set username
    func setUsername(userId: String, username: String, completion: @escaping (Result<[String:Any], Error>) -> Void) {
        isLoading = true
        infoMessage = ""
        OnboardingAPI.shared.setUsername(userId: userId, username: username) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let json):
                    self.infoMessage = (json["message"] as? String) ?? "Username set"
                    completion(.success(json))
                case .failure(let error):
                    self.infoMessage = "❌ \(error.localizedDescription)"
                    completion(.failure(error))
                }
            }
        }
    }

    // update details
    func updateUserDetails(userId: String, userEmail: String, details: [String:Any], completion: @escaping (Result<[String:Any], Error>) -> Void) {
        isLoading = true
        infoMessage = ""
        OnboardingAPI.shared.updateUserDetails(userId: userId, userEmail: userEmail, details: details) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let json):
                    self.infoMessage = (json["message"] as? String) ?? "Profile updated"
                    completion(.success(json))
                case .failure(let error):
                    self.infoMessage = "❌ \(error.localizedDescription)"
                    completion(.failure(error))
                }
            }
        }
    }

    // check onboard by session token
    func checkOnboard(sessionToken: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        isLoading = true
        infoMessage = ""
        OnboardingAPI.shared.checkOnboard(sessionToken: sessionToken) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let json):
                    if let isOnboarded = json["is_onboarded"] as? Bool {
                        completion(.success(isOnboarded))
                    } else if let msg = json["message"] as? String {
                        completion(.success(msg.lowercased().contains("complete") || msg.lowercased().contains("onboarded")))
                    } else {
                        completion(.failure(NSError(domain: "OnboardingVM", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unexpected onboard response"])))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
}
