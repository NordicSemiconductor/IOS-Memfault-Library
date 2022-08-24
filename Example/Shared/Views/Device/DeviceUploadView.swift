//
//  DeviceUploadView.swift
//  nRF Memfault
//
//  Created by Dinesh Harjani on 16/8/22.
//

import SwiftUI

struct DeviceUploadView: View {
    
    @EnvironmentObject var appData: AppData
    @EnvironmentObject var device: Device
    
    // MARK: View
    
    var body: some View {
        List {
            Section("Chunks") {
                if device.chunks.isEmpty {
                    VStack(alignment: .center) {
                        Image(systemName: "eyedropper")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.nordicMiddleGrey)
                        
                        Text("No Chunks have been received at this time.")
                            .font(.subheadline)
                            .foregroundColor(.nordicMiddleGrey)
                    }
                } else {
                    ForEach(device.chunks) { chunk in
                        ChunkView(chunk)
                    }
                }
            }
            
            Section("Status") {
                let deviceIsConnected = device.state == .connected
                
                Label(device.state.description, systemImage: "personalhotspot")
                    .foregroundColor(deviceIsConnected ? .nordicPower : .nordicMiddleGrey)
                    .padding(.horizontal, 4)
                
                Label(device.notificationsEnabled ? "Notifications Enabled" : "Notifications Disabled", systemImage: "arrow.down")
                    .foregroundColor(device.notificationsEnabled ? .nordicBlue : .nordicMiddleGrey)
                    .tint(device.notificationsEnabled ? .nordicBlueslate : .nordicMiddleGrey)
                    .padding(.horizontal, 4)
                
                Label(device.streamingEnabled ? "Data Streaming Enabled" : "Data Streaming Disabled", systemImage: "antenna.radiowaves.left.and.right")
                    .foregroundColor(device.notificationsEnabled ? .nordicGrass : .nordicMiddleGrey)
                    .tint(device.notificationsEnabled ? .nordicBlue : .nordicMiddleGrey)
                    .padding(.horizontal, 4)
                
                DeviceConnectionButton()
                    .environmentObject(device)
                    .centerTextInsideForm()
            }
        }
        .navigationTitle(device.name)
    }
}

#if DEBUG
struct DeviceUploadView_Previews: PreviewProvider {
    
    static var previews: some View {
        NavigationView {
            DeviceUploadView()
                .environmentObject(Device.sample(for: .connected))
        }
    }
}
#endif
