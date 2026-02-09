//import SwiftUI
//
//// MARK: - Models
//struct FoodItem: Identifiable, Codable, Sendable {
//    let id = UUID()
//    let foodCode: String
//    let foodName: String
//    let proteinG: Double?
//    let carbG: Double?
//    let fatG: Double?
//    let fibreG: Double?
//    let energyKcal: Double?
//    let energyKj: Double?
//    let imagePath: [String]?
//
//    enum CodingKeys: String, CodingKey {
//        case foodCode = "food_code"
//        case foodName = "food_name"
//        case proteinG = "protein_g"
//        case carbG = "carb_g"
//        case fatG = "fat_g"
//        case fibreG = "fibre_g"
//        case energyKcal = "energy_kcal"
//        case energyKj = "energy_kj"
//        case imagePath = "image_path"
//    }
//
//    var imageURL: URL? {
//        guard let path = imagePath?.first, !path.isEmpty else { return nil }
//        return URL(string: path)
//    }
//
//    var protein: Double { proteinG ?? 0 }
//    var carb: Double { carbG ?? 0 }
//    var fat: Double { fatG ?? 0 }
//    var fibre: Double { fibreG ?? 0 }
//    var calories: Double { energyKcal ?? 0 }
//}
//
//struct SuggestFoodResponse: Codable, Sendable {
//    let count: Int
//    let mealType: String
//    let suggestions: [FoodItem]
//
//    enum CodingKeys: String, CodingKey {
//        case count
//        case mealType = "meal_type"
//        case suggestions
//    }
//}
//
//struct TopFoodsResponse: Codable, Sendable {
//    let appliedBestTime: String?
//    let count: Int
//    let dbBestTimeFilter: String?
//    let items: [FoodItem]
//    let userId: String
//
//    enum CodingKeys: String, CodingKey {
//        case appliedBestTime = "applied_best_time"
//        case count
//        case dbBestTimeFilter = "db_best_time_filter"
//        case items
//        case userId = "user_id"
//    }
//}
//
//// MARK: - Search Service
//class SearchService {
//    static let shared = SearchService()
//    private let baseURL = "https://server-dev-161863711321.asia-south1.run.app"
//
//    private var headers: [String: String] {
//        var headers = ["Content-Type": "application/json"]
//        if let userId = ProfileViewModel.shared.userID {
//            headers["X-User-ID"] = userId
//        }
//        if let email = ProfileViewModel.shared.email {
//            headers["X-User-Email"] = email
//        }
//        return headers
//    }
//
//    // MARK: - Search Foods
//    func searchFoods(query: String, completion: @escaping (Result<[FoodItem], Error>) -> Void) {
//        guard let url = URL(string: "\(baseURL)/search") else {
//            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
//            return
//        }
//
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
//
//        let body = ["q": query]
//        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
//
//        URLSession.shared.dataTask(with: request) { data, response, error in
//            if let error = error {
//                completion(.failure(error))
//                return
//            }
//
//            guard let data = data else {
//                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data"])))
//                return
//            }
//
//            // Debug print
//            if let jsonString = String(data: data, encoding: .utf8) {
//                print("Search Response: \(jsonString)")
//            }
//
//            do {
//                let decoder = JSONDecoder()
//                let foods = try decoder.decode([FoodItem].self, from: data)
//                completion(.success(foods))
//            } catch {
//                print("Decoding error: \(error)")
//                completion(.failure(error))
//            }
//        }.resume()
//    }
//
//    // MARK: - Suggest Foods
//    func suggestFoods(completion: @escaping (Result<SuggestFoodResponse, Error>) -> Void) {
//        guard let url = URL(string: "\(baseURL)/suggest_food") else {
//            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
//            return
//        }
//
//        var request = URLRequest(url: url)
//        request.httpMethod = "GET"
//        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
//
//        URLSession.shared.dataTask(with: request) { data, response, error in
//            if let error = error {
//                completion(.failure(error))
//                return
//            }
//
//            guard let data = data else {
//                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data"])))
//                return
//            }
//
//            // Debug print
//            if let jsonString = String(data: data, encoding: .utf8) {
//                print("Suggest Response: \(jsonString)")
//            }
//
//            do {
//                let decoder = JSONDecoder()
//                let response = try decoder.decode(SuggestFoodResponse.self, from: data)
//                completion(.success(response))
//            } catch {
//                print("Decoding error for /suggest_food: \(error)")
//                if let decodingError = error as? DecodingError {
//                    switch decodingError {
//                    case .keyNotFound(let key, let context):
//                        print("Key '\(key.stringValue)' not found: \(context.debugDescription)")
//                    case .valueNotFound(let type, let context):
//                        print("Value of type \(type) not found: \(context.debugDescription)")
//                    case .typeMismatch(let type, let context):
//                        print("Type mismatch for type \(type): \(context.debugDescription)")
//                    case .dataCorrupted(let context):
//                        print("Data corrupted: \(context.debugDescription)")
//                    @unknown default:
//                        print("Unknown decoding error")
//                    }
//                }
//                completion(.failure(error))
//            }
//        }.resume()
//    }
//
//    // MARK: - Top Protein Foods
//    func fetchTopProtein(completion: @escaping (Result<[FoodItem], Error>) -> Void) {
//        fetchTopFoods(endpoint: "/foods/top-protein", completion: completion)
//    }
//
//    // MARK: - Top Carb Foods
//    func fetchTopCarbs(completion: @escaping (Result<[FoodItem], Error>) -> Void) {
//        fetchTopFoods(endpoint: "/foods/top-carb", completion: completion)
//    }
//
//    // MARK: - Top Fats Foods
//    func fetchTopFats(completion: @escaping (Result<[FoodItem], Error>) -> Void) {
//        fetchTopFoods(endpoint: "/foods/top-fats", completion: completion)
//    }
//
//    // MARK: - Top Fibre Foods
//    func fetchTopFibre(completion: @escaping (Result<[FoodItem], Error>) -> Void) {
//        fetchTopFoods(endpoint: "/foods/top-fibre", completion: completion)
//    }
//
//    private func fetchTopFoods(endpoint: String, completion: @escaping (Result<[FoodItem], Error>) -> Void) {
//        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
//            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
//            return
//        }
//
//        var request = URLRequest(url: url)
//        request.httpMethod = "GET"
//        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
//
//        URLSession.shared.dataTask(with: request) { data, response, error in
//            if let error = error {
//                completion(.failure(error))
//                return
//            }
//
//            guard let data = data else {
//                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data"])))
//                return
//            }
//
//            // Debug print
//            if let jsonString = String(data: data, encoding: .utf8) {
//                print("\(endpoint) Response: \(jsonString)")
//            }
//
//            do {
//                let decoder = JSONDecoder()
//                let response = try decoder.decode(TopFoodsResponse.self, from: data)
//                completion(.success(response.items))
//            } catch {
//                print("Decoding error for \(endpoint): \(error)")
//                completion(.failure(error))
//            }
//        }.resume()
//    }
//}
//
//// MARK: - Filter Type
//enum NutrientFilter: String, CaseIterable {
//    case protein = "Protein"
//    case carbs = "Carbs"
//    case fats = "Fats"
//    case fibre = "Fibre"
//}
//
//// MARK: - Search View
//struct SearchView: View {
//    @State private var searchText = ""
//    @State private var suggestedFoods: [FoodItem] = []
//    @State private var featuredFoods: [FoodItem] = []
//    @State private var searchResults: [FoodItem] = []
//    @State private var isLoadingSuggestions = false
//    @State private var isLoadingFeatured = false
//    @State private var isSearching = false
//    @State private var selectedFilter: NutrientFilter = .protein
//    @State private var showFilterMenu = false
//    @State private var suggestedMealType = "breakfast"
//    @State private var favorites: Set<String> = []
//
//    var body: some View {
//        VStack(spacing: 0) {
//            // Search Header
//            HStack(spacing: 12) {
//                Button(action: {}) {
//                    Image(systemName: "arrow.left")
//                        .font(.title2)
//                        .foregroundColor(.primary)
//                }
//
//                HStack {
//                    Image(systemName: "magnifyingglass")
//                        .foregroundColor(.gray)
//                    TextField("Search", text: $searchText, onCommit: performSearch)
//                        .autocapitalization(.none)
//                        .disableAutocorrection(true)
//                    if !searchText.isEmpty {
//                        Button(action: { searchText = "" }) {
//                            Image(systemName: "xmark.circle.fill")
//                                .foregroundColor(.gray)
//                        }
//                    }
//                }
//                .padding(12)
//                .background(Color(.systemGray6))
//                .cornerRadius(12)
//            }
//            .padding(.horizontal)
//            .padding(.top, 8)
//
//            ScrollView(showsIndicators: false) {
//                VStack(alignment: .leading, spacing: 20) {
//                    // Show search results if searching
//                    if !searchText.isEmpty && !searchResults.isEmpty {
//                        VStack(alignment: .leading, spacing: 12) {
//                            Text("Search Results")
//                                .font(.title2)
//                                .fontWeight(.bold)
//                                .padding(.horizontal)
//
//                            LazyVStack(spacing: 12) {
//                                ForEach(searchResults) { food in
//                                    FoodRowView(
//                                        food: food,
//                                        isFavorite: favorites.contains(food.foodCode),
//                                        onFavorite: { toggleFavorite(food) }
//                                    )
//                                }
//                            }
//                            .padding(.horizontal)
//                        }
//                    } else if isSearching {
//                        ProgressView("Searching...")
//                            .frame(maxWidth: .infinity)
//                            .padding()
//                    } else {
//                        // Suggested Breakfast
//                        VStack(alignment: .leading, spacing: 12) {
//                            Text("Suggested \(suggestedMealType.capitalized)")
//                                .font(.title2)
//                                .fontWeight(.bold)
//                                .padding(.horizontal)
//
//                            if isLoadingSuggestions {
//                                ProgressView()
//                                    .frame(maxWidth: .infinity)
//                                    .padding()
//                            } else if suggestedFoods.isEmpty {
//                                Text("No suggestions available")
//                                    .font(.subheadline)
//                                    .foregroundColor(.secondary)
//                                    .padding(.horizontal)
//                            } else {
//                                ScrollView(.horizontal, showsIndicators: false) {
//                                    HStack(spacing: 12) {
//                                        ForEach(suggestedFoods.prefix(5)) { food in
//                                            SuggestedFoodCard(food: food)
//                                        }
//                                    }
//                                    .padding(.horizontal)
//                                }
//                            }
//                        }
//
//                        // Featured Food Section
//                        VStack(alignment: .leading, spacing: 12) {
//                            HStack {
//                                Text("Featured Food")
//                                    .font(.title2)
//                                    .fontWeight(.bold)
//
//                                Spacer()
//
//                                Menu {
//                                    ForEach(NutrientFilter.allCases, id: \.self) { filter in
//                                        Button(action: {
//                                            selectedFilter = filter
//                                            fetchFeaturedFoods()
//                                        }) {
//                                            HStack {
//                                                Text(filter.rawValue)
//                                                if selectedFilter == filter {
//                                                    Image(systemName: "checkmark")
//                                                }
//                                            }
//                                        }
//                                    }
//                                } label: {
//                                    HStack(spacing: 4) {
//                                        Text(selectedFilter.rawValue)
//                                            .font(.subheadline)
//                                            .foregroundColor(.orange)
//                                        Image(systemName: "chevron.down")
//                                            .font(.caption)
//                                            .foregroundColor(.orange)
//                                    }
//                                    .padding(.horizontal, 12)
//                                    .padding(.vertical, 6)
//                                    .background(Color.orange.opacity(0.1))
//                                    .cornerRadius(8)
//                                }
//                            }
//                            .padding(.horizontal)
//
//                            if isLoadingFeatured {
//                                ProgressView()
//                                    .frame(maxWidth: .infinity)
//                                    .padding()
//                            } else {
//                                LazyVStack(spacing: 12) {
//                                    ForEach(featuredFoods) { food in
//                                        FoodRowView(
//                                            food: food,
//                                            isFavorite: favorites.contains(food.foodCode),
//                                            onFavorite: { toggleFavorite(food) }
//                                        )
//                                    }
//                                }
//                                .padding(.horizontal)
//                            }
//                        }
//                    }
//
//                    Spacer()
//                        .frame(height: 20)
//                }
//            }
//        }
//        .background(Color(.systemGroupedBackground))
//        .task {
//            fetchSuggestedFoods()
//            fetchFeaturedFoods()
//        }
//        .onChange(of: searchText) { _, newValue in
//            if newValue.isEmpty {
//                searchResults = []
//            }
//        }
//    }
//
//    // MARK: - API Calls
//    private func performSearch() {
//        guard !searchText.isEmpty else { return }
//        isSearching = true
//
//        SearchService.shared.searchFoods(query: searchText) { result in
//            DispatchQueue.main.async {
//                isSearching = false
//                switch result {
//                case .success(let foods):
//                    searchResults = foods
//                case .failure(let error):
//                    print("Search error: \(error.localizedDescription)")
//                    searchResults = []
//                }
//            }
//        }
//    }
//
//    private func fetchSuggestedFoods() {
//        isLoadingSuggestions = true
//
//        SearchService.shared.suggestFoods { result in
//            DispatchQueue.main.async {
//                isLoadingSuggestions = false
//                switch result {
//                case .success(let response):
//                    suggestedFoods = response.suggestions
//                    suggestedMealType = response.mealType
//                    print("✅ Fetched \(response.suggestions.count) suggested foods for \(response.mealType)")
//                case .failure(let error):
//                    print("❌ Suggest error: \(error.localizedDescription)")
//                    suggestedFoods = []
//                }
//            }
//        }
//    }
//
//    private func fetchFeaturedFoods() {
//        isLoadingFeatured = true
//
//        let fetchFunction: (@escaping (Result<[FoodItem], Error>) -> Void) -> Void
//
//        switch selectedFilter {
//        case .protein:
//            fetchFunction = SearchService.shared.fetchTopProtein
//        case .carbs:
//            fetchFunction = SearchService.shared.fetchTopCarbs
//        case .fats:
//            fetchFunction = SearchService.shared.fetchTopFats
//        case .fibre:
//            fetchFunction = SearchService.shared.fetchTopFibre
//        }
//
//        fetchFunction { result in
//            DispatchQueue.main.async {
//                isLoadingFeatured = false
//                switch result {
//                case .success(let foods):
//                    featuredFoods = foods
//                case .failure(let error):
//                    print("Featured error: \(error.localizedDescription)")
//                }
//            }
//        }
//    }
//
//    private func toggleFavorite(_ food: FoodItem) {
//        profileViewModel.toggleLikedFood(food.foodName)
//    }
//
//    private func isFavorite(_ food: FoodItem) -> Bool {
//        favorites.contains(food.foodName.lowercased())
//    }
//}
//
//// MARK: - Filter Type
//enum NutrientFilter: String, CaseIterable {
//    case protein = "Protein"
//    case carbs = "Carbs"
//    case fats = "Fats"
//    case fibre = "Fibre"
//}
//
//// MARK: - Search View
//struct SearchView: View {
//    @ObservedObject private var profileViewModel = ProfileViewModel.shared
//    @State private var searchText = ""
//    @State private var suggestedFoods: [FoodItem] = []
//    @State private var featuredFoods: [FoodItem] = []
//    @State private var searchResults: [FoodItem] = []
//    @State private var isLoadingSuggestions = false
//    @State private var isLoadingFeatured = false
//    @State private var isSearching = false
//    @State private var selectedFilter: NutrientFilter = .protein
//    @State private var suggestedMealType: String? = nil
//
//    // Use ProfileViewModel for favorites
//    private var favorites: Set<String> {
//        Set(profileViewModel.likedFoods.map { $0.food.lowercased() })
//    }
//
//    var body: some View {
//        VStack(spacing: 0) {
//            // Search Header
//            HStack(spacing: 12) {
//                Button(action: {}) {
//                    Image(systemName: "arrow.left")
//                        .font(.title2)
//                        .foregroundColor(.primary)
//                }
//
//                HStack {
//                    Image(systemName: "magnifyingglass")
//                        .foregroundColor(.gray)
//                    TextField("Search", text: $searchText, onCommit: performSearch)
//                        .autocapitalization(.none)
//                        .disableAutocorrection(true)
//                    if !searchText.isEmpty {
//                        Button(action: { searchText = "" }) {
//                            Image(systemName: "xmark.circle.fill")
//                                .foregroundColor(.gray)
//                        }
//                    }
//                }
//                .padding(12)
//                .background(Color(.systemGray6))
//                .cornerRadius(12)
//            }
//            .padding(.horizontal)
//            .padding(.top, 8)
//
//            ScrollView(showsIndicators: false) {
//                VStack(alignment: .leading, spacing: 20) {
//                    // Show search results if searching
//                    if !searchText.isEmpty && !searchResults.isEmpty {
//                        VStack(alignment: .leading, spacing: 12) {
//                            Text("Search Results")
//                                .font(.title2)
//                                .fontWeight(.bold)
//                                .padding(.horizontal)
//
//                            LazyVStack(spacing: 12) {
//                                ForEach(searchResults) { food in
//                                    FoodRowView(
//                                        food: food,
//                                        isFavorite: profileViewModel.isFoodLiked(food.foodName),
//                                        onFavorite: { toggleFavorite(food) }
//                                    )
//                                }
//                            }
//                            .padding(.horizontal)
//                        }
//                    } else if isSearching {
//                        ProgressView("Searching...")
//                            .frame(maxWidth: .infinity)
//                            .padding()
//                    } else {
//                        // Suggested Breakfast
//                        VStack(alignment: .leading, spacing: 12) {
//                            Text("Suggested \(suggestedMealType?.capitalized ?? "")")
//                                .font(.title2)
//                                .fontWeight(.bold)
//                                .padding(.horizontal)
//
//                            if isLoadingSuggestions {
//                                ProgressView()
//                                    .frame(maxWidth: .infinity)
//                                    .padding()
//                            } else {
//                                ScrollView(.horizontal, showsIndicators: false) {
//                                    HStack(spacing: 12) {
//                                        ForEach(suggestedFoods.prefix(5)) { food in
//                                            SuggestedFoodCard(food: food)
//                                        }
//                                    }
//                                    .padding(.horizontal)
//                                }
//                            }
//                        }
//
//                        // Featured Food Section
//                        VStack(alignment: .leading, spacing: 12) {
//                            HStack {
//                                Text("Featured Food")
//                                    .font(.title2)
//                                    .fontWeight(.bold)
//
//                                Spacer()
//
//                                Menu {
//                                    ForEach(NutrientFilter.allCases, id: \.self) { filter in
//                                        Button(action: {
//                                            selectedFilter = filter
//                                            fetchFeaturedFoods()
//                                        }) {
//                                            HStack {
//                                                Text(filter.rawValue)
//                                                if selectedFilter == filter {
//                                                    Image(systemName: "checkmark")
//                                                }
//                                            }
//                                        }
//                                    }
//                                } label: {
//                                    HStack(spacing: 4) {
//                                        Text(selectedFilter.rawValue)
//                                            .font(.subheadline)
//                                            .foregroundColor(.orange)
//                                        Image(systemName: "chevron.down")
//                                            .font(.caption)
//                                            .foregroundColor(.orange)
//                                    }
//                                    .padding(.horizontal, 12)
//                                    .padding(.vertical, 6)
//                                    .background(Color.orange.opacity(0.1))
//                                    .cornerRadius(8)
//                                }
//                            }
//                            .padding(.horizontal)
//
//                            if isLoadingFeatured {
//                                ProgressView()
//                                    .frame(maxWidth: .infinity)
//                                    .padding()
//                            } else {
//                                LazyVStack(spacing: 12) {
//                                    ForEach(featuredFoods) { food in
//                                        FoodRowView(
//                                            food: food,
//                                            isFavorite: favorites.contains(food.foodCode),
//                                            onFavorite: { toggleFavorite(food) }
//                                        )
//                                    }
//                                }
//                                .padding(.horizontal)
//                            }
//                        }
//                    }
//
//                    Spacer()
//                        .frame(height: 20)
//                }
//            }
//        }
//        .background(Color(.systemGroupedBackground))
//        .task {
//            fetchSuggestedFoods()
//            fetchFeaturedFoods()
//        }
//        .onChange(of: searchText) { _, newValue in
//            if newValue.isEmpty {
//                searchResults = []
//            }
//        }
//    }
//
//    // MARK: - API Calls
//    private func performSearch() {
//        guard !searchText.isEmpty else { return }
//        isSearching = true
//
//        SearchService.shared.searchFoods(query: searchText) { result in
//            DispatchQueue.main.async {
//                isSearching = false
//                switch result {
//                case .success(let foods):
//                    searchResults = foods
//                case .failure(let error):
//                    print("Search error: \(error.localizedDescription)")
//                    searchResults = []
//                }
//            }
//        }
//    }
//
//    private func fetchSuggestedFoods() {
//        isLoadingSuggestions = true
//
//        SearchService.shared.suggestFoods { result in
//            DispatchQueue.main.async {
//                isLoadingSuggestions = false
//                switch result {
//                case .success(let response):
//                    suggestedFoods = response.suggestions
//                    suggestedMealType = response.mealType
//                case .failure(let error):
//                    print("Suggest error: \(error.localizedDescription)")
//                }
//            }
//        }
//    }
//
//    private func fetchFeaturedFoods() {
//        isLoadingFeatured = true
//
//        let fetchFunction: (@escaping (Result<[FoodItem], Error>) -> Void) -> Void
//
//        switch selectedFilter {
//        case .protein:
//            fetchFunction = SearchService.shared.fetchTopProtein
//        case .carbs:
//            fetchFunction = SearchService.shared.fetchTopCarbs
//        case .fats:
//            fetchFunction = SearchService.shared.fetchTopFats
//        case .fibre:
//            fetchFunction = SearchService.shared.fetchTopFibre
//        }
//
//        fetchFunction { result in
//            DispatchQueue.main.async {
//                isLoadingFeatured = false
//                switch result {
//                case .success(let foods):
//                    featuredFoods = foods
//                case .failure(let error):
//                    print("Featured error: \(error.localizedDescription)")
//                }
//            }
//        }
//    }
//
//    private func toggleFavorite(_ food: FoodItem) {
//        profileViewModel.toggleLikedFood(food.foodName)
//    }
//
//    private func isFavorite(_ food: FoodItem) -> Bool {
//        favorites.contains(food.foodName.lowercased())
//    }
//}
//
//// MARK: - Suggested Food Card
//struct SuggestedFoodCard: View {
//    let food: FoodItem
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            AsyncImage(url: food.imageURL) { phase in
//                switch phase {
//                case .empty:
//                    RoundedRectangle(cornerRadius: 12)
//                        .fill(Color(.systemGray5))
//                        .frame(width: 140, height: 100)
//                        .overlay(ProgressView())
//                case .success(let image):
//                    image
//                        .resizable()
//                        .scaledToFill()
//                        .frame(width: 140, height: 100)
//                        .clipped()
//                case .failure:
//                    RoundedRectangle(cornerRadius: 12)
//                        .fill(Color(.systemGray5))
//                        .frame(width: 140, height: 100)
//                        .overlay(
//                            Image(systemName: "photo")
//                                .foregroundColor(.gray)
//                        )
//                @unknown default:
//                    EmptyView()
//                }
//            }
//            .frame(width: 140, height: 100)
//            .clipShape(RoundedRectangle(cornerRadius: 12))
//
//            Text(food.foodName)
//                .font(.subheadline)
//                .fontWeight(.medium)
//                .lineLimit(2)
//                .frame(width: 140, alignment: .leading)
//
//            Text("\(Int(food.calories)) cal")
//                .font(.caption)
//                .foregroundColor(.secondary)
//        }
//        .frame(width: 140)
//    }
//}
//
//// MARK: - Food Row View
//struct FoodRowView: View {
//    let food: FoodItem
//    let isFavorite: Bool
//    let onFavorite: () -> Void
//
//    var body: some View {
//        HStack(spacing: 12) {
//            // Food Image
//            ZStack(alignment: .topLeading) {
//                AsyncImage(url: food.imageURL) { phase in
//                    switch phase {
//                    case .empty:
//                        RoundedRectangle(cornerRadius: 12)
//                            .fill(Color(.systemGray5))
//                            .overlay(ProgressView())
//                    case .success(let image):
//                        image
//                            .resizable()
//                            .scaledToFill()
//                    case .failure:
//                        RoundedRectangle(cornerRadius: 12)
//                            .fill(Color(.systemGray5))
//                            .overlay(
//                                Image(systemName: "photo")
//                                    .foregroundColor(.gray)
//                            )
//                    @unknown default:
//                        EmptyView()
//                    }
//                }
//                .frame(width: 80, height: 80)
//                .clipShape(RoundedRectangle(cornerRadius: 12))
//
//                // Favorite Button
//                Button(action: onFavorite) {
//                    Image(systemName: isFavorite ? "heart.fill" : "heart")
//                        .font(.system(size: 16))
//                        .foregroundColor(isFavorite ? .red : .white)
//                        .padding(4)
//                        .background(Circle().fill(Color.black.opacity(0.3)))
//                }
//                .offset(x: 4, y: 4)
//            }
//
//            // Food Details
//            VStack(alignment: .leading, spacing: 4) {
//                HStack {
//                    Text(food.foodName)
//                        .font(.subheadline)
//                        .fontWeight(.medium)
//                        .lineLimit(2)
//
//                    Spacer()
//
//                    Text("(100g)")
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                }
//
//                Text("Protein: \(Int(food.protein))-\(Int(food.protein) + 2)g")
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//
//                Text("Calories: \(Int(food.calories)) kcal")
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//            }
//
//            // Arrow
//            Image(systemName: "chevron.right")
//                .foregroundColor(.gray)
//                .font(.caption)
//        }
//        .padding(12)
//        .background(
//            RoundedRectangle(cornerRadius: 16)
//                .fill(Color(.systemBackground))
//        )
//        .overlay(
//            RoundedRectangle(cornerRadius: 16)
//                .stroke(Color(.systemGray4), lineWidth: 1)
//        )
//    }
//}
//
//#Preview {
//    SearchView()
//}


