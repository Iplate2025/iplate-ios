import SwiftUI

struct MealTimingView: View {

    // Breakfast default: 08:00 AM
    @State private var breakfastHour = 8
    @State private var breakfastMinute = 0
    @State private var breakfastAmPm = "AM"

    // Lunch default: 12:30 PM
    @State private var lunchHour = 12
    @State private var lunchMinute = 30
    @State private var lunchAmPm = "PM"

    // Dinner default: 07:30 PM
    @State private var dinnerHour = 7
    @State private var dinnerMinute = 30
    @State private var dinnerAmPm = "PM"

    @StateObject private var vm = OnboardingViewModel()
    @State private var isSaving = false
    @State private var infoMessage = ""
    @State private var goToHome = false

    private let hours = Array(1...12)
    private let minutes = [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55]
    private let amPmOptions = ["AM", "PM"]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Top bar
            HStack {
                Text("7 of 7")
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
            .padding(.top, 12)

            // Progress bar - all orange (last step)
            HStack(spacing: 6) {
                ForEach(0..<7) { _ in
                    Capsule()
                        .fill(Color.orange)
                        .frame(height: 8)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            // Title
            Text("Tell us your Meal Timings!")
                .font(.title2.bold())
                .foregroundColor(.black)
                .padding(.horizontal, 20)
                .padding(.top, 20)

            VStack(spacing: 20) {
                // Breakfast
                timePickerRow(
                    title: "Breakfast",
                    hour: $breakfastHour,
                    minute: $breakfastMinute,
                    amPm: $breakfastAmPm
                )

                // Lunch
                timePickerRow(
                    title: "Lunch",
                    hour: $lunchHour,
                    minute: $lunchMinute,
                    amPm: $lunchAmPm
                )

                // Dinner
                timePickerRow(
                    title: "Dinner",
                    hour: $dinnerHour,
                    minute: $dinnerMinute,
                    amPm: $dinnerAmPm
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            if !infoMessage.isEmpty {
                Text(infoMessage)
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
            }

            Spacer()

            // Continue button - bottom right like other onboarding steps
            HStack {
                Spacer()
                if isSaving {
                    ProgressView()
                        .padding(.trailing, 18)
                        .padding(.bottom, 24)
                } else {
                    Button(action: finalizeOnboarding) {
                        Text("Continue")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 26)
                            .background(Color.orange)
                            .cornerRadius(22)
                    }
                    .padding(.trailing, 18)
                    .padding(.bottom, 24)
                }
            }
        }
        .background(Color.white.ignoresSafeArea())
        .fullScreenCover(isPresented: $goToHome) {
            HomeView()
        }
    }

    // MARK: - Time Picker Row UI
    @ViewBuilder
    private func timePickerRow(
        title: String,
        hour: Binding<Int>,
        minute: Binding<Int>,
        amPm: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .fontWeight(.semibold)
                .foregroundColor(.black)

            HStack(spacing: 8) {
                // Hour picker
                Menu {
                    ForEach(hours, id: \.self) { h in
                        Button(String(format: "%02d", h)) { hour.wrappedValue = h }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(String(format: "%02d", hour.wrappedValue))
                            .foregroundColor(.black)
                            .fontWeight(.medium)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white))
                    )
                }

                // Colon separator
                Text(":")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.black)

                // Minute picker
                Menu {
                    ForEach(minutes, id: \.self) { m in
                        Button(String(format: "%02d", m)) { minute.wrappedValue = m }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(String(format: "%02d", minute.wrappedValue))
                            .foregroundColor(.black)
                            .fontWeight(.medium)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white))
                    )
                }

                // AM/PM picker
                Menu {
                    ForEach(amPmOptions, id: \.self) { option in
                        Button(option) { amPm.wrappedValue = option }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(amPm.wrappedValue)
                            .foregroundColor(.black)
                            .fontWeight(.medium)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white))
                    )
                }
            }
        }
    }

    // MARK: - Convert to 24hr time string
    private func to24Hour(_ hour: Int, _ minute: Int, _ amPm: String) -> String {
        var h = hour
        if amPm == "AM" {
            if h == 12 { h = 0 }
        } else {
            if h != 12 { h += 12 }
        }
        return String(format: "%02d:%02d:00", h, minute)
    }

    // MARK: - Add 1 hour to a 24hr time string (end time = start time + 1 hour)
    private func toEndTime(_ startTime: String) -> String {
        let parts = startTime.split(separator: ":").map { Int($0) ?? 0 }
        guard parts.count >= 2 else { return startTime }
        var endHour = (parts[0] + 1) % 24   // wrap around midnight
        let endMinute = parts[1]
        return String(format: "%02d:%02d:00", endHour, endMinute)
    }

    // MARK: - Skip
    private func skipOnboarding() {
        goToHome = true
    }

    // MARK: - Finalize
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

        let data = OnboardingData.shared

        let breakfastStr = to24Hour(breakfastHour, breakfastMinute, breakfastAmPm)
        let lunchStr     = to24Hour(lunchHour, lunchMinute, lunchAmPm)
        let dinnerStr    = to24Hour(dinnerHour, dinnerMinute, dinnerAmPm)

        // End time = start time + 1 hour
        let breakfastEndStr = toEndTime(breakfastStr)
        let lunchEndStr     = toEndTime(lunchStr)
        let dinnerEndStr    = toEndTime(dinnerStr)

        // Always include meal timings
        var details: [String: Any] = [
            "breakfast_start": breakfastStr,
            "breakfast_end":   breakfastEndStr,
            "lunch_start":     lunchStr,
            "lunch_end":       lunchEndStr,
            "dinner_start":    dinnerStr,
            "dinner_end":      dinnerEndStr
        ]

        // Only include optional fields if they have valid values
        if let diet = data.diet, !diet.isEmpty {
            details["diet"] = diet
        }
        let allergenStr = data.allergies.joined(separator: ",")
        if !allergenStr.isEmpty {
            details["allergens"] = allergenStr
        }
        // Only send height/weight if > 0 to avoid "Invalid height/weight" error
        if let height = data.heightCm, height > 0 {
            details["height_cm"] = height
        }
        if let weight = data.weightKg, weight > 0 {
            details["weight_kg"] = weight
        }
        if let gender = data.gender, !gender.isEmpty {
            details["sex"] = gender
        }
        if let dob = data.dateOfBirth, !dob.isEmpty {
            details["dob"] = dob
            details["date_of_birth"] = dob
        }

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
                    print("✅ Meal timings saved. Completing onboarding...")
                    completeOnboardingAndProceed()
                case .failure(let error):
                    print("❌ saveDetails failed: \(error.localizedDescription)")
                    infoMessage = error.localizedDescription
                }
            }
        }
    }

    private func completeOnboardingAndProceed() {
        guard let token = ProfileViewModel.shared.sessionToken else {
            infoMessage = "Session expired. Please login again."
            return
        }

        AuthService.shared.completeOnboarding(sessionToken: token) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(true):
                    print("✅ Onboarding complete. Going home...")
                    goToHome = true
                case .success(false):
                    infoMessage = "Onboarding not completed. Please try again."
                case .failure(let error):
                    print("❌ completeOnboarding failed: \(error.localizedDescription)")
                    infoMessage = error.localizedDescription
                }
            }
        }
    }
}
