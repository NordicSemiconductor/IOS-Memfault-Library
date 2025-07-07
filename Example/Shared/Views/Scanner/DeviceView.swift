//
//  DeviceView.swift
//  nRF Memfault
//
//  Created by Dinesh Harjani on 4/8/22.
//

import SwiftUI
import iOS_Common_Libraries

// MARK: - DeviceView

struct DeviceView: View {
    
    @EnvironmentObject var appData: AppData
    
    // MARK: Private
    
    private let device: Device
    private let isMDSDevice: Bool
    
    // MARK: Init
    
    init(_ device: Device) {
        self.device = device
        self.isMDSDevice = device.advertisesMDS()
    }
    
    // MARK: View
    
    var body: some View {
        VStack(alignment: .leading) {
            Label(device.name, systemImage: "cpu")
                .setAccent(isMDSDevice ? .universalAccentColor : .primary)
            
            if isMDSDevice {
                BadgeView(image: Image(systemName: "square.stack.3d.up.fill"),
                          name: "Memfault Diagnostic Service", color: .nordicBlueslate)
                    .padding(.leading, 44.0)
            }
        }
    }
}
