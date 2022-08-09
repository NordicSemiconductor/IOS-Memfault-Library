//
//  ScannerDevice.swift
//  nRF Memfault
//
//  Created by Dinesh Harjani on 9/8/22.
//

import Foundation
import CoreBluetooth

// MARK: - ScannerDevice

protocol ScannerDevice {
    
    var uuidString: String { get }
}

// MARK: - Implementations

extension CBPeripheral: ScannerDevice {
    
    var uuidString: String {
        identifier.uuidString
    }
}
