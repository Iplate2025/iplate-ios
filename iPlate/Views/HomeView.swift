import SwiftUI

struct HomeView: View {

    @State private var isLoggingOut = false
    @State private var logoutError: String?
    @State private var goToLogin = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {

                Text("Welcome to iPlate")
                    .font(.title)
                    .fontWeight(.semibold)

                Text("You are logged in.")
                    .foregroundColor(.secondary)

                Button(action: performLogout) {
                    HStack(spacing: 8) {
                        if isLoggingOut {
                            ProgressView()
                        }
                        Text("Log out")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                .disabled(isLoggingOut)

                if let logoutError {
                    Text(logoutError)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Home")
        }
        .fullScreenCover(isPresented: $goToLogin) {
            LoginView()
        }
    }

    // MARK: - Logout (this device only)
    private func performLogout() {
        guard let token = ProfileViewModel.shared.sessionToken else {
            logoutError = "Session missing"
            return
        }

        isLoggingOut = true
        logoutError = nil

        AuthService.shared.logout(sessionToken: token) { result in
            DispatchQueue.main.async {
                self.isLoggingOut = false

                switch result {
                case .success:
                    // ✅ Backend session deleted
                    ProfileViewModel.shared.clear()
                    goToLogin = true

                case .failure(let error):
                    // ❌ Do NOT clear locally
                    self.logoutError = error.localizedDescription
                }
            }
        }
    }


    // MARK: - Local cleanup + redirect
    private func forceLocalLogout() {
        ProfileViewModel.shared.clear()
        goToLogin = true
    }
}

#Preview {
    HomeView()
}
