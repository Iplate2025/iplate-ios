//
//  ProfileView.swift
//  iPlate
//
//  Created by Lukesh D on 26/01/26.
//

import SwiftUI

struct ProfileView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "person.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.orange)
            
            Text("Profile")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Coming Soon")
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    ProfileView()
}
