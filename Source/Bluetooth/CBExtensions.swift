//
//  CBExtensions.swift
//  nRF Memfault
//
//  Created by Nick Kibysh on 07/04/2021.
//  Created by Dinesh Harjani on 3/8/22.
//

import Foundation
import CoreBluetooth

// MARK: - CBManagerState

extension CBManagerState: CustomDebugStringConvertible, CustomStringConvertible {
    
    public var debugDescription: String {
        return description
    }
    
    public var description: String {
        switch self {
        case .poweredOff:
            return "poweredOff"
        case .poweredOn:
            return "poweredOn"
        case .resetting:
            return "resetting"
        case .unauthorized:
            return "unauthorized"
        case .unknown:
            return "unknown"
        case .unsupported:
            return "unsupported"
        @unknown default:
            return "unknownState"
        }
    }
}
