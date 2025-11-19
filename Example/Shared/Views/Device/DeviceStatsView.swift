//
//  DeviceStatsView.swift
//  nRF Memfault
//
//  Created by Dinesh Harjani on 31/8/22.
//

import SwiftUI

// MARK: - DeviceStatsView

struct DeviceStatsView: View {
    
    // MARK: elapsedTimeFormatter
    
    static let elapsedTimeFormatter: RelativeDateTimeFormatter = {
        let relativeFormatter = RelativeDateTimeFormatter()
        relativeFormatter.dateTimeStyle = .numeric
        return relativeFormatter
    }()
    
    // MARK: byteCountFormatter
    
    static let byteCountFormatter: ByteCountFormatter = {
        let byteCountFormatter = ByteCountFormatter()
        byteCountFormatter.countStyle = .binary
        byteCountFormatter.isAdaptive = true
        return byteCountFormatter
    }()
    
    // MARK: Private
    
    private let device: Device
    private let chunkCount: Int
    private let byteCountString: String
    
    private var isRunningOniPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    private var deviceIsConnected: Bool {
        device.state == .connected
    }
    
    private var chunkCountColor: Color {
        guard deviceIsConnected else {
            return .nordicMiddleGrey
        }
        return chunkCount > 0 ? Color.nordicPower : Color.primary
    }
    
    private var elapsedColor: Color {
        deviceIsConnected ? Color.nordicPower : Color.nordicMiddleGrey
    }
    
    private var byteCountColor: Color {
        guard deviceIsConnected else {
            return .nordicMiddleGrey
        }
        guard chunkCount > 0 else {
            return Color.primary
        }
        return device.online ? Color.nordicPower : Color.yellow
    }
    
    // MARK: init
    
    init(_ device: Device) {
        self.device = device
        self.chunkCount = device.chunks.count
        let byteCount = device.chunks.reduce(0, { $0 + $1.data.count })
        self.byteCountString = Self.byteCountFormatter.string(fromByteCount: Int64(byteCount))
    }
    
    // MARK: View
    
    var body: some View {
        HStack {
            VStack(spacing: 8) {
                Image(systemName: "shippingbox")
                    .foregroundColor(chunkCountColor)
                
                Text("\(chunkCount)")
                    .foregroundColor(chunkCountColor)
                
                Text("Chunks")
                    .bold()
            }
            .frame(maxWidth: .infinity)
            
            Divider()
            
            VStack(spacing: 8) {
                Image(systemName: "clock")
                    .foregroundStyle(elapsedColor)
                
                if device.state == .connected, let elapsedTimestamp = device.uptimeStartTimestamp {
                    TimelineView(.periodic(from: .now, by: 1.0)) { context in
                        let elapsedString = ChunkView.relativeTimestampFormatter.string(for: elapsedTimestamp)?.replacingOccurrences(of: "ago", with: "")
                        Text(elapsedString ?? "N/A")
                            .foregroundStyle(elapsedColor)
                    }
                } else {
                    Text("N/A")
                        .foregroundStyle(elapsedColor)
                }
                
                Text("Uptime")
                    .bold()
            }
            .frame(maxWidth: .infinity)
            
            Divider()
            
            VStack(spacing: 8) {
                Image(systemName: "network")
                    .foregroundColor(byteCountColor)
                
                Text(byteCountString)
                    .foregroundColor(byteCountColor)
                
                Text(device.online ? "Sent" : "Received")
                    .bold()
            }
            .frame(maxWidth: .infinity)
        }
        .monospacedDigit()
    }
}
