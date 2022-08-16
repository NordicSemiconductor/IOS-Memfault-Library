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
    
    var shouldShowConnectedInformation: Bool {
        return device.state == .connected
                || device.state == .disconnecting
    }
    
    // MARK: View
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(device.name)
                
                Spacer()
                
                switch device.state {
                case .notConnectable:
                    Text("Not Connectable")
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
                    .foregroundColor(.nordicFall)
                case .connecting:
                    ProgressView()
                        .frame(width: 6, height: 6)
                        .padding(.trailing)
                    
                    Button("Connecting...", action: {
                        appData.disconnect(from: device)
                    })
                    .font(.callout)
                    .foregroundColor(.nordicBlue)
                case .disconnecting:
                    ProgressView()
                        .frame(width: 6, height: 6)
                        .padding(.trailing)
                    
                    Text("Disconnecting...")
                        .font(.callout)
                        .foregroundColor(.nordicMiddleGrey)
                }
            }
            
            if shouldShowConnectedInformation {
                Label(device.notificationsEnabled ? "Notifications Enabled" : "Notifications Disabled", systemImage: "arrow.down")
                    .font(.caption)
                    .foregroundColor(device.notificationsEnabled ? .nordicBlue : .nordicMiddleGrey)
                    .tint(device.notificationsEnabled ? .nordicBlue : .nordicMiddleGrey)
                    .padding(.horizontal, 4)
                
                Label(device.streamingEnabled ? "Data Streaming Enabled" : "Data Streaming Disabled", systemImage: "antenna.radiowaves.left.and.right")
                    .font(.caption)
                    .foregroundColor(device.notificationsEnabled ? .nordicGrass : .nordicMiddleGrey)
                    .tint(device.notificationsEnabled ? .nordicBlue : .nordicMiddleGrey)
                    .padding(.horizontal, 4)
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
            ForEach(ConnectedState.allCases, id: \.self) { connState in
                DeviceView(.sample(for: connState))
            }
        }
        .previewLayout(.sizeThatFits)
    }
}
#endif
