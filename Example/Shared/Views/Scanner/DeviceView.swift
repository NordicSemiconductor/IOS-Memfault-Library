//
//  DeviceView.swift
//  nRF Memfault
//
//  Created by Dinesh Harjani on 4/8/22.
//

import SwiftUI

// MARK: - DeviceView

struct DeviceView: View {
    
    @EnvironmentObject var appData: AppData
    
    // MARK: Private
    
    private let device: Device
    
    // MARK: Init
    
    init(_ device: Device) {
        self.device = device
    }
    
    // MARK: View
    
    var body: some View {
        Label(device.name, systemImage: "cpu")
            .setAccent(.universalAccentColor)
    }
}
