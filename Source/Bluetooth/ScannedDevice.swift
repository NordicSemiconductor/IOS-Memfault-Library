//
//  ScannedDevice.swift
//  nRF Memfault
//
//  Created by Dinesh Harjani on 8/3/21.
//  Created by Dinesh Harjani on 3/8/22.
//

import Foundation
import CoreBluetooth

struct ScannedDevice: Identifiable {
    
    // MARK: Properties
    
    let name: String
    let id: String
    let uuid: UUID
    let rssi: RSSI
    let advertisementData: AdvertisementData
    let isConnectable: Bool
    
    // MARK: Init
    
    init(name: String, uuid: UUID, rssi: RSSI, advertisementData: AdvertisementData) {
        self.name = name
        self.id = advertisementData.advertisedID() ?? uuid.uuidString
        self.uuid = uuid
        self.rssi = rssi
        self.advertisementData = advertisementData
        self.isConnectable = advertisementData.isConnectable ?? false
    }
    
    init(peripheral: CBPeripheral, advertisementData: [String: Any], rssi: NSNumber) {
        self.name = advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? "N/A"
        let advertisementData = AdvertisementData(advertisementData)
        self.advertisementData = advertisementData
        self.rssi = RSSI(integerLiteral: rssi.intValue)
        self.id = advertisementData.advertisedID() ?? peripheral.identifier.uuidString
        self.uuid = peripheral.identifier
        self.isConnectable = advertisementData.isConnectable ?? false
    }
    
    static func == (lhs: ScannedDevice, rhs: ScannedDevice) -> Bool {
        return lhs.id == rhs.id && lhs.isConnectable == rhs.isConnectable
    }
}
