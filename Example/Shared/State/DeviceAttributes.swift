//
//  DeviceAttributes.swift
//  nRF Memfault
//
//  Created by Dinesh Harjani on 8/8/22.
//

import Foundation

struct DeviceService: BluetoothService {
    
    var uuid: String
    var characteristics: [BluetoothCharacteristic]
}

struct DeviceCharacteristic: BluetoothCharacteristic {
    
    var uuid: String
    var descriptors: [BluetoothDescriptor]
}

struct DeviceDescriptor: BluetoothDescriptor {
    
    var uuid: String
}
