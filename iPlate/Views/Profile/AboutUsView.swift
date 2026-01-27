//
//  AboutUsView.swift
//  iPlate
//
//  Created by Lukesh D on 27/01/26.
//

// iPlate/Views/Profile/AboutUsView.swift
import SwiftUI

struct AboutUsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.orange)
            
            Text("iPlate")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Version 1.0.0")
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.top, 60)
        .navigationTitle("About Us")
        .navigationBarTitleDisplayMode(.inline)
    }
}
