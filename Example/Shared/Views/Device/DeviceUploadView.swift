//
//  DeviceUploadView.swift
//  nRF Memfault
//
//  Created by Dinesh Harjani on 16/8/22.
//

import SwiftUI
import iOS_Common_Libraries

// MARK: - DeviceUploadView

struct DeviceUploadView: View {
    
    // MARK: Environment Variables
    
    @EnvironmentObject var appData: AppData
    
    // MARK: Private
    
    private let device: Device
    
    // MARK: init
    
    init(_ device: Device) {
        self.device = device
    }
    
    // MARK: View
    
    var body: some View {
        List {
            Section {
                DeviceStatsView(device)
            }
            
            Section("Status") {
                DeviceStatusView(device)
            }
            
            if device.online && device.notificationsEnabled {
                ReceivingNewChunksView()
            }
            
            Section("Chunks") {
                ForEach(device.chunks) { chunk in
                    ChunkView(device: device, chunk: chunk)
                }
                
                if device.chunks.isEmpty {
                    NoContentView(title: "No Chunks Received", systemImage: "tray",
                                  description: "On a code sample, you may try pressing one of the devkit's buttons, such as Button 4, to generate some chunks.")
                }
            }
        }
        .navigationTitle(device.name)
    }
}
