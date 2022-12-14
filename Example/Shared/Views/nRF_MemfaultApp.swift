//
//  nRF_MemfaultApp.swift
//  Shared
//
//  Created by Dinesh Harjani on 2/8/22.
//

import SwiftUI

@main
struct nRF_MemfaultApp: App {
    
    let appData = AppData()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appData)
        }
    }
}
