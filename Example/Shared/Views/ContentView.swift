//
//  ContentView.swift
//  Shared
//
//  Created by Dinesh Harjani on 2/8/22.
//

import SwiftUI
import iOS_Common_Libraries

struct ContentView: View {
    
    @EnvironmentObject var appData: AppData
    
    var body: some View {
        #if os(iOS)
        ScannerView()
            .setTitle("nRF Memfault")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        appData.refresh()
                    }, label: {
                        Image(systemName: "arrow.clockwise")
                    })
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        appData.toggleScanner()
                    }, label: {
                        Image(systemName: appData.isScanning ? "stop.fill" : "play.fill")
                    })
                }
            }
            .wrapInNavigationViewForiOS(with: .nordicBlue)
            .alert(item: $appData.error) { error in
                Alert(errorEvent: error)
            }
            .onAppear() {
                guard !appData.isScanning else { return }
                appData.toggleScanner()
            }
        #else
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
        .alert(item: $appData.error) { error in
            Alert(errorEvent: error)
        }
        .onAppear() {
            guard !appData.isScanning else { return }
            appData.toggleScanner()
        }
        .frame(minWidth: 150, idealWidth: 150,
               minHeight: 500, idealHeight: 500)
        #endif
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
