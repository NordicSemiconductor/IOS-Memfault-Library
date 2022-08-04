//
//  DeviceView.swift
//  nRF Memfault
//
//  Created by Dinesh Harjani on 4/8/22.
//

import SwiftUI

// MARK: - DeviceView

struct DeviceView: View {
    
    private let device: ScannedDevice
    
    // MARK: Init
    
    init(_ device: ScannedDevice) {
        self.device = device
    }
    
    // MARK: View
    
    var body: some View {
        VStack {
            HStack {
                Text(device.name)
                
                Spacer()
                
                if device.isConnectable {
                    Button("Connect", action: {
                        // No-op.
                    })
                } else {
                    Text("Not Connectable")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(4)
    }
}

// MARK: - Preview

#if DEBUG

struct DeviceView_Previews: PreviewProvider {
    
    static var previews: some View {
        Group {
            DeviceView(.sample)
        }
        .previewLayout(.sizeThatFits)
    }
}
#endif
