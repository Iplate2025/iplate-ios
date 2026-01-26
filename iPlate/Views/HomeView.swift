import SwiftUI
import PhotosUI

struct HomeView: View {
    @State private var isLoggingOut = false
    @State private var logoutError: String?
    @State private var goToLogin = false
    @State private var showMoodTracker = false
    
    @State private var showPicker = false
    @State private var pickedItem: PhotosPickerItem? = nil
    @State private var pickedImage: UIImage? = nil
    @State private var isUploading = false
    @State private var uploadMessage: String? = nil
    @State private var meals: [[String: Any]] = []
    @State private var isLoadingMeals = false
    @State private var mealsError: String? = nil

    @State private var selectedTab = 0
    @State private var showUploadSheet = false
    @State private var selectedDate = Date()
    @State private var showDatePicker = false
    
    // Camera states
    @State private var showCamera = false
    @State private var showImageSourcePicker = false

    // Nutrition totals for the selected date
    @State private var totalCalories: Double = 0
    @State private var totalProtein: Double = 0
    @State private var totalCarbs: Double = 0
    @State private var totalFat: Double = 0
    @State private var totalFiber: Double = 0

    // Goals (can be fetched from user profile or set as defaults)
    private let goalCalories: Double = 2400
    private let goalProtein: Double = 150
    private let goalCarbs: Double = 300
    private let goalFat: Double = 80
    private let goalFiber: Double = 40