//-------------------------------------------------------------------------
import SwiftUI

// MARK: - Models
struct FoodItem: Identifiable, Codable, Sendable {
    let id = UUID()
    let foodCode: String
    let foodName: String
    let proteinG: Double?
    let carbG: Double?
    let fatG: Double?
    let fibreG: Double?
    let energyKcal: Double?
    let energyKj: Double?
    let imagePath: [String]?

    enum CodingKeys: String, CodingKey {
        case foodCode = "food_code"
        case foodName = "food_name"
        case proteinG = "protein_g"
        case carbG = "carb_g"
        case fatG = "fat_g"
        case fibreG = "fibre_g"
        case energyKcal = "energy_kcal"
        case energyKj = "energy_kj"
        case imagePath = "image_path"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        foodCode = try container.decode(String.self, forKey: .foodCode)
        foodName = try container.decode(String.self, forKey: .foodName)
        proteinG = try container.decodeIfPresent(Double.self, forKey: .proteinG)
        carbG = try container.decodeIfPresent(Double.self, forKey: .carbG)
        fatG = try container.decodeIfPresent(Double.self, forKey: .fatG)
        fibreG = try container.decodeIfPresent(Double.self, forKey: .fibreG)
        energyKcal = try container.decodeIfPresent(Double.self, forKey: .energyKcal)
        energyKj = try container.decodeIfPresent(Double.self, forKey: .energyKj)
        imagePath = try container.decodeIfPresent([String].self, forKey: .imagePath)
    }

