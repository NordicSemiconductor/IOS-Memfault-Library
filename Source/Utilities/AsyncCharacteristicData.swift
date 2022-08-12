//
//  AsyncCharacteristicData.swift
//  nRF Memfault
//
//  Created by Dinesh Harjani on 12/8/22.
//

import Foundation
import CoreBluetooth

typealias AsyncStreamValue = (characteristic: CBCharacteristic, data: Data?)

struct AsyncCharacteristicData: AsyncSequence, AsyncIteratorProtocol {
    typealias Element = Data?
    
    let serviceUUID: String
    let characteristicUUID: String
    let stream: AsyncThrowingStream<AsyncStreamValue, Error>

    func makeAsyncIterator() -> AsyncCharacteristicData {
        self
    }
    
    mutating func next() async throws -> Element? {
        for try await newValue in stream {
            guard newValue.characteristic.uuid.uuidString == characteristicUUID,
                  let service = newValue.characteristic.service,
                  service.uuid.uuidString == serviceUUID else { continue }
            return newValue.data
        }
        return nil
    }
}
