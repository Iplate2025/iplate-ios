import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Welcome to iPlate")
                    .font(.title)
                    .fontWeight(.semibold)
                Text("You are logged in.")
                    .foregroundColor(.secondary)
                Button("Log out") {
                    UserDefaults.standard.removeObject(forKey: "user_id")
                    // Simple way to return to login: dismiss all or restart root view.
                    // If you implement session logic, swap root view to login.
                    // For now, just terminate the app view: (not recommended for production)
                    exit(0)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            .padding()
        }
    }
}

#Preview {
    HomeView()
}
