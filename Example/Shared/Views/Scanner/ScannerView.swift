//
//  ScannerView.swift
//  nRF Memfault
//
//  Created by Dinesh Harjani on 3/8/22.
//

import SwiftUI

// MARK: - ScannerView

struct ScannerView: View {
    
    // MARK: Environment Variables
    
    @EnvironmentObject var appData: AppData
    
    // MARK: AppStorage
    
    @AppStorage("showAboutScreen") private var showAboutScreen = false
    
    // MARK: View
    
    var body: some View {
        List {
            Section("Devices") {
                if appData.scannedDevices.isEmpty {
                    VStack(alignment: .center) {
                        Image(systemName: "tray.fill")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.nordicMiddleGrey)
                        
                        Text("No Devices with current Filter Settings found.")
                            .font(.subheadline)
                            .foregroundColor(.nordicMiddleGrey)
                    }
                    .centerTextInsideForm()
                } else {
                    ForEach(appData.scannedDevices) { scannedDevice in
                        NavigationLink(destination: {
                            DeviceUploadView(scannedDevice)
                        }, label: {
                            DeviceView(scannedDevice)
                        })
                    }
                }
            }
            
            Section("About") {
                Button("Show About Screen", action: {
                    showAboutScreen = true
                })
                .foregroundColor(.primary)
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

// MARK: - Preview

#if DEBUG
struct ScannerView_Previews: PreviewProvider {
    
    static var previews: some View {
        ScannerView()
    }
}
#endif
