//
//  DeviceConnectionButton.swift
//  nRF Memfault
//
//  Created by Dinesh Harjani on 24/8/22.
//

import SwiftUI

// MARK: - DeviceConnectionButton

struct DeviceConnectionButton: View {
    
    // MARK: Environment Variables
    
    @EnvironmentObject var appData: AppData
    @EnvironmentObject var device: Device
    
    // MARK: View
    
    var body: some View {
        switch device.state {
        case .notConnectable:
            Text(device.state.description)
                .font(.caption)
                .foregroundColor(.nordicMiddleGrey)
        case .disconnected:
            Button("Connect", action: {
                appData.connect(to: device)
            })
            .font(.callout)
            .foregroundColor(.nordicBlue)
        case .connected:
            Button("Disconnect", action: {
                appData.disconnect(from: device)
            })
            .foregroundColor(.nordicRed)
        case .connecting:
            ProgressView()
                .frame(width: 6, height: 6)
                .padding(.trailing)
            
            Button(device.state.description, action: {
                appData.disconnect(from: device)
            })
            .font(.callout)
            .foregroundColor(.nordicBlue)
        case .disconnecting:
            ProgressView()
                .frame(width: 6, height: 6)
                .padding(.trailing)
            
            Text(device.state.description)
                .font(.callout)
                .foregroundColor(.nordicMiddleGrey)
        }
    }
}
