//
//  AppearanceView.swift
//  iPlate
//
//  Created by Lukesh D on 27/01/26.
//

// iPlate/Views/Profile/AppearanceView.swift
import SwiftUI

struct AppearanceView: View {
    @AppStorage("selectedAppearance") private var selectedAppearance = 0
    
    var body: some View {
        List {
            Section {
                Picker("Appearance", selection: $selectedAppearance) {
                    Text("System").tag(0)
                    Text("Light").tag(1)
                    Text("Dark").tag(2)
                }
                .pickerStyle(.inline)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
}
