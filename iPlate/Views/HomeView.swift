import SwiftUI
import PhotosUI
import AVFoundation
import CoreBluetooth
import Combine

struct HomeView: View {
    @ObservedObject private var profileViewModel = ProfileViewModel.shared
    @StateObject private var bluetoothManager = BluetoothManager()
    
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
    @State private var showCameraPermissionAlert = false
    @State private var cameraPermissionStatus: AVAuthorizationStatus = .notDetermined
    @State private var weightsInput: String = ""
    
    // Bluetooth states
    @State private var showBluetoothPermissionAlert = false

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
        // Use username or email from ProfileViewModel
        if let username = profileViewModel.username, !username.isEmpty {
            return username.capitalized
        }
        return profileViewModel.email?.components(separatedBy: "@").first?.capitalized ?? "User"
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
                onAddTapped: {
                    // Request Bluetooth permission when + is tapped
                    bluetoothManager.requestPermission()
                    showImageSourcePicker = true
                }
            )
        }
        .confirmationDialog("Choose Image Source", isPresented: $showImageSourcePicker, titleVisibility: .visible) {
            Button("Take Photo") {
                checkCameraPermissionAndOpen()
            }
            Button("Choose from Library") {
                showUploadSheet = true
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Camera Access Required", isPresented: $showCameraPermissionAlert) {
            Button("Open Settings") {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable camera access in Settings to take photos of your meals.")
        }
        .fullScreenCover(isPresented: $showCamera) {
            FoodCameraView(capturedImage: $pickedImage, onCapture: {
                showCamera = false
                if pickedImage != nil {
                    showUploadSheet = true
                }
            }, onDismiss: {
                showCamera = false
            })
        }
        .sheet(isPresented: $showUploadSheet) {
            UploadSheetView(
                pickedItem: $pickedItem,
                pickedImage: $pickedImage,
                isUploading: $isUploading,
                uploadMessage: $uploadMessage,
                weightsInput: $weightsInput,
                onUpload: uploadPickedImage,
                onDismiss: {
                    showUploadSheet = false
                    pickedImage = nil
                    pickedItem = nil
                    uploadMessage = nil
                    weightsInput = ""
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

        // Parse weights from user input - comma or space separated
        var weights: [Double] = []
        let weightComponents = weightsInput
            .replacingOccurrences(of: " ", with: ",")
            .split(separator: ",")
            .compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
        
        if weightComponents.isEmpty {
            // Default weight if no input provided
            weights = [100.0]
        } else {
            weights = weightComponents
        }
        
        print("📤 Uploading meal with weights: \(weights)")

        MealService.shared.uploadMeal(image: image, weights: weights) { result in
            DispatchQueue.main.async {
                self.isUploading = false
                switch result {
                case .success(let json):
                    print("📥 Upload response: \(json)")
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
                        self.weightsInput = ""
                        self.fetchMeals(for: self.selectedDate)
                    }
                case .failure(let error):
                    print("❌ Upload failed: \(error)")
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

    // MARK: - Camera Permission
    private func checkCameraPermissionAndOpen() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            showCamera = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        showCamera = true
                    } else {
                        showCameraPermissionAlert = true
                    }
                }
            }
        case .denied, .restricted:
            showCameraPermissionAlert = true
        @unknown default:
            showCameraPermissionAlert = true
        }
    }
}

// MARK: - Food Camera View (Custom UI matching design)
struct FoodCameraView: View {
    @Binding var capturedImage: UIImage?
    var onCapture: () -> Void
    var onDismiss: () -> Void
    
    @State private var flashEnabled = false
    @State private var showCameraPreview = true
    
    var body: some View {
        ZStack {
            // Camera Preview
            CameraPreviewView(capturedImage: $capturedImage, flashEnabled: $flashEnabled)
                .ignoresSafeArea()
            
            // Overlay UI
            VStack {
                // Top bar with back and flash buttons
                HStack {
                    Button(action: onDismiss) {
                        Image(systemName: "arrow.left")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                    }
                    
                    Spacer()
                    
                    Button(action: { flashEnabled.toggle() }) {
                        Image(systemName: flashEnabled ? "bolt.fill" : "bolt.slash.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                Spacer()
                
                // Center circle guide
                ZStack {
                    Circle()
                        .strokeBorder(
                            style: StrokeStyle(lineWidth: 3, dash: [10, 5])
                        )
                        .foregroundColor(.orange)
                        .frame(width: 280, height: 280)
                }
                
                Spacer()
                
                // Bottom section with instruction and capture button
                VStack(spacing: 24) {
                    Text("Place food in the circle!")
                        .font(.headline)
                        .foregroundColor(.orange)
                    
                    // Capture button
                    Button(action: {
                        // Capture happens via CameraPreviewView
                        NotificationCenter.default.post(name: .capturePhoto, object: nil)
                    }) {
                        ZStack {
                            Circle()
                                .stroke(Color.white, lineWidth: 4)
                                .frame(width: 80, height: 80)
                            
                            Circle()
                                .fill(Color.orange.opacity(0.8))
                                .frame(width: 64, height: 64)
                        }
                    }
                }
                .padding(.bottom, 50)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .photoCaptured)) { _ in
            if capturedImage != nil {
                onCapture()
            }
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let capturePhoto = Notification.Name("capturePhoto")
    static let photoCaptured = Notification.Name("photoCaptured")
}

// MARK: - Camera Preview View (AVFoundation based)
struct CameraPreviewView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    @Binding var flashEnabled: Bool
    
    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        uiViewController.flashEnabled = flashEnabled
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, CameraViewControllerDelegate {
        let parent: CameraPreviewView
        
        init(_ parent: CameraPreviewView) {
            self.parent = parent
        }
        
        func didCapturePhoto(_ image: UIImage) {
            DispatchQueue.main.async {
                self.parent.capturedImage = image
                NotificationCenter.default.post(name: .photoCaptured, object: nil)
            }
        }
    }
}

// MARK: - Camera View Controller Delegate
protocol CameraViewControllerDelegate: AnyObject {
    func didCapturePhoto(_ image: UIImage)
}

// MARK: - Camera View Controller
class CameraViewController: UIViewController {
    weak var delegate: CameraViewControllerDelegate?
    var flashEnabled = false
    
    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var captureObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        
        // Listen for capture notification
        captureObserver = NotificationCenter.default.addObserver(
            forName: .capturePhoto,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.capturePhoto()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
    
    deinit {
        if let observer = captureObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        captureSession?.stopRunning()
    }
    
    private func setupCamera() {
        let session = AVCaptureSession()
        session.sessionPreset = .photo
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            print("Failed to access camera")
            return
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        let output = AVCapturePhotoOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        
        photoOutput = output
        captureSession = session
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        self.previewLayer = previewLayer
        
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }
    
    func capturePhoto() {
        guard let photoOutput = photoOutput else { return }
        
        let settings = AVCapturePhotoSettings()
        
        if let device = AVCaptureDevice.default(for: .video),
           device.hasFlash {
            settings.flashMode = flashEnabled ? .on : .off
        }
        
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil,
              let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("Error capturing photo: \(error?.localizedDescription ?? "unknown")")
            return
        }
        
        delegate?.didCapturePhoto(image)
    }
}

// MARK: - Legacy Camera View (kept for compatibility)
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
// MARK: - Meal Card View
struct MealCardView: View {
    let meal: [String: Any]
    let index: Int
    @State private var showDetail = false

    private var mealId: String {
        // Try multiple possible keys for meal ID
        if let id = meal["_id"] as? String, !id.isEmpty {
            return id
        }
        if let id = meal["id"] as? String, !id.isEmpty {
            return id
        }
        if let id = meal["meal_id"] as? String, !id.isEmpty {
            return id
        }
        return ""
    }

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
        Button {
            // Debug: Print all meal keys to find the correct ID field
            print("🔵 Meal dictionary keys: \(meal.keys)")
            print("🔵 Full meal data: \(meal)")
            print("🔵 Extracted mealId: \(mealId)")
            
            if !mealId.isEmpty {
                showDetail = true
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(mealTitle)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text("\(calories) cal • \(totalWeight)g")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("• \(mealType)")
                    .font(.subheadline)
                    .foregroundColor(mealTypeColor)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .fullScreenCover(isPresented: $showDetail) {
            MealDetailView(mealId: mealId)
        }
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
    @Binding var weightsInput: String
    let onUpload: () -> Void
    let onDismiss: () -> Void

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
                    TextField("e.g., 150, 200, 100, 120", text: $weightsInput)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numbersAndPunctuation)
                    Text("Enter up to 4 weights separated by commas (one per food item)")
                        .font(.caption)
                        .foregroundColor(.gray)
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

// MARK: - Bluetooth Manager
class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate {
    private var centralManager: CBCentralManager?
    @Published var isBluetoothAuthorized = false
    @Published var bluetoothState: CBManagerState = .unknown
    
    override init() {
        super.init()
    }
    
    func requestPermission() {
        // Initialize CBCentralManager to trigger the permission popup
        if centralManager == nil {
            centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: true])
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        bluetoothState = central.state
        
        switch central.state {
        case .poweredOn:
            print("✅ Bluetooth is powered on and ready")
            isBluetoothAuthorized = true
        case .poweredOff:
            print("⚠️ Bluetooth is powered off")
            isBluetoothAuthorized = false
        case .unauthorized:
            print("❌ Bluetooth access is unauthorized")
            isBluetoothAuthorized = false
        case .unsupported:
            print("❌ Bluetooth is not supported on this device")
            isBluetoothAuthorized = false
        case .resetting:
            print("⚠️ Bluetooth is resetting")
        case .unknown:
            print("⚠️ Bluetooth state is unknown")
        @unknown default:
            print("⚠️ Unknown Bluetooth state")
        }
    }
}

#Preview {
    HomeView()
}
