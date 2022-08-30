//
//  MemfaultDevice.swift
//  iOS-nRF-Memfault-Library
//
//  Created by Dinesh Harjani on 26/8/22.
//

import Foundation
import iOS_BLE_Library

// MARK: - MemfaultDeviceAuth

public struct MemfaultDeviceAuth {
    
    let url: URL
    let authKey: String
    let authValue: String
}

// MARK: - MemfaultDevice

struct MemfaultDevice: BluetoothDevice {
    
    let uuidString: String
    var isConnected: Bool
    var isNotifying: Bool
    var isStreaming: Bool
    var auth: MemfaultDeviceAuth?
    
    init(uuidString: String) {
        self.uuidString = uuidString
        self.isConnected = false
        self.isNotifying = false
        self.isStreaming = false
        self.auth = nil
    }
}
