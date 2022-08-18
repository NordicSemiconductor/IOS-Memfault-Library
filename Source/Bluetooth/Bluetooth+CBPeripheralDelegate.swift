//
//  Bluetooth+CBPeripheralDelegate.swift
//  nRF Memfault
//
//  Created by Dinesh Harjani on 9/8/22.
//

import Foundation
import CoreBluetooth

// MARK: - CBPeripheralDelegate

extension Bluetooth: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        logger.debug("[Callback] peripheral(peripheral: \(peripheral), didDiscoverServices error: \(error.debugDescription))")
        guard case .connection(let continuation)? = continuations[peripheral.identifier.uuidString] else { return }
        if let error = error {
            continuation.resume(throwing: BluetoothError.coreBluetoothError(description: error.localizedDescription))
        } else {
            // Success.
            continuation.resume(returning: peripheral)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        logger.debug("[Callback] peripheral(peripheral: \(peripheral), didDiscoverCharacteristicsFor: \(service), error: \(error.debugDescription))")
        guard case .updatedService(let continuation)? = continuations[peripheral.identifier.uuidString] else { return }
        if let error = error {
            continuation.resume(throwing: BluetoothError.coreBluetoothError(description: error.localizedDescription))
        } else {
            // Success.
            continuation.resume(returning: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        logger.debug("[Callback] peripheral(peripheral: \(peripheral), didWriteValueFor: \(characteristic), error: \(error.debugDescription))")
        guard case .attribute(let continuation)? = continuations[peripheral.identifier.uuidString] else { return }
        if let error = error {
            continuation.resume(throwing: BluetoothError.coreBluetoothError(description: error.localizedDescription))
        } else {
            continuation.resume(returning: characteristic.value)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        logger.debug("[Callback] peripheral(peripheral: \(peripheral), didUpdateNotificationStateFor: \(characteristic), error: \(error.debugDescription))")
        guard case .notificationChange(let continuation)? = continuations[peripheral.identifier.uuidString] else { return }
        if let error = error {
            continuation.resume(throwing: BluetoothError.coreBluetoothError(description: error.localizedDescription))
        } else {
            continuation.resume(returning: characteristic.isNotifying)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        logger.debug("[Callback] peripheral(peripheral: \(peripheral), didUpdateValueFor: \(characteristic), error: \(error.debugDescription))")
        if let error = error {
            let rethrow = BluetoothError.coreBluetoothError(description: error.localizedDescription)
            connectedStreams[peripheral.identifier.uuidString]?.forEach {
                $0.finish(throwing: rethrow)
            }
        } else {
            connectedStreams[peripheral.identifier.uuidString]?.forEach {
                $0.yield((characteristic, characteristic.value))
            }
        }
    }
}
