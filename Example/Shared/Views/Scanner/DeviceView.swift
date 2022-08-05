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
                
                switch device.state {
                case .notConnectable:
                    Text("Not Connectable")
                        .font(.caption)
                        .foregroundColor(.secondary)
                case .disconnected:
                    Button("Connect", action: {
                        appData.connect(to: device)
                    })
                case .connected:
                    Button("Disconnect", action: {
                        // No-op.
                    })
                case .connecting:
                    ProgressView()
                        .frame(width: 6, height: 6)
                        .padding(.trailing)
                    
                    Button("Connecting...", action: {
                        // No-op.
                    })
                case .disconnecting:
                    ProgressView()
                        .frame(width: 6, height: 6)
                        .padding(.trailing)
                    
                    Text("Disconnecting...")
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
