//
//  ConnectedDevicesView.swift
//  iPlate
//
//  Created by Lukesh D on 27/01/26.
//

// iPlate/Views/Profile/ConnectedDevicesView.swift
import SwiftUI

struct ConnectedDevicesView: View {
    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "applewatch")
                        .foregroundColor(.orange)
                    Text("Apple Watch")
                    Spacer()
                    Text("Not Connected")
                        .foregroundColor(.secondary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Connected Devices")
        .navigationBarTitleDisplayMode(.inline)
    }
}
