//
//  BluetoothDevice.swift
//  nRF Memfault
//
//  Created by Dinesh Harjani on 9/8/22.
//

import Foundation
import CoreBluetooth

// MARK: - BluetoothDevice

protocol BluetoothDevice {
    
    var uuidString: String { get }
}

// MARK: - Implementations

extension CBPeripheral: BluetoothDevice {
    
    var uuidString: String {
        identifier.uuidString
    }
}
