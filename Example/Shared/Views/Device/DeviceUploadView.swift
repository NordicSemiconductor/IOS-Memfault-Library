//
//  DeviceUploadView.swift
//  nRF Memfault
//
//  Created by Dinesh Harjani on 16/8/22.
//

import SwiftUI

struct DeviceUploadView: View {
    
    // MARK: Environment Variables
    
    @EnvironmentObject var appData: AppData
    
    // MARK: Private
    
    private let device: Device
    
    // MARK: Init
    
    init(_ device: Device) {
        self.device = device
    }
    
    // MARK: View
    
    var body: some View {
        List {
            Section("Stats") {
                DeviceStatsView(device)
            }
            
            Section("Status") {
                DeviceStatusView(device)
            }
            
            if device.streamingEnabled && device.notificationsEnabled {
                ReceivingNewChunksView()
            }
            
            Section("Chunks") {
                if device.chunks.isEmpty {
                    VStack(alignment: .center) {
                        Image(systemName: "eyedropper")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.nordicMiddleGrey)
                        
                        Text("No Chunks have been received as of this time.")
                            .font(.subheadline)
                            .foregroundColor(.nordicMiddleGrey)
                    }
                    .centerTextInsideForm()
                } else {
                    ForEach(device.chunks) { chunk in
                        ChunkView(device: device, chunk: chunk)
                    }
                }
            }
        }
        .navigationTitle(device.name)
    }
}

#if DEBUG
struct DeviceUploadView_Previews: PreviewProvider {
    
    static var previews: some View {
        NavigationView {
            DeviceUploadView(Device.sample(for: .connected))
        }
    }
}
#endif
