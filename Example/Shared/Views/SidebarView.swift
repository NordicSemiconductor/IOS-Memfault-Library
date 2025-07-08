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
    
    // MARK: Properties
    
    private static let sourceCodeURL: URL! = URL(string: "https://github.com/NordicSemiconductor/IOS-Memfault-Library")
    
    // MARK: view
    
    var body: some View {
        List {
            Section("Scanner") {
                ScannerView()
            }
            .listRowSeparator(.hidden)
            
            Section {
                Button {
                    showAboutScreen = true
                } label: {
                    Label("About nRF Memfault", systemImage: "app.gift")
                }
                
                if let url = Self.sourceCodeURL {
                    SourceCodeLinkView(url: url)
                }
                
                DevZoneLinkView()
            } header: {
                Text("About")
            } footer: {
                Text(Constant.copyright)
            }
            .setAccent(.universalAccentColor)
            .tint(.primarylabel)
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("Refresh", systemImage: "arrow.counterclockwise") {
                    appData.refresh()
                }
            }
        }
        .refreshable {
            appData.refresh()
        }
    }
}
