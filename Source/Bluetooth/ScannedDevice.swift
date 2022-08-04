//
//  ScannedDevice.swift
//  nRF Memfault
//
//  Created by Dinesh Harjani on 8/3/21.
//  Created by Dinesh Harjani on 3/8/22.
//

import Foundation
import CoreBluetooth

public struct ScannedDevice: Identifiable {
    
    // MARK: Properties
    
    public var id: String {
        return uuid
    }
    
    public let name: String
    public let uuid: String
    public let rssi: RSSI
    public let advertisementData: AdvertisementData
    public let isConnectable: Bool
    
    // MARK: Init
    
    init(name: String, uuid: UUID, rssi: RSSI, advertisementData: AdvertisementData) {
        self.name = name
        self.uuid = uuid.uuidString
        self.rssi = rssi
        self.advertisementData = advertisementData
        self.isConnectable = advertisementData.isConnectable ?? false
    }
    
    init(peripheral: CBPeripheral, advertisementData: [String: Any], rssi: NSNumber) {
        self.name = advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? "N/A"
        self.uuid = peripheral.identifier.uuidString
        self.rssi = RSSI(integerLiteral: rssi.intValue)
        let advertisementData = AdvertisementData(advertisementData)
        self.advertisementData = advertisementData
        self.isConnectable = advertisementData.isConnectable ?? false
    }
}

// MARK: - Equatable

extension ScannedDevice: Equatable {

    public static func == (lhs: ScannedDevice, rhs: CBPeripheral) -> Bool {
        return lhs.uuid == rhs.identifier.uuidString
    }

    public static func == (lhs: ScannedDevice, rhs: ScannedDevice) -> Bool {
        return lhs.uuid == rhs.uuid
    }
}

// MARK: - Hashable

extension ScannedDevice: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuid)
    }
}

// MARK: - Debug

#if DEBUG
extension ScannedDevice {
    
    static let sample = ScannedDevice(name: "Test Device", uuid: UUID(), rssi: .outOfRange, advertisementData: .connectableMock)
    static let unconnectableSample = ScannedDevice(name: "#AlonsoAlpineAstonMartinPiastriRicciardoMclarenMess", uuid: UUID(), rssi: .outOfRange, advertisementData: .unconnectableMock)
}
#endif
