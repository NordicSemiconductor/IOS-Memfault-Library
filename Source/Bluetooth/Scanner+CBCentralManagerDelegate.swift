//
//  Scanner+CBCentralManagerDelegate.swift
//  nRF Memfault
//
//  Created by Dinesh Harjani on 9/8/22.
//

import Foundation
import CoreBluetooth

// MARK: - CBCentralManagerDelegate

extension Scanner: CBCentralManagerDelegate {
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let isConnectable = (advertisementData[CBAdvertisementDataIsConnectable] as? NSNumber)?.boolValue
        if scanConditions.contains(where: { $0 == .connectable }) {
            if isConnectable ?? false {
                devicePublisher.send((peripheral, advertisementData, RSSI))
            }
        } else {
            devicePublisher.send((peripheral, advertisementData, RSSI))
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        managerState = central.state
        logger.info("Bluetooth changed state: \(central.state)")
        
        if central.state != .poweredOn {
            shouldScan = false
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        guard let continuation = continuations[peripheral.identifier.uuidString] else { return }
        continuation.resume(returning: peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        guard let continuation = continuations[peripheral.identifier.uuidString] else { return }
        continuation.resume(returning: peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        guard let continuation = continuations[peripheral.identifier.uuidString] else { return }
        if let error = error {
            continuation.resume(throwing: BluetoothError.coreBluetoothError(description: error.localizedDescription))
        } else {
            // Success.
            continuation.resume(returning: peripheral)
        }
    }
}
