//
//  UserService.swift
//  iPlate
//
//  Created by Lukesh D on 27/01/26.
//

// iPlate/Services/UserService.swift
import Foundation

final class UserService {
    static let shared = UserService()
    private init() {}
    
    private var userId: String? { ProfileViewModel.shared.userId }
    private var userEmail: String? { ProfileViewModel.shared.email }
    
    private func createRequest(url: URL, method: String, body: [String: Any]? = nil) -> URLRequest? {
        guard let userId = userId, let userEmail = userEmail else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(userId, forHTTPHeaderField: "X-User-ID")
        request.setValue(userEmail, forHTTPHeaderField: "X-User-Email")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let body = body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }
        
        return request
    }
    
    // MARK: - User Details
    func fetchUserDetails(completion: @escaping (Result<UserDetails, Error>) -> Void) {
        guard let request = createRequest(url: APIConstants.User.details, method: "GET") else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing credentials"])))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data"])))
                return
            }
            
            do {
                let details = try JSONDecoder().decode(UserDetails.self, from: data)
                completion(.success(details))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func updateUserDetails(_ updates: [String: Any], completion: @escaping (Result<UserDetails, Error>) -> Void) {
        guard let request = createRequest(url: APIConstants.User.details, method: "PATCH", body: updates) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing credentials"])))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data"])))
                return
            }
            
            do {
                let details = try JSONDecoder().decode(UserDetails.self, from: data)
                completion(.success(details))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - User Goals
    func fetchUserGoals(completion: @escaping (Result<UserGoals, Error>) -> Void) {
        guard let request = createRequest(url: APIConstants.User.goals, method: "GET") else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing credentials"])))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data"])))
                return
            }
            
            do {
                let goals = try JSONDecoder().decode(UserGoals.self, from: data)
                completion(.success(goals))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func updateUserGoals(_ updates: [String: Any], completion: @escaping (Result<UserGoals, Error>) -> Void) {
        guard let request = createRequest(url: APIConstants.User.goals, method: "PATCH", body: updates) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing credentials"])))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data"])))
                return
            }
            
            do {
                let response = try JSONDecoder().decode(UserGoalsResponse.self, from: data)
                if let goals = response.data {
                    completion(.success(goals))
                } else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Liked Foods
    func fetchLikedFoods(completion: @escaping (Result<[LikedFood], Error>) -> Void) {
        guard let request = createRequest(url: APIConstants.User.likedFoods, method: "GET") else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing credentials"])))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data"])))
                return
            }
            
            do {
                let response = try JSONDecoder().decode(LikedFoodsResponse.self, from: data)
                completion(.success(response.likedFoods))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func addLikedFood(_ foodName: String, completion: @escaping (Result<[LikedFood], Error>) -> Void) {
        guard let request = createRequest(url: APIConstants.User.likedFoods, method: "POST", body: ["food": foodName]) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing credentials"])))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data"])))
                return
            }
            
            do {
                let response = try JSONDecoder().decode(LikedFoodsResponse.self, from: data)
                completion(.success(response.likedFoods))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func removeLikedFood(_ foodName: String, completion: @escaping (Result<[LikedFood], Error>) -> Void) {
        guard let request = createRequest(url: APIConstants.User.likedFoods, method: "DELETE", body: ["food": foodName]) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing credentials"])))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data"])))
                return
            }
            
            do {
                let response = try JSONDecoder().decode(LikedFoodsResponse.self, from: data)
                completion(.success(response.likedFoods))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