    var imageURL: URL? {
        guard let path = imagePath?.first, !path.isEmpty else { return nil }
        return URL(string: path)
    }
    
    var protein: Double { proteinG ?? 0 }
    var carb: Double { carbG ?? 0 }
    var fat: Double { fatG ?? 0 }
    var fibre: Double { fibreG ?? 0 }
    var calories: Double { energyKcal ?? 0 }
}

struct SuggestFoodResponse: Codable, Sendable {
    let count: Int
    let mealType: String
    let suggestions: [FoodItem]

    enum CodingKeys: String, CodingKey {
        case count
        case mealType = "meal_type"
        case suggestions
    }
    
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        count = try container.decode(Int.self, forKey: .count)
        mealType = try container.decode(String.self, forKey: .mealType)
        suggestions = try container.decode([FoodItem].self, forKey: .suggestions)
    }
}

struct TopFoodsResponse: Codable, Sendable {
    let appliedBestTime: String?
    let count: Int
    let dbBestTimeFilter: String?
    let items: [FoodItem]
    let userId: String

    enum CodingKeys: String, CodingKey {
        case appliedBestTime = "applied_best_time"
        case count
        case dbBestTimeFilter = "db_best_time_filter"
        case items
        case userId = "user_id"
    }
    
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        appliedBestTime = try container.decodeIfPresent(String.self, forKey: .appliedBestTime)
        count = try container.decode(Int.self, forKey: .count)
        dbBestTimeFilter = try container.decodeIfPresent(String.self, forKey: .dbBestTimeFilter)
        items = try container.decode([FoodItem].self, forKey: .items)
        userId = try container.decode(String.self, forKey: .userId)
    }
}

