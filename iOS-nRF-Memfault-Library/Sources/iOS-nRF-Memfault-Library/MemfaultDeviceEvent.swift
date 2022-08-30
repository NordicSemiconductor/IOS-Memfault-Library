//
//  MemfaultDeviceEvent.swift
//  
//
//  Created by Dinesh Harjani on 26/8/22.
//

import Foundation

public enum MemfaultDeviceEvent {
    case connected
    case notifications(_ enabled: Bool), streaming(_ enabled: Bool)
    case authenticated(_ auth: MemfaultDeviceAuth)
    
    case updatedChunk(_ chunk: MemfaultChunk, status: MemfaultChunk.Status)
    
    case disconnected
}
