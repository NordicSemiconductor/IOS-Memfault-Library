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
        VStack {
            ScannerView()
        }
        .toolbar {
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
        .frame(minWidth: 150, idealWidth: 150,
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
