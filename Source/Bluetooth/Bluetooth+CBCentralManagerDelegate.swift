//
//  Bluetooth+CBCentralManagerDelegate.swift
//  nRF Memfault
//
//  Created by Dinesh Harjani on 9/8/22.
//

import Foundation
import CoreBluetooth

// MARK: - CBCentralManagerDelegate

extension Bluetooth: CBCentralManagerDelegate {
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let isConnectable = (advertisementData[CBAdvertisementDataIsConnectable] as? NSNumber)?.boolValue
        if conditions.contains(where: { $0 == .connectable }) {
            if isConnectable ?? false {
                devicePublisher.send((peripheral, advertisementData, RSSI))
            }
        } else {
            devicePublisher.send((peripheral, advertisementData, RSSI))
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        logger.debug("[Callback] centralManagerDidUpdateState(central: \(central))")
        managerState = central.state
        logger.info("Bluetooth changed state: \(central.state)")
        
        if central.state != .poweredOn {
            shouldScan = false
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        logger.debug("[Callback] centralManager(central: \(central), didConnect: \(peripheral))")
        connectedStreams[peripheral.identifier.uuidString] = [AsyncThrowingStream<AsyncStreamValue, Error>.Continuation]()
        guard case .connection(let continuation)? = continuations[peripheral.identifier.uuidString] else { return }
        continuation.resume(returning: peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        logger.debug("[Callback] centralManager(central: \(central), didFailToConnect: \(peripheral), error: \(error.debugDescription))")
        guard case .connection(let continuation)? = continuations[peripheral.identifier.uuidString] else { return }
        if let error = error {
            let rethrow = BluetoothError.coreBluetoothError(description: error.localizedDescription)
            continuation.resume(throwing: rethrow)
            connectedStreams[peripheral.identifier.uuidString]?.forEach {
                $0.finish(throwing: rethrow)
            }
        } else {
            // Success.
            continuation.resume(returning: peripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        logger.debug("[Callback] centralManager(central: \(central), didDisconnectPeripheral: \(peripheral), error: \(error.debugDescription))")
        guard case .connection(let continuation)? = continuations[peripheral.identifier.uuidString] else { return }
        if let error = error {
            let rethrow = BluetoothError.coreBluetoothError(description: error.localizedDescription)
            continuation.resume(throwing: rethrow)
            connectedStreams[peripheral.identifier.uuidString]?.forEach {
                $0.finish(throwing: rethrow)
            }
        } else {
            // Success.
            connectedStreams[peripheral.identifier.uuidString]?.forEach {
                $0.finish()
            }
            continuation.resume(returning: peripheral)
        }
    }
}