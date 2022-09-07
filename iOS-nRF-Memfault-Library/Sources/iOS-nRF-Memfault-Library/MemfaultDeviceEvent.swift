//
//  MemfaultDeviceEvent.swift
//  
//
//  Created by Dinesh Harjani on 26/8/22.
//

import Foundation

// MARK: MemfaultDeviceEvent

public enum MemfaultDeviceEvent: CustomStringConvertible {
    
    // MARK: Case(s)
    
    case connected, disconnected
    
    case notifications(_ enabled: Bool), streaming(_ enabled: Bool)
    case authenticated(_ auth: MemfaultDeviceAuth)
    case updatedChunk(_ chunk: MemfaultChunk, status: MemfaultChunk.Status)
    
    // MARK: CustomStringConvertible
    
    public var description: String {
        switch self {
        case .connected:
            return ".connected"
        case .disconnected:
            return ".disconnected"
        case .notifications(let enabled):
            return ".notifications(\(enabled ? "enabled" : "disabled"))"
        case .streaming(let enabled):
            return ".streaming(\(enabled ? "enabled" : "disabled"))"
        case .authenticated(_):
            return ".authenticated(_)"
        case .updatedChunk(let chunk, status: let status):
            return ".updatedChunk(\(chunk.sequenceNumber), \(String(describing: status))"
        }
    }
}
