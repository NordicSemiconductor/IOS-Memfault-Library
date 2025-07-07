//
//  ScannerView.swift
//  nRF Memfault
//
//  Created by Dinesh Harjani on 3/8/22.
//

import SwiftUI
import iOS_Common_Libraries

// MARK: - ScannerView

struct ScannerView: View {
    
    // MARK: Environment Variables
    
    @EnvironmentObject var appData: AppData
    
    // MARK: View
    
    var body: some View {
        ForEach(appData.scannedDevices) { scannedDevice in
            NavigationLink(destination: {
                DeviceUploadView(scannedDevice)
            }, label: {
                DeviceView(scannedDevice)
            })
        }
        
        if appData.scannedDevices.isEmpty {
            NoContentView(title: "Empty Scanner", systemImage: "tray.fill",
                          description: "No Devices with current Filter Settings found.")
        }
    }
}
