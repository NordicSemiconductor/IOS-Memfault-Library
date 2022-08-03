//
//  AdvertisementData.swift
//  nRF Memfault
//
//  Created by Nick Kibysh on 25/03/2021.
//  Created by Dinesh Harjani on 3/8/22.
//

import Foundation
import CoreBluetooth

struct AdvertisementData {
    
    // MARK: - Properties
    
    let localName: String? // CBAdvertisementDataLocalNameKey
    let manufacturerData: Data? // CBAdvertisementDataManufacturerDataKey
    let serviceData: [CBUUID : Data]? // CBAdvertisementDataServiceDataKey
    let serviceUUIDs: [CBUUID]? // CBAdvertisementDataServiceUUIDsKey
    let overflowServiceUUIDs: [CBUUID]? // CBAdvertisementDataOverflowServiceUUIDsKey
    let txPowerLevel: Int? // CBAdvertisementDataTxPowerLevelKey
    let isConnectable: Bool? // CBAdvertisementDataIsConnectable
    let solicitedServiceUUIDs: [CBUUID]? // CBAdvertisementDataSolicitedServiceUUIDsKey
    
    // MARK: - Init
    
    init() {
        self.init([:])
    }
    
    init(_ advertisementData: [String : Any]) {
        localName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data
        serviceData = advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID : Data]
        serviceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]
        overflowServiceUUIDs = advertisementData[CBAdvertisementDataOverflowServiceUUIDsKey] as? [CBUUID]
        txPowerLevel = (advertisementData[CBAdvertisementDataTxPowerLevelKey] as? NSNumber)?.intValue
        isConnectable = (advertisementData[CBAdvertisementDataIsConnectable] as? NSNumber)?.boolValue
        solicitedServiceUUIDs = advertisementData[CBAdvertisementDataSolicitedServiceUUIDsKey] as? [CBUUID]
    }
    
    // MARK: - Advertised ID (MAC Address)
    
    private static let ExpectedManufacturerDataPrefix: UInt8 = 225
    
    func advertisedID() -> String? {
        guard let data = manufacturerData, data.count > 4 else { return nil }
        var advData = data.suffix(from: 2) // Skip 'Nordic' Manufacturer Code
        guard advData.removeFirst() == Self.ExpectedManufacturerDataPrefix else { return nil }
        return advData.hexEncodedString(separator: ":").uppercased()
    }
}

// MARK: - hexEncodedString()

fileprivate extension Data {
    
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }
    
    func hexEncodedString(options: HexEncodingOptions = [], separator: String = "") -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return self
            .map { String(format: format, $0) }
            .joined(separator: separator)
    }
}

// MARK: - Debug

#if DEBUG
extension AdvertisementData {
    
    static var connectableMock: AdvertisementData {
        AdvertisementData(
            [
                CBAdvertisementDataLocalNameKey : "iPhone 13",
                CBAdvertisementDataIsConnectable : true as NSNumber
            ]
        )
    }
    
    static var unconnectableMock: AdvertisementData {
        AdvertisementData(
            [
                CBAdvertisementDataLocalNameKey : "iPhone 14",
                CBAdvertisementDataIsConnectable : false as NSNumber
            ]
        )
    }
}
#endif
