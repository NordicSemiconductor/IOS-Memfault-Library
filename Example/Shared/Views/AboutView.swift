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
                    .iridescence()
                
                Text("nRF Memfault")
                    .centered()
                    .font(.title)
                    .bold()
                
                Text("Version \(Constant.appVersion(forBundleWithClass: AppData.self))")
                    .centered()
                    .foregroundStyle(.secondary)
                    .font(.caption)
                
                Text(Constant.copyright)
                    .centered()
                    .foregroundStyle(.secondary)
                    .font(.caption)
                    .padding(.top, -8.0)
            }
            .listRowSeparator(.hidden)
            
            Section("Description") {
                Text("An iOS Example App + Library that can connect to a Bluetooth LE device with the Memfault Diagnostic Service, receive Chunks of Data, and upload them to [Memfault](https://memfault.com/).")
                    .tint(.nordicBlue)
                
                if let link = Self.sourceCodeURL {
                    Link(destination: link, label: {
                        Label("Full Source Code (GitHub)", systemImage: "square.and.arrow.up")
                            .foregroundColor(.nordicBlue)
                            .centered()
                    })
                }
            }
            .listRowSeparator(.hidden)
            
            Section("Requirements") {
                Text("As noted above, this Example App / Library requires that the connected Device implement the Memfault Diagnostic Service.")
    
                Text("An Internet connection is required to upload Data back to the [Memfault Console](https://docs.memfault.com/docs/android/introduction). **If uploading a Chunk fails, the BLE connection with the device will be dropped** to minimise data loss.")
                    .tint(.nordicBlue)
            }
            .listRowSeparator(.hidden)
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