    private var userName: String {
        ProfileViewModel.shared.email?.components(separatedBy: "@").first?.capitalized ?? "User"
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good Morning," }
        else if hour < 17 { return "Good Afternoon," }
        else { return "Good Evening," }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            // Switch content based on selected tab
            Group {
                switch selectedTab {
                case 0:
                    homeContent
                case 1:
                    AnalyticsView()
                case 2:
                    SearchView()
                case 3:
                    ProfileView()
                default:
                    homeContent
                }
            }

            // Custom Tab Bar with centered FAB
            CustomTabBar(
                selectedTab: $selectedTab,
                onAddTapped: { showImageSourcePicker = true }
            )
        }
        .confirmationDialog("Choose Image Source", isPresented: $showImageSourcePicker, titleVisibility: .visible) {
            Button("Take Photo") {
                showCamera = true
            }
            Button("Choose from Library") {
                showUploadSheet = true
            }
            Button("Cancel", role: .cancel) {}
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView(capturedImage: $pickedImage, onCapture: {
                showCamera = false
                showUploadSheet = true
            })
        }
        .sheet(isPresented: $showUploadSheet) {
            UploadSheetView(
                pickedItem: $pickedItem,
                pickedImage: $pickedImage,
                isUploading: $isUploading,
                uploadMessage: $uploadMessage,
                onUpload: uploadPickedImage,
                onDismiss: {
                    showUploadSheet = false
                    pickedImage = nil
                    pickedItem = nil
                    uploadMessage = nil
                    fetchMeals(for: selectedDate)
                }
            )
        }
        .sheet(isPresented: $showDatePicker) {
            DatePickerSheet(selectedDate: $selectedDate, onDone: {
                showDatePicker = false
                fetchMeals(for: selectedDate)
            })
        }
        .task {
            fetchMeals(for: Date())
        }
        .fullScreenCover(isPresented: $goToLogin) {
            LoginView()
        }
        .fullScreenCover(isPresented: $showMoodTracker) {
            MoodTrackerView()
        }
    }

    // MARK: - Home Content
    private var homeContent: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                // App Logo
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 50, height: 50)
                        .shadow(color: .black.opacity(0.1), radius: 2, y: 1)

                    VStack(spacing: -2) {
                        Image("splashLogo")
                            .resizable()
                            .frame(width: 20, height: 20)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(greeting)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(userName) !")
                        .font(.title2)
                        .fontWeight(.bold)
                }

                Spacer()

                // Health meter icon - now clickable
                Button(action: { showMoodTracker = true }) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 44, height: 44)
                            .shadow(color: .black.opacity(0.1), radius: 2, y: 1)

                        Image(systemName: "gauge.medium")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Today's Goals Header
                    HStack {
                        Text("Today's Goals")
                            .font(.title2)
                            .fontWeight(.bold)
                        Spacer()
                        Button(action: { showDatePicker = true }) {
                            Image(systemName: "calendar")
                                .font(.title2)
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Goals Card
                    GoalsCardView(
                        totalCalories: totalCalories,
                        goalCalories: goalCalories,
                        proteinPercent: min(totalProtein / goalProtein, 1.0),
                        carbsPercent: min(totalCarbs / goalCarbs, 1.0),
                        fatsPercent: min(totalFat / goalFat, 1.0),
                        fiberPercent: min(totalFiber / goalFiber, 1.0)
                    )
                    .padding(.horizontal)

                    // Page indicator dots
                    HStack(spacing: 8) {
                        Capsule()
                            .fill(Color.orange)
                            .frame(width: 32, height: 6)
                        Capsule()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 6, height: 6)
                        Capsule()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 6, height: 6)
                    }

                    // Previous Meals Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Previous Meals")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)

                        if isLoadingMeals {
                            VStack(spacing: 12) {
                                ProgressView()
                                Text("Loading meals...")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else if let error = mealsError {
                            VStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.largeTitle)
                                    .foregroundColor(.orange)
                                Text(error)
                                    .foregroundColor(.secondary)
                                    .font(.footnote)
                                    .multilineTextAlignment(.center)
                                Button("Retry") {
                                    fetchMeals(for: selectedDate)
                                }
                                .font(.footnote)
                                .foregroundColor(.orange)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else if meals.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "fork.knife.circle")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray.opacity(0.5))
                                Text("No meals recorded")
                                    .foregroundColor(.secondary)
                                Text("Tap + to add your first meal")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(Array(meals.enumerated()), id: \.offset) { index, meal in
                                    MealCardView(meal: meal, index: index)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    Spacer()
                        .frame(height: 100)
                }
            }
        }
    }

    // MARK: - Upload
    private func uploadPickedImage() {
        guard let image = pickedImage else { return }
        isUploading = true
        uploadMessage = nil

        let weights: [Double] = [100]

        MealService.shared.uploadMeal(image: image, weights: weights) { result in
            DispatchQueue.main.async {
                self.isUploading = false
                switch result {
                case .success(let json):
                    if let message = json["message"] as? String {
                        self.uploadMessage = message
                    } else {
                        self.uploadMessage = "Upload successful!"
                    }
                    // Refresh meals after successful upload
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.showUploadSheet = false
                        self.pickedImage = nil
                        self.pickedItem = nil
                        self.fetchMeals(for: self.selectedDate)
                    }
                case .failure(let error):
                    self.uploadMessage = "Upload failed: \(error.localizedDescription)"
                }
            }
        }
    }

    // MARK: - Fetch meals
    private func fetchMeals(for date: Date) {
        isLoadingMeals = true
        mealsError = nil

        MealService.shared.fetchMeals(for: date) { result in
            DispatchQueue.main.async {
                self.isLoadingMeals = false
                switch result {
                case .success(let response):
                    // Extract meals array from response: { "date": "...", "meals": [...] }
                    if let mealsArray = response["meals"] as? [[String: Any]] {
                        self.meals = mealsArray
                        self.calculateTotals(from: mealsArray)
                    } else {
                        self.meals = []
                        self.resetTotals()
                    }
                case .failure(let error):
                    self.mealsError = error.localizedDescription
                    self.meals = []
                    self.resetTotals()
                }
            }
        }
    }

    private func calculateTotals(from meals: [[String: Any]]) {
        var calories: Double = 0
        var protein: Double = 0
        var carbs: Double = 0
        var fat: Double = 0
        var fiber: Double = 0

        for meal in meals {
            if let summary = meal["summary"] as? [String: Any] {
                calories += (summary["calories"] as? Double) ?? 0
                protein += (summary["protein"] as? Double) ?? 0
                carbs += (summary["carbs"] as? Double) ?? 0
                fat += (summary["fat"] as? Double) ?? 0
                fiber += (summary["fiber"] as? Double) ?? 0
            }
        }

        totalCalories = calories
        totalProtein = protein
        totalCarbs = carbs
        totalFat = fat
        totalFiber = fiber
    }

    private func resetTotals() {
        totalCalories = 0
        totalProtein = 0
        totalCarbs = 0
        totalFat = 0
        totalFiber = 0
    }
}

