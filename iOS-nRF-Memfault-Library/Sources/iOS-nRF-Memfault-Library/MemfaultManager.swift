//
//  MemfaultManager.swift
//  iOS-nRF-Memfault-Library
//
//  Created by Dinesh Harjani on 25/8/22.
//

import Foundation
import iOS_BLE_Library
import iOS_Common_Libraries
import CoreBluetooth
import Combine

// MARK: - Memfault

public final actor MemfaultManager {
    
    // MARK: Public
    
    public typealias AsyncMemfaultDeviceStreamValue = (deviceUUID: String, event: MemfaultDeviceEvent)
    public typealias AsyncMemfaultStream = AsyncThrowingStream<AsyncMemfaultDeviceStreamValue, Error>
    
    // MARK: Internal
    
    internal let bluetooth: Bluetooth
    internal let network: Network
    internal var devices: [String: MemfaultDevice]
    internal var deviceStreams: [String: AsyncMemfaultStream.Continuation]
    
    // MARK: Init
    
    public init() {
        self.bluetooth = Bluetooth()
        self.network = Network("chunks.memfault.com")
        self.devices = [String: MemfaultDevice]()
        self.deviceStreams = [String: AsyncMemfaultStream.Continuation]()
    }
    
    // MARK: Bluetooth
    
    @discardableResult
    public func connect<T: BluetoothDevice>(to device: T) -> AsyncMemfaultStream {
        if devices[device.uuidString] == nil {
            devices[device.uuidString] = MemfaultDevice(uuidString: device.uuidString)
        }
        
        let asyncMemfaultDeviceStream = AsyncMemfaultStream() { continuation in
            // To-Do: Is there a previous one?
            deviceStreams[device.uuidString] = continuation
        }
        
        Task {
            await connectAndAuthenticate(from: device)
        }
        return asyncMemfaultDeviceStream
    }
    
    public func disconnect<T: BluetoothDevice>(from device: T) {
        Task {
            guard let device = devices[device.uuidString] else { return }
            do {
                if device.isStreaming {
                    _ = try await bluetooth.writeCharacteristic(
                        Data(repeating: 0, count: 1), writeType: .withResponse, toCharacteristicWithUUID: .MDSDataExportCharacteristic, inServiceWithUUID: .MDS, from: device)
                    deviceStreams[device.uuidString]?.yield((device.uuidString, .streaming(false)))
                }
                
                if device.isNotifying {
                    _ = try await bluetooth.setNotify(false, toCharacteristicWithUUID: .MDSDataExportCharacteristic, inServiceWithUUID: .MDS, from: device)
                    deviceStreams[device.uuidString]?.yield((device.uuidString, .notifications(false)))
                }
                
                try await bluetooth.disconnect(from: device)
                deviceStreams[device.uuidString]?.yield((device.uuidString, .disconnected))
                deviceStreams[device.uuidString]?.finish()
            } catch {
                deviceStreams[device.uuidString]?.finish(throwing: error)
            }
        }
    }
    
    // MARK: Network
    
    public func upload(_ chunk: MemfaultChunk, with chunkAuth: MemfaultDeviceAuth) async throws {
        // If there's an error it'll be thrown and caught by the caller.
        for try await _ in network.perform(HTTPRequest.post(chunk, with: chunkAuth)).values {
            return
        }
    }
}
