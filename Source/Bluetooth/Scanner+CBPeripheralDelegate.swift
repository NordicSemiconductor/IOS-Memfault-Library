//
//  Scanner+CBPeripheralDelegate.swift
//  nRF Memfault
//
//  Created by Dinesh Harjani on 9/8/22.
//

import Foundation
import CoreBluetooth

// MARK: - CBPeripheralDelegate

extension Scanner: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let continuation = continuations[peripheral.identifier.uuidString] else { return }
        if let error = error {
            continuation.resume(throwing: BluetoothError.coreBluetoothError(description: error.localizedDescription))
        } else {
            // Success.
            continuation.resume(returning: peripheral)
        }
    }
}
