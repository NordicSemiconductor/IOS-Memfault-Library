//
//  DeviceStatusView.swift
//  nRF Memfault
//
//  Created by Dinesh Harjani on 24/8/22.
//

import SwiftUI

// MARK: - DeviceStatusView

struct DeviceStatusView: View {
    
    // MARK: Environment Variables
    
    @EnvironmentObject var device: Device
    
    // MARK: Private
    
    private var deviceIsConnected: Bool {
        device.state == .connected
    }
    
    // MARK: View
    
    var body: some View {
        Label(device.state.description, systemImage: "personalhotspot")
            .foregroundColor(deviceIsConnected ? .nordicPower : .nordicMiddleGrey)
            .padding(.horizontal, 4)
        
        let disabledColor: Color = deviceIsConnected ? .nordicSun : .nordicMiddleGrey
        Label(device.notificationsEnabled ? "Data Notifications Enabled" : "Data Notifications Disabled", systemImage: "arrow.down")
            .foregroundColor(device.notificationsEnabled ? .nordicPower : disabledColor)
            .padding(.horizontal, 4)
        
        Label(device.streamingEnabled ? "Data Streaming Enabled" : "Data Streaming Disabled", systemImage: "antenna.radiowaves.left.and.right")
            .foregroundColor(device.streamingEnabled ? .nordicPower : disabledColor)
            .padding(.horizontal, 4)
        
        DeviceConnectionButton()
            .environmentObject(device)
            .centerTextInsideForm()
    }
}
