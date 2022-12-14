//
//  DeviceStatsView.swift
//  nRF Memfault
//
//  Created by Dinesh Harjani on 31/8/22.
//

import SwiftUI

// MARK: - DeviceStatsView

struct DeviceStatsView: View {
    
    // MARK: Private
    
    private let device: Device
    
    // MARK: Init
    
    init(_ device: Device) {
        self.device = device
    }
    
    static let elapsedTimeFormatter: RelativeDateTimeFormatter = {
        let relativeFormatter = RelativeDateTimeFormatter()
        relativeFormatter.dateTimeStyle = .numeric
        
        return relativeFormatter
    }()
    
    static let byteCountFormatter: ByteCountFormatter = {
        let byteCountFormatter = ByteCountFormatter()
        byteCountFormatter.countStyle = .binary
        byteCountFormatter.isAdaptive = true
        return byteCountFormatter
    }()
    
    private var isRunningOniPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    private var deviceIsConnected: Bool {
        device.state == .connected
    }
    
    // MARK: View
    
    var body: some View {
        HStack {
            if isRunningOniPad {
                Spacer()
            }
            
            VStack(spacing: 8) {
                Image(systemName: "shippingbox")
                
                Text("\(device.chunks.count)")
                    .foregroundColor(deviceIsConnected ? .nordicMiddleGrey : .primary)
                
                Text("Chunks")
                    .bold()
            }
            
            Spacer()
            
            VStack(spacing: 8) {
                Image(systemName: "network")
                
                let byteCount = device.chunks.reduce(0, { $0 + $1.data.count })
                Text(Self.byteCountFormatter.string(fromByteCount: Int64(byteCount)))
                    .foregroundColor(deviceIsConnected ? .nordicMiddleGrey : .primary)
                
                Text("Sent")
                    .bold()
            }
            
            Spacer()
            
            VStack(spacing: 8) {
                Image(systemName: "clock")
                
                if device.state == .connected, let elapsedTimestamp = device.uptimeStartTimestamp {
                    TimelineView(.periodic(from: .now, by: 1.0)) { context in
                        let elapsedString = ChunkView.timestampFormatter.string(for: elapsedTimestamp)?.replacingOccurrences(of: "ago", with: "")
                        Text(elapsedString ?? "N/A")
                            .foregroundColor(.nordicMiddleGrey)
                    }
                } else {
                    Text("N/A")
                }
                
                Text("Uptime")
                    .bold()
            }
            
            if isRunningOniPad {
                Spacer()
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct DeviceStatsView_Previews: PreviewProvider {
    
    static var previews: some View {
        NavigationView {
            DeviceStatsView(Device.sample(for: .connected))
        }
    }
}
#endif
