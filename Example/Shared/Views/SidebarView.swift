//
//  SidebarView.swift
//  nRF Memfault (iOS)
//
//  Created by Dinesh Harjani on 7/7/25.
//

import SwiftUI
import iOS_Common_Libraries

// MARK: - SidebarView

struct SidebarView: View {
    
    // MARK: AppStorage
    
    @AppStorage("showAboutScreen") private var showAboutScreen = false
    
    // MARK: Environment Variables
    
    @EnvironmentObject var appData: AppData
    
    // MARK: view
    
    var body: some View {
        List {
            Section("Scanner") {
                ScannerView()
            }
            
            Section {
                Button {
                    showAboutScreen = true
                } label: {
                    Label("About nRF Memfault", systemImage: "app.gift")
                }
                .setAccent(.universalAccentColor)
                .tint(.primarylabel)
            } header: {
                Text("About")
            } footer: {
                Text(Constant.copyright)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Menu(content: {
                    Toggle("Show Only Memfault Devices", isOn: $appData.showOnlyMDSDevices)
                    Toggle("Show Only Connectable Devices", isOn: $appData.showOnlyConnectableDevices)
                }, label: {
                    Image(systemName: "slider.horizontal.3")
                })
              }
        }
        .refreshable {
            appData.refresh()
        }
    }
}
