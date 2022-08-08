//
//  ScannerDevice.swift
//  nRF Memfault
//
//  Created by Dinesh Harjani on 5/8/22.
//

import Foundation
import CoreBluetooth

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
    
    static func from(_ cbState: CBPeripheralState) -> ConnectedState {
        switch cbState {
        case .connecting:
            return .connecting
        case .connected:
            return .connected
        case .disconnecting:
            return .disconnecting
        case .disconnected:
            fallthrough
        default:
            return .disconnected
        }
    }
}
