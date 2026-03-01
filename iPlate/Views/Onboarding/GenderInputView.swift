//
//  GenderInputView.swift
//  iPlate
//
//  3rd onboarding screen: asks gender, Skip and Continue
//  Linked with PUT /user/details
//

import SwiftUI

struct GenderInputView: View {
    // Options matching the UI image
    private let options = ["Male", "Female", "Prefer not to say"]

    @State private var selectedGender: String? = nil
    @State private var goNext = false
    @State private var goHome = false

    @StateObject private var vm = OnboardingViewModel()

    private var userId: String { ProfileViewModel.shared.userID ?? "local_user" }
    private var userEmail: String { ProfileViewModel.shared.email ?? "unknown@example.com" }

    var body: some View {
        VStack {
            // Top row: step indicator + Skip
            HStack {
                Text("3 of 7").foregroundColor(.gray)
                Spacer()
                Button("Skip") {
                    markOnboardCompleteAndGoHome()
                }
                .foregroundColor(.gray)
            }
            .padding(.horizontal)
            .padding(.top, 12)

            // Progress capsules (7 total, highlight first 3)
            HStack(spacing: 6) {
                ForEach(0..<7) { idx in
                    Capsule()
                        .frame(width: 30, height: 8)
                        .foregroundColor(idx <= 2 ? Color.orange : Color.gray.opacity(0.25))
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // Title
            VStack(alignment: .leading, spacing: 8) {
                Text("What is your gender?")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top, 20)
            }
            .padding(.horizontal)

            // Gender option buttons
            VStack(spacing: 12) {
                ForEach(options, id: \.self) { option in
                    Button(action: { selectedGender = option }) {
                        HStack {
                            Text(option)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(
                                    selectedGender == option ? Color.orange : Color.gray.opacity(0.3),
                                    lineWidth: selectedGender == option ? 2 : 1
                                )
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(selectedGender == option ? Color.orange.opacity(0.05) : Color.white)
                                )
                        )
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.top, 12)

            Spacer()

            // Inline VM info message
            if !vm.infoMessage.isEmpty {
                Text(vm.infoMessage)
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding(.bottom, 6)
            }

            // Continue button bottom-right
            HStack {
                Spacer()
                if vm.isLoading {
                    ProgressView()
                        .padding(.trailing, 18)
                        .padding(.bottom, 18)
                } else {
                    Button(action: continueTapped) {
                        Text("Continue")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 26)
                            .background(selectedGender != nil ? Color.orange : Color.orange.opacity(0.5))
                            .cornerRadius(22)
                    }
                    .disabled(selectedGender == nil)
                    .padding(.trailing, 18)
                    .padding(.bottom, 18)
                }
            }
        }
        .background(Color.white.ignoresSafeArea())
        .fullScreenCover(isPresented: $goNext) {
            DietPreferenceView()
        }
        .fullScreenCover(isPresented: $goHome) {
            HomeView()
        }
    }

    // MARK: - Actions
    private func continueTapped() {
        guard let gender = selectedGender else {
            vm.infoMessage = "Please select a gender or Skip."
            return
        }

        // Save locally for final step
        OnboardingData.shared.gender = gender

        // Send to API: PUT /user/details
        let details: [String: Any] = ["gender": gender]

        print("📤 Sending Gender payload: \(details)")

        vm.updateUserDetails(userId: userId, userEmail: userEmail, details: details) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("✅ Gender saved successfully: \(gender)")
                    self.goNext = true
                case .failure(let err):
                    print("❌ updateUserDetails (Gender) failed: \(err.localizedDescription)")
                    // Navigate forward anyway so onboarding is not blocked
                    self.goNext = true
                }
            }
        }
    }

    private func markOnboardCompleteAndGoHome() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding_\(userId)")
        goHome = true
    }
}

#Preview {
    GenderInputView()
}
