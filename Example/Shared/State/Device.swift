//
//  Device.swift
//  nRF Memfault
//
//  Created by Dinesh Harjani on 3/8/22.
//

import Foundation
import CoreBluetooth

// MARK: - Device

struct Device: ScannerDevice, Identifiable {
    
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
    
    // MARK: Init
    
    init(name: String, uuid: UUID, rssi: RSSI, advertisementData: AdvertisementData) {
        self.name = name
        self.uuid = uuid.uuidString
        self.rssi = rssi
        self.advertisementData = advertisementData
        self.state = (advertisementData.isConnectable ?? false) ? .disconnected : .notConnectable
    }
    
    init(peripheral: CBPeripheral, advertisementData: [String: Any], rssi: NSNumber) {
        self.name = advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? "N/A"
        self.uuid = peripheral.identifier.uuidString
        self.rssi = RSSI(integerLiteral: rssi.intValue)
        let advertisementData = AdvertisementData(advertisementData)
        self.advertisementData = advertisementData
        self.state = (advertisementData.isConnectable ?? false) ? .disconnected : .notConnectable
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

// MARK: - Debug

#if DEBUG
extension Device {
    
    static let sample = Device(name: "Test Device", uuid: UUID(), rssi: .outOfRange, advertisementData: .connectableMock)
    static let unconnectableSample = Device(name: "#AlonsoAlpineAstonMartinPiastriRicciardoMclarenMess", uuid: UUID(), rssi: .outOfRange, advertisementData: .unconnectableMock)
}
#endif
