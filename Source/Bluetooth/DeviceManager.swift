//
//  DeviceManager.swift
//  nRF Memfault
//
//  Created by Nick Kibysh on 24/03/2021.
//  Created by Dinesh Harjani on 2/8/22.
//

import Foundation
import CoreBluetooth
import os
import Combine

// MARK: - DeviceManager

final class DeviceManager: NSObject, ObservableObject {
    
}

// MARK: - CBPeripheralDelegate

extension DeviceManager: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Swift.Error?) {
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Swift.Error?) {
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Swift.Error?) {
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Swift.Error?) {
        
    }
}