// MARK: - Search Service
class SearchService {
    static let shared = SearchService()
    private let baseURL = "https://server-dev-161863711321.asia-south1.run.app"

    private var headers: [String: String] {
        var headers = ["Content-Type": "application/json"]
        if let userId = ProfileViewModel.shared.userID {
            headers["X-User-ID"] = userId
        }
        if let email = ProfileViewModel.shared.email {
            headers["X-User-Email"] = email
        }
        return headers
    }

    // MARK: - Search Foods
    func searchFoods(query: String, completion: @escaping (Result<[FoodItem], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/search") else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        let body = ["q": query]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data"])))
                return
            }

            // Debug print
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Search Response: \(jsonString)")
            }

            do {
                let decoder = JSONDecoder()
                let foods = try decoder.decode([FoodItem].self, from: data)
                completion(.success(foods))
            } catch {
                print("Decoding error: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }

    // MARK: - Suggest Foods
    func suggestFoods(completion: @escaping (Result<SuggestFoodResponse, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)/suggest_food") else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data"])))
                return
            }

            // Debug print
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Suggest Response: \(jsonString)")
            }

            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(SuggestFoodResponse.self, from: data)
                DispatchQueue.main.async {
                    completion(.success(response))
                }
            } catch {
                print("Decoding error: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
    }

    // MARK: - Top Protein Foods
    func fetchTopProtein(completion: @escaping (Result<[FoodItem], Error>) -> Void) {
        fetchTopFoods(endpoint: "/foods/top-protein", completion: completion)
    }

    // MARK: - Top Carb Foods
    func fetchTopCarbs(completion: @escaping (Result<[FoodItem], Error>) -> Void) {
        fetchTopFoods(endpoint: "/foods/top-carb", completion: completion)
    }

    // MARK: - Top Fats Foods
    func fetchTopFats(completion: @escaping (Result<[FoodItem], Error>) -> Void) {
        fetchTopFoods(endpoint: "/foods/top-fats", completion: completion)
    }

    // MARK: - Top Fibre Foods
    func fetchTopFibre(completion: @escaping (Result<[FoodItem], Error>) -> Void) {
        fetchTopFoods(endpoint: "/foods/top-fibre", completion: completion)
    }

    private func fetchTopFoods(endpoint: String, completion: @escaping (Result<[FoodItem], Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data"])))
                return
            }

            // Debug print
            if let jsonString = String(data: data, encoding: .utf8) {
                print("\(endpoint) Response: \(jsonString)")
            }

            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(TopFoodsResponse.self, from: data)
                DispatchQueue.main.async {
                    completion(.success(response.items))
                }
            } catch {
                print("Decoding error for \(endpoint): \(error)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
}

// MARK: - Filter Type
enum NutrientFilter: String, CaseIterable {
    case protein = "Protein"
    case carbs = "Carbs"
    case fats = "Fats"
    case fibre = "Fibre"
}

// MARK: - Search View
struct SearchView: View {
    @ObservedObject private var profileViewModel = ProfileViewModel.shared
    @State private var searchText = ""
    @State private var suggestedFoods: [FoodItem] = []
    @State private var featuredFoods: [FoodItem] = []
    @State private var searchResults: [FoodItem] = []
    @State private var isLoadingSuggestions = false
    @State private var isLoadingFeatured = false
    @State private var isSearching = false
    @State private var selectedFilter: NutrientFilter = .protein
    @State private var suggestedMealType: String? = nil
    @State private var showAllFeatured = false
    
    // Use ProfileViewModel for favorites - match by food name (lowercased)
    private func isFoodLiked(_ foodName: String) -> Bool {
        profileViewModel.likedFoods.contains { $0.food.lowercased() == foodName.lowercased() }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search Header
            HStack(spacing: 12) {
                Button(action: {}) {
                    Image(systemName: "arrow.left")
                        .font(.title2)
                        .foregroundColor(.primary)
                }

                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search", text: $searchText, onCommit: performSearch)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.top, 8)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // Show search results if searching
                    if !searchText.isEmpty && !searchResults.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Search Results")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)

                            LazyVStack(spacing: 12) {
                                ForEach(searchResults) { food in
                                    FoodRowView(
                                        food: food,
                                        isFavorite: isFoodLiked(food.foodName),
                                        onFavorite: { toggleFavorite(food) }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    } else if isSearching {
                        ProgressView("Searching...")
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        // Suggested Breakfast
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Suggested \(suggestedMealType?.capitalized ?? "")")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)

                            if isLoadingSuggestions {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(suggestedFoods.prefix(5)) { food in
                                            SuggestedFoodCard(
                                                food: food,
                                                onFavorite: { toggleFavorite(food) },
                                                isFavorite: isFoodLiked(food.foodName)
                                            )
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }

                        // Featured Food Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Featured Food")
                                    .font(.title2)
                                    .fontWeight(.bold)

                                Spacer()

                                Menu {
                                    ForEach(NutrientFilter.allCases, id: \.self) { filter in
                                        Button(action: {
                                            selectedFilter = filter
                                            fetchFeaturedFoods()
                                        }) {
                                            HStack {
                                                Text(filter.rawValue)
                                                if selectedFilter == filter {
                                                    Image(systemName: "checkmark")
                                                }
                                            }
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(selectedFilter.rawValue)
                                            .font(.subheadline)
                                            .foregroundColor(.orange)
                                        Image(systemName: "chevron.down")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.orange.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal)

                            if isLoadingFeatured {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            } else {
                                LazyVStack(spacing: 12) {
                                    ForEach(showAllFeatured ? featuredFoods : Array(featuredFoods.prefix(3))) { food in
                                        FoodRowView(
                                            food: food,
                                            isFavorite: isFoodLiked(food.foodName),
                                            onFavorite: { toggleFavorite(food) }
                                        )
                                    }
                                }
                                .padding(.horizontal)

                                if !showAllFeatured && featuredFoods.count > 3 {
                                    Button(action: {
                                        withAnimation {
                                            showAllFeatured = true
                                        }
                                    }) {
                                        Text("more >")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.top, 8)
                                }
                            }
                        }
                    }

                    Spacer()
                        .frame(height: 20)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .task {
            profileViewModel.fetchLikedFoods()
            fetchSuggestedFoods()
            fetchFeaturedFoods()
        }
        .onChange(of: searchText) { _, newValue in
            if newValue.isEmpty {
                searchResults = []
            }
        }
        .onChange(of: selectedFilter) { _, _ in
            showAllFeatured = false
        }
    }

    // MARK: - API Calls
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        isSearching = true

        SearchService.shared.searchFoods(query: searchText) { result in
            DispatchQueue.main.async {
                isSearching = false
                switch result {
                case .success(let foods):
                    searchResults = foods
                case .failure(let error):
                    print("Search error: \(error.localizedDescription)")
                    searchResults = []
                }
            }
        }
    }

    private func fetchSuggestedFoods() {
        isLoadingSuggestions = true

        SearchService.shared.suggestFoods { result in
            DispatchQueue.main.async {
                isLoadingSuggestions = false
                switch result {
                case .success(let response):
                    suggestedFoods = response.suggestions
                    suggestedMealType = response.mealType
                case .failure(let error):
                    print("Suggest error: \(error.localizedDescription)")
                }
            }
        }
    }

    private func fetchFeaturedFoods() {
        isLoadingFeatured = true

        let fetchFunction: (@escaping (Result<[FoodItem], Error>) -> Void) -> Void

        switch selectedFilter {
        case .protein:
            fetchFunction = SearchService.shared.fetchTopProtein
        case .carbs:
            fetchFunction = SearchService.shared.fetchTopCarbs
        case .fats:
            fetchFunction = SearchService.shared.fetchTopFats
        case .fibre:
            fetchFunction = SearchService.shared.fetchTopFibre
        }

        fetchFunction { result in
            DispatchQueue.main.async {
                isLoadingFeatured = false
                switch result {
                case .success(let foods):
                    featuredFoods = foods
                case .failure(let error):
                    print("Featured error: \(error.localizedDescription)")
                }
            }
        }
    }

    private func toggleFavorite(_ food: FoodItem) {
        profileViewModel.toggleLikedFood(food.foodName)
    }
}

// MARK: - Suggested Food Card
struct SuggestedFoodCard: View {
    let food: FoodItem
    let onFavorite: () -> Void
    let isFavorite: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 8) {
                AsyncImage(url: food.imageURL) { phase in
                    switch phase {
                    case .empty:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray5))
                            .frame(width: 140, height: 100)
                            .overlay(ProgressView())
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 140, height: 100)
                            .clipped()
                    case .failure:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray5))
                            .frame(width: 140, height: 100)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 140, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Text(food.foodName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .frame(width: 140, alignment: .leading)

                Text("\(Int(food.calories)) cal")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Button(action: onFavorite) {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .foregroundColor(isFavorite ? .red : .white)
                    .padding(6)
                    .background(Circle().fill(Color.black.opacity(0.3)))
            }
            .padding(8)
        }
        .frame(width: 140)
    }
}

// MARK: - Food Row View
struct FoodRowView: View {
    let food: FoodItem
    let isFavorite: Bool
    let onFavorite: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Food Image
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: food.imageURL) { phase in
                    switch phase {
                    case .empty:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray5))
                            .overlay(ProgressView())
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray5))
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Favorite Button
                Button(action: onFavorite) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 14))
                        .foregroundColor(isFavorite ? .red : .white)
                        .padding(4)
                        .background(Circle().fill(Color.black.opacity(0.3)))
                }
                .offset(x: -4, y: 4)
            }

            // Food Details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(food.foodName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(2)

                    Spacer()

                    Text("(100g)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text("Protein: \(Int(food.protein))-\(Int(food.protein) + 2)g")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("Calories: \(Int(food.calories)) kcal")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Arrow
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.caption)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}