// MARK: - Camera View
struct CameraView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    var onCapture: () -> Void
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.capturedImage = image
            }
            parent.dismiss()
            parent.onCapture()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Goals Card View
struct GoalsCardView: View {
    let totalCalories: Double
    let goalCalories: Double
    let proteinPercent: Double
    let carbsPercent: Double
    let fatsPercent: Double
    let fiberPercent: Double

    private var caloriesProgress: Double {
        min(totalCalories / goalCalories, 1.0)
    }

    var body: some View {
        HStack(spacing: 20) {
            // Circular Progress
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 12)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: caloriesProgress)
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: caloriesProgress)

                VStack(spacing: 0) {
                    Text("\(Int(totalCalories))")
                        .font(.system(size: 28, weight: .bold))
                    Text("Cal")
                        .font(.subheadline)
                }
                .foregroundColor(.white)
            }

            // Nutrient Bars
            VStack(spacing: 14) {
                NutrientBar(name: "Protein:", percentage: proteinPercent)
                NutrientBar(name: "Carbs:", percentage: carbsPercent)
                NutrientBar(name: "Fats:", percentage: fatsPercent)
                NutrientBar(name: "Fiber:", percentage: fiberPercent)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color.orange, Color.orange.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .foregroundColor(.white)
    }
}

// MARK: - Nutrient Bar
struct NutrientBar: View {
    let name: String
    let percentage: Double

    var body: some View {
        HStack(spacing: 8) {
            Text(name)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 60, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 8)

                    Capsule()
                        .fill(Color.white)
                        .frame(width: geo.size.width * percentage, height: 8)
                        .animation(.easeInOut(duration: 0.5), value: percentage)
                }
            }
            .frame(height: 8)

            Text("\(Int(percentage * 100))%")
                .font(.caption)
                .fontWeight(.medium)
                .frame(width: 40, alignment: .trailing)
        }
    }
}

// MARK: - Meal Card View
struct MealCardView: View {
    let meal: [String: Any]
    let index: Int

    private var mealTitle: String {
        if let title = meal["meal_title"] as? String, !title.isEmpty {
            return title.capitalized
        }
        return "Meal #\(index + 1)"
    }

    private var calories: Int {
        if let summary = meal["summary"] as? [String: Any],
           let cal = summary["calories"] as? Double {
            return Int(cal)
        }
        return 0
    }

    private var totalWeight: Int {
        if let qty = meal["quantity_total"] as? Double {
            return Int(qty)
        }
        return 0
    }

    private var mealType: String {
        if let type = meal["meal_type"] as? String, type != "exception" {
            return type.capitalized
        }
        // Assign based on time or index
        let types = ["Breakfast", "Lunch", "Snack", "Dinner"]
        return types[index % types.count]
    }

