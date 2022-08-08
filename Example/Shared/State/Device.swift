//
//  Device.swift
//  nRF Memfault
//
//  Created by Dinesh Harjani on 3/8/22.
//

import Foundation
import CoreBluetooth

// MARK: - Device

struct Device: Identifiable {
    
    // MARK: Properties
    
    var id: String {
        return uuid
    }
    
    var isConnectable: Bool {
        return state != .notConnectable
    }
    
    let name: String
    let uuid: String
    let rssi: RSSI
    let advertisementData: AdvertisementData
    var state: ConnectedState
    var services: [CBService]
    
    // MARK: Init
    
    init(name: String, uuid: UUID, rssi: RSSI, advertisementData: AdvertisementData) {
        self.name = advertisementData.localName ?? name
        self.uuid = uuid.uuidString
        self.rssi = rssi
        self.advertisementData = advertisementData
        self.state = (advertisementData.isConnectable ?? false) ? .disconnected : .notConnectable
        self.services = []
    }
    
    init(peripheral: CBPeripheral, state: ConnectedState, advertisementData: [String: Any], rssi: NSNumber) {
        let advertisementData = AdvertisementData(advertisementData)
        self.name = advertisementData.localName ?? (peripheral.name ?? "N/A")
        self.uuid = peripheral.identifier.uuidString
        self.rssi = RSSI(integerLiteral: rssi.intValue)
        self.advertisementData = advertisementData
        self.state = (advertisementData.isConnectable ?? false) ? state : .notConnectable
        self.services = []
    }
}

// MARK: - Equatable

extension Device: Equatable {

    public static func == (lhs: Device, rhs: CBPeripheral) -> Bool {
        return lhs.uuid == rhs.identifier.uuidString
    }

    public static func == (lhs: Device, rhs: Device) -> Bool {
        return lhs.uuid == rhs.uuid && lhs.state == rhs.state
    }
}

// MARK: - Hashable

extension Device: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
}

// MARK: ConnectedState

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

// MARK: - Debug

#if DEBUG
extension Device {
    
    static let sample = Device(name: "Test Device", uuid: UUID(), rssi: .outOfRange, advertisementData: .connectableMock)
    static let unconnectableSample = Device(name: "#AlonsoAlpineAstonMartinPiastriRicciardoMclarenMess", uuid: UUID(), rssi: .outOfRange, advertisementData: .unconnectableMock)
}
#endif
