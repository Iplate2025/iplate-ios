//
//  HelpSupportView.swift
//  iPlate
//
//  Created by Lukesh D on 27/01/26.
//

// iPlate/Views/Profile/HelpSupportView.swift
import SwiftUI

struct HelpSupportView: View {
    var body: some View {
        List {
            Section {
                NavigationLink("FAQ") {
                    Text("FAQ Content")
                }
                NavigationLink("Contact Us") {
                    Text("Contact Information")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Help & Support")
        .navigationBarTitleDisplayMode(.inline)
    }
}