#Preview {
    SearchView()
}


//---------------------------

//import SwiftUI
//
//// MARK: - Models
//struct FoodItem: Identifiable, Codable, Sendable {
//    let id = UUID()
//    let foodCode: String
//    let foodName: String
//    let proteinG: Double?
//    let carbG: Double?
//    let fatG: Double?
//    let fibreG: Double?
//    let energyKcal: Double?
//    let energyKj: Double?
//    let imagePath: [String]?
//
//    enum CodingKeys: String, CodingKey {
//        case foodCode = "food_code"
//        case foodName = "food_name"
//        case proteinG = "protein_g"
//        case carbG = "carb_g"
//        case fatG = "fat_g"
//        case fibreG = "fibre_g"
//        case energyKcal = "energy_kcal"
//        case energyKj = "energy_kj"
//        case imagePath = "image_path"
//    }
//
//    var imageURL: URL? {
//        guard let path = imagePath?.first, !path.isEmpty else { return nil }
//        return URL(string: path)
//    }
//
//    var protein: Double { proteinG ?? 0 }
//    var carb: Double { carbG ?? 0 }
//    var fat: Double { fatG ?? 0 }
//    var fibre: Double { fibreG ?? 0 }
//    var calories: Double { energyKcal ?? 0 }
//}
//
//struct SuggestFoodResponse: Codable, Sendable {
//    let count: Int
//    let mealType: String
//    let suggestions: [FoodItem]
//
//    enum CodingKeys: String, CodingKey {
//        case count
//        case mealType = "meal_type"
//        case suggestions
//    }
//}
//
//struct TopFoodsResponse: Codable, Sendable {
//    let appliedBestTime: String?
//    let count: Int
//    let dbBestTimeFilter: String?
//    let items: [FoodItem]
//    let userId: String
//
//    enum CodingKeys: String, CodingKey {
//        case appliedBestTime = "applied_best_time"
//        case count
//        case dbBestTimeFilter = "db_best_time_filter"
//        case items
//        case userId = "user_id"
//    }
//}
//
//// MARK: - Search Service
//class SearchService {
//    static let shared = SearchService()
//    private let baseURL = "https://server-dev-161863711321.asia-south1.run.app"
//
//    private var headers: [String: String] {
//        var headers = ["Content-Type": "application/json"]
//        if let userId = ProfileViewModel.shared.userID {
//            headers["X-User-ID"] = userId
//        }
//        if let email = ProfileViewModel.shared.email {
//            headers["X-User-Email"] = email
//        }
//        return headers
//    }
//
//    // MARK: - Search Foods
//    func searchFoods(query: String, completion: @escaping (Result<[FoodItem], Error>) -> Void) {
//        guard let url = URL(string: "\(baseURL)/search") else {
//            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
//            return
//        }
//
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
//
//        let body = ["q": query]
//        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
//
//        URLSession.shared.dataTask(with: request) { data, response, error in
//            if let error = error {
//                completion(.failure(error))
//                return
//            }
//
//            guard let data = data else {
//                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data"])))
//                return
//            }
//
//            do {
//                let decoder = JSONDecoder()
//                let foods = try decoder.decode([FoodItem].self, from: data)
//                completion(.success(foods))
//            } catch {
//                print("Decoding error: \(error)")
//                completion(.failure(error))
//            }
//        }.resume()
//    }
//
//    // MARK: - Suggest Foods
//    func suggestFoods(completion: @escaping (Result<SuggestFoodResponse, Error>) -> Void) {
//        guard let url = URL(string: "\(baseURL)/suggest_food") else {
//            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
//            return
//        }
//
//        var request = URLRequest(url: url)
//        request.httpMethod = "GET"
//        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
//
//        URLSession.shared.dataTask(with: request) { data, response, error in
//            if let error = error {
//                completion(.failure(error))
//                return
//            }
//
//            guard let data = data else {
//                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data"])))
//                return
//            }
//
//            do {
//                let decoder = JSONDecoder()
//                let response = try decoder.decode(SuggestFoodResponse.self, from: data)
//                completion(.success(response))
//            } catch {
//                print("Decoding error for /suggest_food: \(error)")
//                completion(.failure(error))
//            }
//        }.resume()
//    }
//
//    // MARK: - Top Protein Foods
//    func fetchTopProtein(completion: @escaping (Result<[FoodItem], Error>) -> Void) {
//        fetchTopFoods(endpoint: "/foods/top-protein", completion: completion)
//    }
//
//    // MARK: - Top Carb Foods
//    func fetchTopCarbs(completion: @escaping (Result<[FoodItem], Error>) -> Void) {
//        fetchTopFoods(endpoint: "/foods/top-carb", completion: completion)
//    }
//
//    // MARK: - Top Fats Foods
//    func fetchTopFats(completion: @escaping (Result<[FoodItem], Error>) -> Void) {
//        fetchTopFoods(endpoint: "/foods/top-fats", completion: completion)
//    }
//
//    // MARK: - Top Fibre Foods
//    func fetchTopFibre(completion: @escaping (Result<[FoodItem], Error>) -> Void) {
//        fetchTopFoods(endpoint: "/foods/top-fibre", completion: completion)
//    }
//
//    private func fetchTopFoods(endpoint: String, completion: @escaping (Result<[FoodItem], Error>) -> Void) {
//        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
//            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
//            return
//        }
//
//        var request = URLRequest(url: url)
//        request.httpMethod = "GET"
//        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
//
//        URLSession.shared.dataTask(with: request) { data, response, error in
//            if let error = error {
//                completion(.failure(error))
//                return
//            }
//
//            guard let data = data else {
//                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data"])))
//                return
//            }
//
//            do {
//                let decoder = JSONDecoder()
//                let response = try decoder.decode(TopFoodsResponse.self, from: data)
//                completion(.success(response.items))
//            } catch {
//                print("Decoding error for \(endpoint): \(error)")
//                completion(.failure(error))
//            }
//        }.resume()
//    }
//}
//
//// MARK: - Filter Type
//enum NutrientFilter: String, CaseIterable {
//    case protein = "Protein"
//    case carbs = "Carbs"
//    case fats = "Fats"
//    case fibre = "Fibre"
//}
//
//// MARK: - Search View
//struct SearchView: View {
//    @State private var searchText = ""
//    @State private var suggestedFoods: [FoodItem] = []
//    @State private var featuredFoods: [FoodItem] = []
//    @State private var searchResults: [FoodItem] = []
//    @State private var isLoadingSuggestions = false
//    @State private var isLoadingFeatured = false
//    @State private var isSearching = false
//    @State private var selectedFilter: NutrientFilter = .protein
//    @State private var showFilterMenu = false
//    @State private var suggestedMealType = "breakfast"
//    @State private var favorites: Set<String> = []
//    @State private var isNonEatingTime = false
//    @State private var nextMealInfo: (name: String, time: String)?
//
//    var body: some View {
//        VStack(spacing: 0) {
//            // Search Header
//            HStack(spacing: 12) {
//                Button(action: {}) {
//                    Image(systemName: "arrow.left")
//                        .font(.title2)
//                        .foregroundColor(.primary)
//                }
//
//                HStack {
//                    Image(systemName: "magnifyingglass")
//                        .foregroundColor(.gray)
//                    TextField("Search", text: $searchText, onCommit: performSearch)
//                        .autocapitalization(.none)
//                        .disableAutocorrection(true)
//                    if !searchText.isEmpty {
//                        Button(action: { searchText = "" }) {
//                            Image(systemName: "xmark.circle.fill")
//                                .foregroundColor(.gray)
//                        }
//                    }
//                }
//                .padding(12)
//                .background(Color(.systemGray6))
//                .cornerRadius(12)
//            }
//            .padding(.horizontal)
//            .padding(.top, 8)
//
//            ScrollView(showsIndicators: false) {
//                VStack(alignment: .leading, spacing: 20) {
//                    // Show search results if searching
//                    if !searchText.isEmpty && !searchResults.isEmpty {
//                        VStack(alignment: .leading, spacing: 12) {
//                            Text("Search Results")
//                                .font(.title2)
//                                .fontWeight(.bold)
//                                .padding(.horizontal)
//
//                            LazyVStack(spacing: 12) {
//                                ForEach(searchResults) { food in
//                                    FoodRowView(
//                                        food: food,
//                                        isFavorite: favorites.contains(food.foodCode),
//                                        onFavorite: { toggleFavorite(food) }
//                                    )
//                                }
//                            }
//                            .padding(.horizontal)
//                        }
//                    } else if isSearching {
//                        ProgressView("Searching...")
//                            .frame(maxWidth: .infinity)
//                            .padding()
//                    } else if isNonEatingTime {
//                        // Non-Eating Time View
//                        NonEatingTimeView(nextMeal: nextMealInfo?.name ?? "Next Meal", nextMealTime: nextMealInfo?.time ?? "")
//                            .padding(.horizontal)
//                            .padding(.top, 40)
//                    } else {
//                        // Suggested Breakfast
//                        VStack(alignment: .leading, spacing: 12) {
//                            Text("Suggested \(suggestedMealType.capitalized)")
//                                .font(.title2)
//                                .fontWeight(.bold)
//                                .padding(.horizontal)
//
//                            if isLoadingSuggestions {
//                                ProgressView()
//                                    .frame(maxWidth: .infinity)
//                                    .padding()
//                            } else if suggestedFoods.isEmpty {
//                                Text("No suggestions available")
//                                    .font(.subheadline)
//                                    .foregroundColor(.secondary)
//                                    .padding(.horizontal)
//                            } else {
//                                ScrollView(.horizontal, showsIndicators: false) {
//                                    HStack(spacing: 12) {
//                                        ForEach(suggestedFoods.prefix(5)) { food in
//                                            SuggestedFoodCard(food: food)
//                                        }
//                                    }
//                                    .padding(.horizontal)
//                                }
//                            }
//                        }
//
//                        // Featured Food Section
//                        VStack(alignment: .leading, spacing: 12) {
//                            HStack {
//                                Text("Featured Food")
//                                    .font(.title2)
//                                    .fontWeight(.bold)
//
//                                Spacer()
//
//                                Menu {
//                                    ForEach(NutrientFilter.allCases, id: \.self) { filter in
//                                        Button(action: {
//                                            selectedFilter = filter
//                                            fetchFeaturedFoods()
//                                        }) {
//                                            HStack {
//                                                Text(filter.rawValue)
//                                                if selectedFilter == filter {
//                                                    Image(systemName: "checkmark")
//                                                }
//                                            }
//                                        }
//                                    }
//                                } label: {
//                                    HStack(spacing: 4) {
//                                        Text(selectedFilter.rawValue)
//                                            .font(.subheadline)
//                                            .foregroundColor(.orange)
//                                        Image(systemName: "chevron.down")
//                                            .font(.caption)
//                                            .foregroundColor(.orange)
//                                    }
//                                    .padding(.horizontal, 12)
//                                    .padding(.vertical, 6)
//                                    .background(Color.orange.opacity(0.1))
//                                    .cornerRadius(8)
//                                }
//                            }
//                            .padding(.horizontal)
//
//                            if isLoadingFeatured {
//                                ProgressView()
//                                    .frame(maxWidth: .infinity)
//                                    .padding()
//                            } else {
//                                LazyVStack(spacing: 12) {
//                                    ForEach(featuredFoods) { food in
//                                        FoodRowView(
//                                            food: food,
//                                            isFavorite: favorites.contains(food.foodCode),
//                                            onFavorite: { toggleFavorite(food) }
//                                        )
//                                    }
//                                }
//                                .padding(.horizontal)
//                            }
//                        }
//                    }
//
//                    Spacer()
//                        .frame(height: 20)
//                }
//            }
//        }
//        .background(Color(.systemGroupedBackground))
//        .task {
//            checkEatingTime()
//            fetchSuggestedFoods()
//            fetchFeaturedFoods()
//        }
//        .onChange(of: searchText) { _, newValue in
//            if newValue.isEmpty {
//                searchResults = []
//            }
//        }
//    }
//
//    // MARK: - Check Eating Time
//    private func checkEatingTime() {
//        let calendar = Calendar.current
//        let now = Date()
//        let hour = calendar.component(.hour, from: now)
//        let minute = calendar.component(.minute, from: now)
//        let currentTime = hour * 60 + minute // Minutes since midnight
//
//        // Define meal time windows (in minutes since midnight)
//        let breakfastStart = 7 * 60  // 7:00 AM
//        let breakfastEnd = 10 * 60   // 10:00 AM
//        let lunchStart = 12 * 60     // 12:00 PM
//        let lunchEnd = 15 * 60       // 3:00 PM
//        let snackStart = 16 * 60     // 4:00 PM
//        let snackEnd = 18 * 60       // 6:00 PM
//        let dinnerStart = 19 * 60    // 7:00 PM
//        let dinnerEnd = 22 * 60      // 10:00 PM
//
//        // Check if current time is in eating window
//        let isEatingTime = (currentTime >= breakfastStart && currentTime <= breakfastEnd) ||
//                          (currentTime >= lunchStart && currentTime <= lunchEnd) ||
//                          (currentTime >= snackStart && currentTime <= snackEnd) ||
//                          (currentTime >= dinnerStart && currentTime <= dinnerEnd)
//
//        isNonEatingTime = !isEatingTime
//
//        // Determine next meal
//        if isNonEatingTime {
//            if currentTime < breakfastStart {
//                nextMealInfo = ("Breakfast", formatTime(breakfastStart))
//            } else if currentTime < lunchStart {
//                nextMealInfo = ("Lunch", formatTime(lunchStart))
//            } else if currentTime < snackStart {
//                nextMealInfo = ("Evening Snack", formatTime(snackStart))
//            } else if currentTime < dinnerStart {
//                nextMealInfo = ("Dinner", formatTime(dinnerStart))
//            } else {
//                nextMealInfo = ("Breakfast", formatTime(breakfastStart))
//            }
//        }
//    }
//
//    private func formatTime(_ minutes: Int) -> String {
//        let hour = minutes / 60
//        let minute = minutes % 60
//        let period = hour >= 12 ? "PM" : "AM"
//        let displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)
//        return String(format: "%d:%02d %@", displayHour, minute, period)
//    }
//
//    // MARK: - API Calls
//    private func performSearch() {
//        guard !searchText.isEmpty else { return }
//        isSearching = true
//
//        SearchService.shared.searchFoods(query: searchText) { result in
//            DispatchQueue.main.async {
//                isSearching = false
//                switch result {
//                case .success(let foods):
//                    searchResults = foods
//                case .failure(let error):
//                    print("Search error: \(error.localizedDescription)")
//                    searchResults = []
//                }
//            }
//        }
//    }
//
//    private func fetchSuggestedFoods() {
//        isLoadingSuggestions = true
//
//        SearchService.shared.suggestFoods { result in
//            DispatchQueue.main.async {
//                isLoadingSuggestions = false
//                switch result {
//                case .success(let response):
//                    suggestedFoods = response.suggestions
//                    suggestedMealType = response.mealType
//                case .failure(let error):
//                    print("❌ Suggest error: \(error.localizedDescription)")
//                    suggestedFoods = []
//                }
//            }
//        }
//    }
//
//    private func fetchFeaturedFoods() {
//        isLoadingFeatured = true
//
//        let fetchFunction: (@escaping (Result<[FoodItem], Error>) -> Void) -> Void
//
//        switch selectedFilter {
//        case .protein:
//            fetchFunction = SearchService.shared.fetchTopProtein
//        case .carbs:
//            fetchFunction = SearchService.shared.fetchTopCarbs
//        case .fats:
//            fetchFunction = SearchService.shared.fetchTopFats
//        case .fibre:
//            fetchFunction = SearchService.shared.fetchTopFibre
//        }
//
//        fetchFunction { result in
//            DispatchQueue.main.async {
//                isLoadingFeatured = false
//                switch result {
//                case .success(let foods):
//                    featuredFoods = foods
//                case .failure(let error):
//                    print("Featured error: \(error.localizedDescription)")
//                }
//            }
//        }
//    }
//
//    private func toggleFavorite(_ food: FoodItem) {
//        if favorites.contains(food.foodCode) {
//            favorites.remove(food.foodCode)
//        } else {
//            favorites.insert(food.foodCode)
//        }
//    }
//}
//
//// MARK: - Non-Eating Time View
//struct NonEatingTimeView: View {
//    let nextMeal: String
//    let nextMealTime: String
//
//    var body: some View {
//        VStack(spacing: 24) {
//            // Clock Icon with Animation
//            ZStack {
//                Circle()
//                    .fill(
//                        LinearGradient(
//                            colors: [Color.orange.opacity(0.2), Color.purple.opacity(0.1)],
//                            startPoint: .topLeading,
//                            endPoint: .bottomTrailing
//                        )
//                    )
//                    .frame(width: 140, height: 140)
//
//                Image(systemName: "clock.fill")
//                    .font(.system(size: 60))
//                    .foregroundStyle(
//                        LinearGradient(
//                            colors: [.orange, .purple],
//                            startPoint: .topLeading,
//                            endPoint: .bottomTrailing
//                        )
//                    )
//            }
//            .padding(.top, 20)
//
//            VStack(spacing: 12) {
//                Text("Not Eating Time")
//                    .font(.title)
//                    .fontWeight(.bold)
//                    .foregroundColor(.primary)
//
//                Text("Take a break and hydrate yourself")
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
//                    .multilineTextAlignment(.center)
//            }
//
//            // Next Meal Card
//            VStack(spacing: 16) {
//                HStack {
//                    VStack(alignment: .leading, spacing: 4) {
//                        Text("Next Meal")
//                            .font(.caption)
//                            .foregroundColor(.secondary)
//
//                        Text(nextMeal)
//                            .font(.title3)
//                            .fontWeight(.semibold)
//                    }
//
//                    Spacer()
//
//                    VStack(alignment: .trailing, spacing: 4) {
//                        Image(systemName: "bell.fill")
//                            .font(.caption)
//                            .foregroundColor(.orange)
//
//                        Text(nextMealTime)
//                            .font(.headline)
//                            .foregroundColor(.orange)
//                    }
//                }
//                .padding(20)
//                .background(
//                    RoundedRectangle(cornerRadius: 16)
//                        .fill(Color(.systemBackground))
//                        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
//                )
//
//                // Hydration Reminder
//                HStack(spacing: 12) {
//                    Image(systemName: "drop.fill")
//                        .font(.title2)
//                        .foregroundColor(.blue)
//
//                    VStack(alignment: .leading, spacing: 2) {
//                        Text("Stay Hydrated")
//                            .font(.subheadline)
//                            .fontWeight(.semibold)
//
//                        Text("Drink water while you wait")
//                            .font(.caption)
//                            .foregroundColor(.secondary)
//                    }
//
//                    Spacer()
//
//                    Image(systemName: "chevron.right")
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                }
//                .padding(16)
//                .background(
//                    RoundedRectangle(cornerRadius: 12)
//                        .fill(Color.blue.opacity(0.1))
//                )
//            }
//            .padding(.horizontal, 4)
//
//            Spacer()
//        }
//        .frame(maxWidth: .infinity)
//        .padding()
//    }
//}
//
//// MARK: - Suggested Food Card
//struct SuggestedFoodCard: View {
//    let food: FoodItem
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            AsyncImage(url: food.imageURL) { phase in
//                switch phase {
//                case .empty:
//                    RoundedRectangle(cornerRadius: 12)
//                        .fill(Color(.systemGray5))
//                        .frame(width: 140, height: 100)
//                        .overlay(ProgressView())
//                case .success(let image):
//                    image
//                        .resizable()
//                        .scaledToFill()
//                        .frame(width: 140, height: 100)
//                        .clipped()
//                case .failure:
//                    RoundedRectangle(cornerRadius: 12)
//                        .fill(Color(.systemGray5))
//                        .frame(width: 140, height: 100)
//                        .overlay(
//                            Image(systemName: "photo")
//                                .foregroundColor(.gray)
//                        )
//                @unknown default:
//                    EmptyView()
//                }
//            }
//            .frame(width: 140, height: 100)
//            .clipShape(RoundedRectangle(cornerRadius: 12))
//
//            Text(food.foodName)
//                .font(.subheadline)
//                .fontWeight(.medium)
//                .lineLimit(2)
//                .frame(width: 140, alignment: .leading)
//
//            Text("\(Int(food.calories)) cal")
//                .font(.caption)
//                .foregroundColor(.secondary)
//        }
//        .frame(width: 140)
//    }
//}
//
//// MARK: - Food Row View
//struct FoodRowView: View {
//    let food: FoodItem
//    let isFavorite: Bool
//    let onFavorite: () -> Void
//
//    var body: some View {
//        HStack(spacing: 12) {
//            // Food Image
//            ZStack(alignment: .topLeading) {
//                AsyncImage(url: food.imageURL) { phase in
//                    switch phase {
//                    case .empty:
//                        RoundedRectangle(cornerRadius: 12)
//                            .fill(Color(.systemGray5))
//                            .overlay(ProgressView())
//                    case .success(let image):
//                        image
//                            .resizable()
//                            .scaledToFill()
//                    case .failure:
//                        RoundedRectangle(cornerRadius: 12)
//                            .fill(Color(.systemGray5))
//                            .overlay(
//                                Image(systemName: "photo")
//                                    .foregroundColor(.gray)
//                            )
//                    @unknown default:
//                        EmptyView()
//                    }
//                }
//                .frame(width: 80, height: 80)
//                .clipShape(RoundedRectangle(cornerRadius: 12))
//
//                // Favorite Button
//                Button(action: onFavorite) {
//                    Image(systemName: isFavorite ? "heart.fill" : "heart")
//                        .font(.system(size: 16))
//                        .foregroundColor(isFavorite ? .red : .white)
//                        .padding(4)
//                        .background(Circle().fill(Color.black.opacity(0.3)))
//                }
//                .offset(x: 4, y: 4)
//            }
//
//            // Food Details
//            VStack(alignment: .leading, spacing: 4) {
//                HStack {
//                    Text(food.foodName)
//                        .font(.subheadline)
//                        .fontWeight(.medium)
//                        .lineLimit(2)
//
//                    Spacer()
//
//                    Text("(100g)")
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                }
//
//                Text("Protein: \(Int(food.protein))-\(Int(food.protein) + 2)g")
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//
//                Text("Calories: \(Int(food.calories)) kcal")
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//            }
//
//            // Arrow
//            Image(systemName: "chevron.right")
//                .foregroundColor(.gray)
//                .font(.caption)
//        }
//        .padding(12)
//        .background(
//            RoundedRectangle(cornerRadius: 16)
//                .fill(Color(.systemBackground))
//        )
//        .overlay(
//            RoundedRectangle(cornerRadius: 16)
//                .stroke(Color(.systemGray4), lineWidth: 1)
//        )
//    }
//}
//
//#Preview {
//    SearchView()
//}
