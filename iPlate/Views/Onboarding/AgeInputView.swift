//
//  AgeInputView.swift
//  iPlate
//
//  Created by Lukesh D on 19/10/25.
//  Updated to follow onboarding flow conventions.
//

import SwiftUI

struct AgeInputView: View {
    let userName: String

    // date parts
    @State private var day = ""
    @State private var month = ""
    @State private var year = ""

    // navigation
    @State private var goNext = false
    @State private var goHome = false

    @StateObject private var vm = OnboardingViewModel()

    // Profile values (set at login)
    private var userId: String { ProfileViewModel.shared.userID ?? "local_user" }
    private var userEmail: String { ProfileViewModel.shared.email ?? "unknown@example.com" }

    // Validate numeric parts and a plausible date
    private var isValidDate: Bool {
        guard let d = Int(day), let m = Int(month), let y = Int(year) else { return false }
        guard (1...31).contains(d) && (1...12).contains(m) && (1900...Calendar.current.component(.year, from: Date())).contains(y) else {
            return false
        }
        // Quick calendar validation
        var comps = DateComponents()
        comps.day = d
        comps.month = m
        comps.year = y
        return Calendar.current.date(from: comps) != nil
    }

    // formatted iso date for sending to server
    private var isoDateString: String? {
        guard isValidDate, let d = Int(day), let m = Int(month), let y = Int(year) else { return nil }
        let mm = String(format: "%02d", m)
        let dd = String(format: "%02d", d)
        return "\(y)-\(mm)-\(dd)" // "YYYY-MM-DD"
    }

    var body: some View {
        VStack {
            // Top row: step indicator + Skip
            HStack {
                Text("2 of 6").foregroundColor(.gray)
                Spacer()
                Button(action: { markOnboardCompleteAndExit() }) {
                    Text("Skip")
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)

            // Progress capsules (6 total)
            HStack(spacing: 8) {
                ForEach(0..<6) { idx in
                    Capsule()
                        .frame(width: 36, height: 8)
                        .foregroundColor(idx <= 1 ? Color.orange : Color.gray.opacity(0.25))
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // Title & inputs
            VStack(alignment: .leading, spacing: 12) {
                Text("When’s your birthday?")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top, 20)

                HStack(spacing: 12) {
                    // Day
                    TextField("DD", text: $day)
                        .keyboardType(.numberPad)
                        .onChange(of: day) { new in
                            // keep only digits and max 2 chars
                            day = filterDigitsAndLimit(new, limit: 2)
                        }
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)

                    // Month
                    TextField("MM", text: $month)
                        .keyboardType(.numberPad)
                        .onChange(of: month) { new in
                            month = filterDigitsAndLimit(new, limit: 2)
                        }
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)

                    // Year
                    TextField("YYYY", text: $year)
                        .keyboardType(.numberPad)
                        .onChange(of: year) { new in
                            year = filterDigitsAndLimit(new, limit: 4)
                        }
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal)

            Spacer()

            // Inline status message from VM (if any)
            if !vm.infoMessage.isEmpty {
                Text(vm.infoMessage)
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding(.bottom, 6)
            }

            // Continue button aligned to bottom-right
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
                            .background(isValidDate ? Color.orange : Color.orange.opacity(0.5))
                            .cornerRadius(22)
                    }
                    .disabled(!isValidDate)
                    .padding(.trailing, 18)
                    .padding(.bottom, 18)
                }
            }
        }
        .background(Color.white.ignoresSafeArea())
        // destination after continue
        .fullScreenCover(isPresented: $goNext) {
            DietPreferenceView()
        }
        .fullScreenCover(isPresented: $goHome) {
            HomeView()
        }
    }

    // keep only digits & limit length
    private func filterDigitsAndLimit(_ str: String, limit: Int) -> String {
        let filtered = str.filter { $0.isWholeNumber }
        if filtered.count > limit {
            return String(filtered.prefix(limit))
        }
        return filtered
    }

    private func continueTapped() {
        guard let dob = isoDateString else {
            vm.infoMessage = "Please enter a valid date."
            return
        }

        // Prepare details payload — adjust key names to your backend if required
        let details: [String:Any] = [
            "date_of_birth": dob
        ]

        vm.updateUserDetails(userId: userId, userEmail: userEmail, details: details) { result in
            switch result {
            case .success:
                // mark onboarding progress (you can choose to mark only at final step,
                // but we mark per step's temp flag here if you want)
                UserDefaults.standard.setValue(dob, forKey: "onboard_dob_\(userId)")
                // move to next onboarding view
                self.goNext = true
            case .failure(let err):
                print("updateUserDetails failed:", err.localizedDescription)
                vm.infoMessage = "❌ \(err.localizedDescription)"
            }
        }
    }

    private func markOnboardCompleteAndExit() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding_\(userId)")
        self.goHome = true
    }
}
