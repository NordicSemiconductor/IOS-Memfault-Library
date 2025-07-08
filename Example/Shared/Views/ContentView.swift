//
//  ContentView.swift
//  Shared
//
//  Created by Dinesh Harjani on 2/8/22.
//

import SwiftUI
import iOS_Common_Libraries

// MARK: - ContentView

struct ContentView: View {
    
    // MARK: Environment Variables
    
    @EnvironmentObject var appData: AppData
    
    // MARK: AppStorage
    
    @AppStorage("showAboutScreen") private var showAboutScreen = true
    
    // MARK: init
    
    init() {
        // Override Status Bar to always be 'white'.
        UIApplication.shared.statusBarStyle = .lightContent
    }
    
    // MARK: View
    
    var body: some View {
        SidebarView()
            .setTitle("nRF Memfault")
            .wrapInNavigationViewForiOS(with: .navigationBarBackground)
            .alert(item: $appData.error) { error in
                Alert(errorEvent: error)
            }
            .sheet(isPresented: $showAboutScreen) {
                AboutView()
                    .wrapInNavigationViewForiOS(with: .navigationBarBackground)
            }
    }
}
