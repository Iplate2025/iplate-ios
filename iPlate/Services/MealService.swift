import Foundation
import UIKit

final class MealService {
    static let shared = MealService()
    private init() {}

    private func makeError(_ text: String) -> NSError {
        NSError(domain: "MealService", code: -1, userInfo: [NSLocalizedDescriptionKey: text])
    }

    // MARK: - Upload Meal
    func uploadMeal(image: UIImage, weights: [Double], completion: @escaping (Result<[String:Any], Error>) -> Void) {
        let url = APIConstants.baseURL.appendingPathComponent("upload")

        guard let userId = ProfileViewModel.shared.userID,
              let userEmail = ProfileViewModel.shared.email else {
            completion(.failure(makeError("User not authenticated")))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(userId, forHTTPHeaderField: "X-User-ID")
        request.addValue(userEmail, forHTTPHeaderField: "X-User-Email")

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        let weightsString = weights.map { "\($0)" }.joined(separator: ",")
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"weights\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(weightsString)\r\n".data(using: .utf8)!)

        if let imageData = image.jpegData(compressionQuality: 0.85) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"image\"; filename=\"meal.jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
        }
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(self.makeError("No data from upload")))
                return
            }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                completion(.success(json))
            } else {
                completion(.failure(self.makeError("Invalid upload response")))
            }
        }.resume()
    }

    // MARK: - Fetch Meals by Date
    func fetchMeals(for date: Date, completion: @escaping (Result<[String:Any], Error>) -> Void) {
        let url = APIConstants.baseURL.appendingPathComponent("meals").appendingPathComponent("by-date")

        guard let userId = ProfileViewModel.shared.userID,
              let userEmail = ProfileViewModel.shared.email else {
            completion(.failure(makeError("User not authenticated")))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(userId, forHTTPHeaderField: "X-User-ID")
        request.addValue(userEmail, forHTTPHeaderField: "X-User-Email")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let body: [String: Any] = ["date": fmt.string(from: date)]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(self.makeError("No data from meals/by-date")))
                return
            }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                completion(.success(json))
            } else {
                completion(.failure(self.makeError("Invalid meals response")))
            }
        }.resume()
    }

    // MARK: - Fetch Weekly Calories
    func fetchWeeklyCalories(completion: @escaping (Result<[String:Any], Error>) -> Void) {
        let url = APIConstants.baseURL.appendingPathComponent("meals").appendingPathComponent("calories").appendingPathComponent("weekly")
        performGETRequest(url: url, completion: completion)
    }

    // MARK: - Fetch Monthly Calories
    func fetchMonthlyCalories(completion: @escaping (Result<[String:Any], Error>) -> Void) {
        let url = APIConstants.baseURL.appendingPathComponent("meals").appendingPathComponent("calories").appendingPathComponent("monthly")
        performGETRequest(url: url, completion: completion)
    }

    // MARK: - Fetch Weekly Summary
    func fetchWeeklySummary(completion: @escaping (Result<[String:Any], Error>) -> Void) {
        let url = APIConstants.baseURL.appendingPathComponent("meals").appendingPathComponent("summary").appendingPathComponent("weekly")
        performGETRequest(url: url, completion: completion)
    }

    // MARK: - Fetch Monthly Summary
    func fetchMonthlySummary(completion: @escaping (Result<[String:Any], Error>) -> Void) {
        let url = APIConstants.baseURL.appendingPathComponent("meals").appendingPathComponent("summary").appendingPathComponent("monthly")
        performGETRequest(url: url, completion: completion)
    }

    // MARK: - Fetch Weight Logs
    func fetchWeightLogs(completion: @escaping (Result<[String:Any], Error>) -> Void) {
        let url = APIConstants.baseURL.appendingPathComponent("user").appendingPathComponent("weight_logs")
        performGETRequest(url: url, completion: completion)
    }

    // MARK: - Helper GET Request
    private func performGETRequest(url: URL, completion: @escaping (Result<[String:Any], Error>) -> Void) {
        guard let userId = ProfileViewModel.shared.userID,
              let userEmail = ProfileViewModel.shared.email else {
            completion(.failure(makeError("User not authenticated")))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(userId, forHTTPHeaderField: "X-User-ID")
        request.addValue(userEmail, forHTTPHeaderField: "X-User-Email")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(self.makeError("No data received")))
                return
            }
            if let txt = String(data: data, encoding: .utf8) {
                print("[MealService] raw response:", txt)
            }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                completion(.success(json))
            } else {
                completion(.failure(self.makeError("Invalid response format")))
            }
        }.resume()
    }
}
