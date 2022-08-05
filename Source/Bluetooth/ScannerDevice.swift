//
//  ScannerDevice.swift
//  nRF Memfault
//
//  Created by Dinesh Harjani on 5/8/22.
//

import Foundation

// MARK: - ScannerDevice

public protocol ScannerDevice {
    
    var name: String { get }
    var uuid: String { get }
    var rssi: RSSI { get }
    var isConnectable: Bool { get }
    var state: ConnectedState { get set }
}

// MARK: - ConnectedState

public enum ConnectedState: Int {
    case notConnectable
    case connecting, connected, disconnecting, disconnected
}
