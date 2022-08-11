//
//  Device.swift
//  nRF Memfault
//
//  Created by Dinesh Harjani on 3/8/22.
//

import Foundation
import CoreBluetooth

// MARK: - Device

struct Device: Identifiable, ScannerDevice {
    
    // MARK: Properties
    
    var id: String {
        return uuidString
    }
    
    var isConnectable: Bool {
        return state != .notConnectable
    }
    
    private(set) var name: String
    let uuidString: String
    let rssi: RSSI
    let advertisementData: AdvertisementData
    var state: ConnectedState
    var services: [CBService]
    
    // MARK: Init
    
    init(name: String, uuid: UUID, rssi: RSSI, advertisementData: AdvertisementData,
         state: ConnectedState? = nil) {
        self.name = advertisementData.localName ?? name
        self.uuidString = uuid.uuidString
        self.rssi = rssi
        self.advertisementData = advertisementData
        self.state = state ?? ((advertisementData.isConnectable ?? false) ? .disconnected : .notConnectable)
        self.services = []
    }
    
    init(peripheral: CBPeripheral, state: ConnectedState, advertisementData: [String: Any], rssi: NSNumber) {
        let advertisementData = AdvertisementData(advertisementData)
        self.name = advertisementData.localName ?? (peripheral.name ?? "N/A")
        self.uuidString = peripheral.identifier.uuidString
        self.rssi = RSSI(integerLiteral: rssi.intValue)
        self.advertisementData = advertisementData
        self.state = (advertisementData.isConnectable ?? false) ? state : .notConnectable
        self.services = []
    }
    
    // MARK: API
    
    mutating func update(from advertisingData: [String: Any]) {
        self.name = advertisementData.localName ?? name
    }
}

// MARK: - Equatable

extension Device: Equatable {

    public static func == (lhs: Device, rhs: CBPeripheral) -> Bool {
        return lhs.uuidString == rhs.identifier.uuidString
    }

    public static func == (lhs: Device, rhs: Device) -> Bool {
        return lhs.uuidString == rhs.uuidString && lhs.state == rhs.state
    }
}

// MARK: - Hashable

extension Device: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuidString)
        hasher.combine(state)
    }
}

// MARK: ConnectedState

public enum ConnectedState: Int, CaseIterable {
    
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

// MARK: - Debug

#if DEBUG
extension Device {
    
    static func sample(for connectedState: ConnectedState) -> Device {
        switch connectedState {
        case .notConnectable:
            return Device(name: "#AlonsoAlpineAstonMartinPiastriRicciardoMclarenMess", uuid: UUID(), rssi: .outOfRange, advertisementData: .unconnectableMock)
        case .connecting, .connected, .disconnecting, .disconnected:
            return Device(name: "Test Device", uuid: UUID(), rssi: .outOfRange, advertisementData: .connectableMock, state: connectedState)
        }
    }
}
#endif
