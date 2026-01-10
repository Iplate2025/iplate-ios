import Foundation

enum APIConstants {
    /// The base URL for all API requests.
    /// Update this when switching environments (e.g., dev/staging/prod).
    static let baseURL: URL = URL(string: "https://server-dev-161863711321.asia-south1.run.app")!

    /// Convenience string form of the base URL if needed by legacy call sites.
    static let base: String = baseURL.absoluteString

    /// Auth endpoints
    enum Auth {
        /// https://server-dev-161863711321.asia-south1.run.app/auth
        static var root: URL { baseURL.appendingPathComponent("auth") }
    }
}
