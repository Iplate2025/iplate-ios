//
//  HeightWeightView.swift
//  iPlate
//
//  Created by Lukesh D on 20/10/25.
//

import SwiftUI

struct HeightWeightView: View {

    @State private var height = ""
    @State private var weight = ""

    @State private var showNext = false
    @State private var goHome = false

    @State private var infoMessage = ""
    @State private var isLoading = false

    // ViewModel for PUT /user/details
    @StateObject private var vm = OnboardingViewModel()

    // Get from logged session
    private var userId: String {
        ProfileViewModel.shared.userID ?? "local_user"
    }
    private var userEmail: String {
        ProfileViewModel.shared.email ?? "unknown@example.com"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            // TOP BAR
            HStack {
                Text("5 of 6")
                    .foregroundColor(.gray)

                Spacer()

                Button("Skip") {
                    skipOnboarding()
                }
                .foregroundColor(.gray)
            }
            .padding(.horizontal)
            .padding(.top, 12)

            // PROGRESS CAPSULES
            HStack(spacing: 8) {
                ForEach(0..<6) { i in
                    Capsule()
                        .frame(width: 36, height: 8)
                        .foregroundColor(i <= 4 ? .orange : Color.gray.opacity(0.3))
                }
            }
            .padding(.horizontal)

            // TITLE
            Text("Set your Height & Weight")
                .font(.title2.bold())
                .padding(.horizontal)

            // HEIGHT FIELD
            VStack(alignment: .leading, spacing: 6) {
                Text("What's your height?")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                HStack {
                    TextField("Enter height", text: $height)
                        .keyboardType(.decimalPad)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)

                    Text("cm")
                        .foregroundColor(.gray)
                        .frame(width: 50, height: 48)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal)

            // WEIGHT FIELD
            VStack(alignment: .leading, spacing: 6) {
                Text("What's your weight?")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                HStack {
                    TextField("Enter weight", text: $weight)
                        .keyboardType(.decimalPad)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)

                    Text("kg")
                        .foregroundColor(.gray)
                        .frame(width: 50, height: 48)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal)

            Spacer()

            // INLINE MESSAGE
            if !infoMessage.isEmpty {
                Text(infoMessage)
                    .foregroundColor(.gray)
                    .font(.footnote)
                    .padding(.horizontal)
            }

            // CONTINUE BUTTON
            HStack {
                Spacer()
                Button(action: saveAndContinue) {
                    Text("Continue")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 32)
                        .background((height.isEmpty || weight.isEmpty) ? Color.gray : Color.orange)
                        .cornerRadius(25)
                }
                .disabled(height.isEmpty || weight.isEmpty || isLoading)
                Spacer()
            }

            Spacer(minLength: 20)
        }
        .background(Color.white.ignoresSafeArea())
        .fullScreenCover(isPresented: $showNext) {
            MealTimingView()
        }
        .fullScreenCover(isPresented: $goHome) {
            HomeView()
        }
    }

    // MARK: - SKIP BUTTON ACTION
    private func skipOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding_\(userId)")
        goHome = true
    }

    // MARK: - CONTINUE → SEND TO BACKEND → NEXT PAGE
    private func saveAndContinue() {

        guard let heightValue = Double(height),
              let weightValue = Double(weight) else {
            infoMessage = "Please enter valid numeric values."
            return
        }

        isLoading = true
        infoMessage = "Saving..."

        let payload: [String: Any] = [
            "height_cm": heightValue,
            "weight_kg": weightValue
        ]

        vm.updateUserDetails(userId: userId, userEmail: userEmail, details: payload) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(_):
                    print("✅ Height & Weight saved.")
                    self.showNext = true

                case .failure(let error):
                    self.infoMessage = "❌ \(error.localizedDescription)"
                }
            }
        }
    }
}
