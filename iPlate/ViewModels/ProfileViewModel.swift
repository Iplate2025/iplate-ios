//
//  ProfileViewModel.swift
//  iPlate
//

import Foundation
import Combine

final class ProfileViewModel: ObservableObject {
    static let shared = ProfileViewModel()

    private init() {
        loadSession()
    }

    private let tokenKey = "session_token"
    private let userIdKey = "user_id"
    private let emailKey = "user_email"

    // PRIMARY PROPERTIES (lowercase 'd' - matches MealService, MoodService, etc.)
    @Published var userId: String?
    @Published var email: String?
    @Published var sessionToken: String?
    @Published var username: String?
    @Published var userName: String?
    @Published var dateOfBirth: Date?
    @Published var sex: String?
    @Published var units: String = "kg, cm, cal"

    // User Details
    @Published var userDetails: UserDetails?
    @Published var userGoals: UserGoals?
    @Published var likedFoods: [LikedFood] = []

    @Published var isLoading = false
    @Published var errorMessage: String?

    // LEGACY COMPUTED PROPERTY (capital 'D' - for backward compatibility)
    var userID: String? {
        get { userId }
        set { userId = newValue }
    }

    // MARK: - Session Management

    func setUserSession(userID: String, email: String, sessionToken: String?) {
        self.userId = userID
        self.email = email
        self.sessionToken = sessionToken

        UserDefaults.standard.set(userID, forKey: userIdKey)
        UserDefaults.standard.set(email, forKey: emailKey)

        if let token = sessionToken {
            UserDefaults.standard.set(token, forKey: tokenKey)
        }
    }

    func save(userId: String, email: String, userName: String?, sessionToken: String) {
        self.userId = userId
        self.email = email
        self.userName = userName
        self.username = userName
        self.sessionToken = sessionToken

        UserDefaults.standard.set(userId, forKey: userIdKey)
        UserDefaults.standard.set(email, forKey: emailKey)
        UserDefaults.standard.set(userName, forKey: "userName")
        UserDefaults.standard.set(sessionToken, forKey: tokenKey)
    }

    func loadSession() {
        self.userId = UserDefaults.standard.string(forKey: userIdKey)
        self.email = UserDefaults.standard.string(forKey: emailKey)
        self.sessionToken = UserDefaults.standard.string(forKey: tokenKey)
        self.userName = UserDefaults.standard.string(forKey: "userName")
        self.username = self.userName

        if let dobInterval = UserDefaults.standard.object(forKey: "dateOfBirth") as? TimeInterval {
            self.dateOfBirth = Date(timeIntervalSince1970: dobInterval)
        }
        self.sex = UserDefaults.standard.string(forKey: "sex")
        self.units = UserDefaults.standard.string(forKey: "units") ?? "kg, cm, cal"
    }

    func updateLocalProfile(dateOfBirth: Date?, sex: String?, units: String?) {
        if let dob = dateOfBirth {
            self.dateOfBirth = dob
            UserDefaults.standard.set(dob.timeIntervalSince1970, forKey: "dateOfBirth")
        }
        if let sex = sex {
            self.sex = sex
            UserDefaults.standard.set(sex, forKey: "sex")
        }
        if let units = units {
            self.units = units
            UserDefaults.standard.set(units, forKey: "units")
        }
    }

    func clear() {
        userId = nil
        email = nil
        sessionToken = nil
        username = nil
        userName = nil
        dateOfBirth = nil
        sex = nil
        units = "kg, cm, cal"
        userDetails = nil
        userGoals = nil
        likedFoods = []

        UserDefaults.standard.removeObject(forKey: userIdKey)
        UserDefaults.standard.removeObject(forKey: emailKey)
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: "userName")
        UserDefaults.standard.removeObject(forKey: "dateOfBirth")
        UserDefaults.standard.removeObject(forKey: "sex")
        UserDefaults.standard.removeObject(forKey: "units")
    }

    func clearSession() {
        clear()
    }

    // MARK: - API Calls

    func fetchUserDetails() {
        isLoading = true
        errorMessage = nil

        UserService.shared.fetchUserDetails { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let details):
                    self?.userDetails = details
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func updateUserDetails(_ updates: [String: Any], completion: ((Bool) -> Void)? = nil) {
        isLoading = true
        errorMessage = nil

        UserService.shared.updateUserDetails(updates) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let details):
                    self?.userDetails = details
                    completion?(true)
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    completion?(false)
                }
            }
        }
    }

    func fetchUserGoals() {
        UserService.shared.fetchUserGoals { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let goals):
                    self?.userGoals = goals
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func updateUserGoals(_ updates: [String: Any], completion: ((Bool) -> Void)? = nil) {
        isLoading = true

        UserService.shared.updateUserGoals(updates) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let goals):
                    self?.userGoals = goals
                    completion?(true)
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    completion?(false)
                }
            }
        }
    }

    func fetchLikedFoods() {
        UserService.shared.fetchLikedFoods { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let foods):
                    self?.likedFoods = foods
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }

    func addLikedFood(_ foodName: String, completion: ((Bool) -> Void)? = nil) {
        UserService.shared.addLikedFood(foodName) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let foods):
                    self?.likedFoods = foods
                    completion?(true)
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    completion?(false)
                }
            }
        }
    }

    func removeLikedFood(_ foodName: String, completion: ((Bool) -> Void)? = nil) {
        UserService.shared.removeLikedFood(foodName) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let foods):
                    self?.likedFoods = foods
                    completion?(true)
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    completion?(false)
                }
            }
        }
    }

    func isFoodLiked(_ foodName: String) -> Bool {
        likedFoods.contains { $0.food.lowercased() == foodName.lowercased() }
    }
    
    func toggleLikedFood(_ foodName: String, completion: ((Bool) -> Void)? = nil) {
        if isFoodLiked(foodName) {
            removeLikedFood(foodName, completion: completion)
        } else {
            addLikedFood(foodName, completion: completion)
        }
    }
}
