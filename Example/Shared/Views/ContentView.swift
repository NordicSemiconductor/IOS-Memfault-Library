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
        #if os(iOS)
        NavigationView {
            ScannerView()
                .background(.green)
        }
        .navigationTitle("nRF Memfault")
        .navigationViewStyle(StackNavigationViewStyle())
        .toolbar {
            commonToolbar()
        }
        .onAppear() {
            appData.toggleScanner()
        }
        #else
        VStack {
            ScannerView()
        }
        .toolbar {
            commonToolbar()
        }
        .onAppear() {
            appData.toggleScanner()
        }
        .frame(minWidth: 150, idealWidth: 150,
               minHeight: 500, idealHeight: 500)
        #endif
    }
    
    @ViewBuilder
    func commonToolbar() -> some View {
        Button(action: {
            appData.refresh()
        }, label: {
            Image(systemName: "arrow.clockwise")
        })
        .keyboardShortcut(KeyEquivalent(Character("r")), modifiers: [.command])

        Button(action: {
            appData.toggleScanner()
        }, label: {
            Image(systemName: appData.isScanning ? "stop.fill" : "play.fill")
        })
        .keyboardShortcut(KeyEquivalent(Character(" ")), modifiers: [])
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
