//
//  AboutView.swift
//  nRF Memfault
//
//  Created by Dinesh Harjani on 25/8/22.
//

import SwiftUI
import iOS_Common_Libraries

// MARK: - AboutView

struct AboutView: View {
    
    // MARK: Environment
    
    @Environment(\.dismiss) var dismiss
    
    // MARK: Properties
    
    private static let sourceCodeURL: URL! = URL(string: "https://github.com/NordicSemiconductor/IOS-Memfault-Library")
    
    // MARK: view
    
    var body: some View {
        List {
            Section("") {
                AppIconView()
                    .frame(width: 100, height: 100)
                    .cornerRadius(8.0)
                    .centered()
                    .padding(.top)
                
                VStack(spacing: 8.0) {
                    Text("nRF Memfault [DEPRECATED]")
                        .font(.title)
                        .bold()
                    
                    Text("Version \(Constant.appVersion(forBundleWithClass: AppData.self))")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    
                    Text(Constant.copyright)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                .centered()
            }
            .listRowSeparator(.hidden)
            
            Section("Description") {
                Label("nRF Memfault is now deprecated.", systemImage: "exclamationmark.triangle")
                    .bold()
                    .centered()
                
                Text("The library has been superseeded by the newer [iOSOtaLibrary, which is part of the larger iOSMcuMgrLibrary Package](https://github.com/NordicSemiconductor/IOS-nRF-Connect-Device-Manager). The newer library is a superset of the previous one, so all functionalities remain, plus Over-The-Air capabilities, as well as on-device store of chunks that have been received, but not sent due to Network unavailability.")
                    .tint(.nordicBlue)
            }
            .listRowSeparator(.hidden)
            
            Section("Requirements") {
                Label("The connected device must implement the Memfault Diagnostic Service or MDS.", systemImage: "cpu")
                
                Label("An Internet connection is required to upload data to the [Memfault Console](https://docs.memfault.com/docs/android/introduction). If the network is unavailable, received chunks will be stored locally until connectivity is restored.", systemImage: "wifi.router.fill")
                    .tint(.nordicBlue)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("About App")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarRole(.navigationStack)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Dismiss", systemImage: "chevron.down") {
                    dismiss()
                }
                .tint(Color.white)
            }
        }
        .setAccent(.nordicBlue)
    }
}
