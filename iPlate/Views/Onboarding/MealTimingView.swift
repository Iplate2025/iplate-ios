import SwiftUI

struct MealTimingView: View {
    // default times
    @State private var breakfastTime: Date = {
        var comps = DateComponents(); comps.hour = 8; comps.minute = 0
        return Calendar.current.date(from: comps) ?? Date()
    }()
    @State private var lunchTime: Date = {
        var comps = DateComponents(); comps.hour = 12; comps.minute = 30
        return Calendar.current.date(from: comps) ?? Date()
    }()
    @State private var dinnerTime: Date = {
        var comps = DateComponents(); comps.hour = 19; comps.minute = 30
        return Calendar.current.date(from: comps) ?? Date()
    }()

    @StateObject private var vm = OnboardingViewModel()
    @State private var isSaving = false
    @State private var infoMessage = ""
    @State private var goToHome = false

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Text("6 of 6")
                    .foregroundColor(.gray)
                    .font(.subheadline)
                Spacer()
                Button(action: skipOnboarding) {
                    Text("Skip")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            // Progress bar
            HStack(spacing: 8) {
                ForEach(0..<6) { _ in
                    Capsule()
                        .fill(Color.orange)
                        .frame(height: 8)
                }
            }
            .padding(.horizontal, 20)

            Text("Tell us your Meal Timings!")
                .font(.title2.bold())
                .foregroundColor(.black)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 14) {
                timeRow(title: "Breakfast", date: $breakfastTime)
                timeRow(title: "Lunch", date: $lunchTime)
                timeRow(title: "Dinner", date: $dinnerTime)
            }
            .padding(.horizontal, 20)

            if !infoMessage.isEmpty {
                Text(infoMessage)
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }

            Spacer()

            Button(action: finalizeOnboarding) {
                if isSaving {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange.opacity(0.8))
                        .cornerRadius(25)
                } else {
                    Text("Continue")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(25)
                }
            }
            .disabled(isSaving)
            .padding(.horizontal, 44)
            .padding(.bottom, 24)
        }
        .background(Color.white.ignoresSafeArea())
        .fullScreenCover(isPresented: $goToHome) {
            HomeView()
        }
    }

    // MARK: - UI helper
    private func timeRow(title: String, date: Binding<Date>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .fontWeight(.medium)

            DatePicker("", selection: date, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .padding()
                .frame(height: 48)
                .background(Color(.systemGray6))
                .cornerRadius(10)
        }
    }

    // MARK: - Actions

    /// ✅ Skip = leave onboarding WITHOUT completing it
    private func skipOnboarding() {
        goToHome = true
    }

    /// ✅ Final step = ONLY place onboarding is completed
    private func finalizeOnboarding() {
        guard
            let userId = ProfileViewModel.shared.userID,
            let userEmail = ProfileViewModel.shared.email
        else {
            infoMessage = "Session expired. Please login again."
            return
        }

        isSaving = true
        infoMessage = "Saving profile..."

        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm:ss"

        let data = OnboardingData.shared

        let details: [String: Any] = [
            "diet": data.diet ?? "",
            "allergens": data.allergies.joined(separator: ","),
            "height_cm": data.heightCm ?? 0,
            "weight_kg": data.weightKg ?? 0,
            "breakfast_start": fmt.string(from: breakfastTime),
            "breakfast_end": fmt.string(from: breakfastTime),
            "lunch_start": fmt.string(from: lunchTime),
            "lunch_end": fmt.string(from: lunchTime),
            "dinner_start": fmt.string(from: dinnerTime),
            "dinner_end": fmt.string(from: dinnerTime)
        ]

        // Username is optional but supported
        if let username = data.username, !username.isEmpty {
            vm.setUsername(userId: userId, username: username) { _ in
                saveDetails(userId: userId, email: userEmail, details: details)
            }
        } else {
            saveDetails(userId: userId, email: userEmail, details: details)
        }
    }

    private func saveDetails(userId: String, email: String, details: [String: Any]) {
        vm.updateUserDetails(userId: userId, userEmail: email, details: details) { result in
            DispatchQueue.main.async {
                isSaving = false

                switch result {
                case .success:
                    // ✅ FINAL STEP → MARK ONBOARDING COMPLETE (BACKEND)
                    completeOnboardingAndProceed()

                case .failure(let error):
                    infoMessage = error.localizedDescription
                }
            }
        }
    }
    /// ✅ Marks onboarding complete in backend
    private func completeOnboardingAndProceed() {
        guard let token = ProfileViewModel.shared.sessionToken else {
            infoMessage = "Session expired. Please login again."
            return
        }

        AuthService.shared.completeOnboarding(sessionToken: token) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(true):
                    goToHome = true

                case .success(false):
                    infoMessage = "Onboarding not completed. Please try again."

                case .failure(let error):
                    infoMessage = error.localizedDescription
                }
            }
        }
    }

}
