//import Foundation
//
//enum APIConstants {
//    /// The base URL for all API requests.
//    /// Update this when switching environments (e.g., dev/staging/prod).
//    static let baseURL: URL = URL(string: "https://server-dev-161863711321.asia-south1.run.app")!
//
//    /// Convenience string form of the base URL if needed by legacy call sites.
//    static let base: String = baseURL.absoluteString
//
//    /// Auth endpoints
//    enum Auth {
//        /// https://server-dev-161863711321.asia-south1.run.app/auth
//        static var root: URL { baseURL.appendingPathComponent("auth") }
//    }
//}

// iPlate/Services/APIConstants.swift
import Foundation

enum APIConstants {
    static let baseURL: URL = URL(string: "https://server-dev-161863711321.asia-south1.run.app")!
    static let base: String = baseURL.absoluteString

    enum Auth {
        static var root: URL { baseURL.appendingPathComponent("auth") }
    }
    
    enum User {
        static var root: URL { baseURL.appendingPathComponent("user") }
        static var details: URL { root.appendingPathComponent("details") }
        static var goals: URL { root.appendingPathComponent("goals") }
        static var likedFoods: URL { root.appendingPathComponent("liked_foods") }
    }
}
