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
    var services: [BluetoothService] { get set }
}

// MARK: - Attribute(s)

public protocol DeviceAttribute {
    
    var uuid: String { get }
}

public protocol BluetoothService: DeviceAttribute {
    
    var characteristics: [BluetoothCharacteristic] { get set }
}

public protocol BluetoothCharacteristic: DeviceAttribute {
    
    var descriptors: [BluetoothDescriptor] { get set }
}

public protocol BluetoothDescriptor: DeviceAttribute {
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