    private var mealTypeColor: Color {
        switch mealType.lowercased() {
        case "breakfast": return .green
        case "lunch": return .blue
        case "dinner": return .purple
        case "snack": return .orange
        default: return .green
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(mealTitle)
                        .font(.headline)
                        .fontWeight(.semibold)

                    if totalWeight > 0 {
                        Text("(\(totalWeight)g)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Text("\(calories) Cal")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("• \(mealType)")
                .font(.subheadline)
                .foregroundColor(mealTypeColor)
                .fontWeight(.semibold)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.5), lineWidth: 1.5)
        )
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: Int
    let onAddTapped: () -> Void

    var body: some View {
        ZStack {
            // Background
            HStack(spacing: 0) {
                TabBarButton(icon: "house.fill", title: "Home", isSelected: selectedTab == 0) {
                    selectedTab = 0
                }
                TabBarButton(icon: "chart.line.uptrend.xyaxis", title: "Analytics", isSelected: selectedTab == 1) {
                    selectedTab = 1
                }

                // Space for FAB
                Color.clear
                    .frame(width: 80)

                TabBarButton(icon: "magnifyingglass", title: "Search", isSelected: selectedTab == 2) {
                    selectedTab = 2
                }
                TabBarButton(icon: "person.fill", title: "Profile", isSelected: selectedTab == 3) {
                    selectedTab = 3
                }
            }
            .frame(height: 60)
            .background(Color(.systemBackground))
            .shadow(color: .black.opacity(0.08), radius: 8, y: -4)

            // Floating Action Button
            Button(action: onAddTapped) {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 64, height: 64)
                    .overlay(
                        Image(systemName: "plus")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.white)
                    )
                    .shadow(color: .orange.opacity(0.4), radius: 8, y: 4)
            }
            .offset(y: -20)
        }
    }
}

// MARK: - Tab Bar Button
struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(title)
                    .font(.caption2)
            }
            .foregroundColor(isSelected ? .orange : .gray)
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Upload Sheet
struct UploadSheetView: View {
    @Binding var pickedItem: PhotosPickerItem?
    @Binding var pickedImage: UIImage?
    @Binding var isUploading: Bool
    @Binding var uploadMessage: String?
    let onUpload: () -> Void
    let onDismiss: () -> Void

    @State private var weightText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Image Preview
                if let image = pickedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 280)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray5))
                        .frame(height: 200)
                        .overlay(
                            VStack(spacing: 12) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray)
                                Text("Select a meal photo")
                                    .foregroundColor(.secondary)
                            }
                        )
                }

                // Photo Picker
                PhotosPicker(selection: $pickedItem, matching: .images, photoLibrary: .shared()) {
                    HStack {
                        Image(systemName: pickedImage == nil ? "photo.badge.plus" : "arrow.triangle.2.circlepath")
                        Text(pickedImage == nil ? "Pick from Library" : "Change Image")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .onChange(of: pickedItem) { _, newItem in
                    guard let item = newItem else { return }
                    Task {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let img = UIImage(data: data) {
                            await MainActor.run {
                                self.pickedImage = img
                                self.uploadMessage = nil
                            }
                        }
                    }
                }

                // Weight Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Food weights (grams)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextField("e.g., 150, 200, 100", text: $weightText)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numbersAndPunctuation)
                }

                // Upload Button
                Button(action: onUpload) {
                    HStack(spacing: 8) {
                        if isUploading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        Text(isUploading ? "Uploading..." : "Upload Meal")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(pickedImage == nil ? Color.gray : Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(pickedImage == nil || isUploading)

                // Status Message
                if let message = uploadMessage {
                    HStack {
                        Image(systemName: message.contains("failed") ? "xmark.circle.fill" : "checkmark.circle.fill")
                            .foregroundColor(message.contains("failed") ? .red : .green)
                        Text(message)
                            .font(.footnote)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Upload Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                }
            }
        }
    }
}

// MARK: - Date Picker Sheet
struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    let onDone: () -> Void

    var body: some View {
        NavigationStack {
            VStack {
                DatePicker("Select Date", selection: $selectedDate, in: ...Date(), displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .tint(.orange)
                    .padding()
                Spacer()
            }
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { onDone() }
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
            }
        }
    }
}

#Preview {
    HomeView()
}
