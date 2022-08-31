//
//  ContentView.swift
//  Shared
//
//  Created by Dinesh Harjani on 2/8/22.
//

import SwiftUI
import iOS_Common_Libraries

struct ContentView: View {
    
    // MARK: Environment Variables
    
    @EnvironmentObject var appData: AppData
    
    // MARK: AppStorage
    
    @AppStorage("showAboutScreen") private var showAboutScreen = true
    
    // MARK: View
    
    var body: some View {
        ScannerView()
            .setTitle("nRF Memfault")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        appData.toggleScanner()
                    }, label: {
                        Image(systemName: appData.isScanning ? "stop.fill" : "play.fill")
                    })
                }
            }
            .wrapInNavigationViewForiOS(with: .navigationBarBackground)
            .alert(item: $appData.error) { error in
                Alert(errorEvent: error)
            }
            .onAppear() {
                guard !appData.isScanning else { return }
                appData.toggleScanner()
            }
            .sheet(isPresented: $showAboutScreen) {
                AboutView()
            }
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
