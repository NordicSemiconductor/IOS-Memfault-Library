//
//  ContentView.swift
//  Shared
//
//  Created by Dinesh Harjani on 2/8/22.
//

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var appData: AppData
    
    var body: some View {
        NavigationView {
            ScannerView()
        }
        .navigationTitle("Memfault")
        .toolbar {
            Button(appData.isScanning ? "Stop" : "Start") {
                appData.toggleScanner()
            }
        }
        .frame(minWidth: 300, idealWidth: 300,
               minHeight: 500, idealHeight: 500)
    }
}

// MARK: - Preview

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    
    static var previews: some View {
        ContentView()
    }
}
#endif
