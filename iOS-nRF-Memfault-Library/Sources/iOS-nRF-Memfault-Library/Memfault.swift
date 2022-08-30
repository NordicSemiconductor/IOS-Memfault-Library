//
//  Memfault.swift
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

public final actor Memfault {
    
    // MARK: Public
    
    public typealias AsyncMemfaultDeviceStreamValue = (deviceUUID: String, event: MemfaultDeviceEvent)
    public typealias AsyncMemfaultStream = AsyncThrowingStream<AsyncMemfaultDeviceStreamValue, Error>
    
    // MARK: Private
    
    private let bluetooth: Bluetooth
    private let network: Network
    private var devices: [String: MemfaultDevice]
    private var deviceStreams: [String: AsyncMemfaultStream.Continuation]
    
    // MARK: Init
    
    public init() {
        self.bluetooth = Bluetooth()
        self.network = Network("chunks.memfault.com")
        self.devices = [String: MemfaultDevice]()
        self.deviceStreams = [String: AsyncMemfaultStream.Continuation]()
    }
    
    // MARK: Bluetooth
    
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

extension Memfault {
    
    private func connectAndAuthenticate<T: BluetoothDevice>(from device: T) async {
        do {
            try await bluetooth.connect(to: device)
            devices[device.uuidString]?.isConnected = true
            deviceStreams[device.uuidString]?.yield((device.uuidString, .connected))

            listenForNewChunks(from: device)

            let cbServices = try await bluetooth.discoverServices(of: device)
            guard let mdsService = cbServices.first(where: { $0.uuid == .MDS }) else {
                throw MemfaultError.mdsNotFound
            }

            try await bluetooth.discoverCharacteristics(ofService: mdsService.uuid.uuidString, ofDeviceWithUUID: device.uuidString)
            
            guard let uriData = try await bluetooth.readCharacteristic(withUUID: .MDSDataURICharacteristic, inServiceWithUUID: .MDS, from: device),
                  let uriString = String(data: uriData, encoding: .utf8),
                  let uriURL = URL(string: uriString) else {
                throw MemfaultError.unableToReadDeviceURI
            }

            guard let authData = try await bluetooth.readCharacteristic(withUUID: .MDSAuthCharacteristic, inServiceWithUUID: .MDS, from: device),
                  let authString = String(data: authData, encoding: .utf8)?.split(separator: ":") else {
                throw MemfaultError.unableToReadAuthData
            }
            let auth = MemfaultDeviceAuth(url: uriURL, authKey: String(authString[0]),
                                          authValue: String(authString[1]))
            devices[device.uuidString]?.auth = auth
            deviceStreams[device.uuidString]?.yield((device.uuidString, .authenticated(auth)))
            
//            for pendingChunk
            
            let setNotifyResult = try await bluetooth.setNotify(true, toCharacteristicWithUUID: .MDSDataExportCharacteristic, inServiceWithUUID: .MDS, from: device)
            devices[device.uuidString]?.isNotifying = setNotifyResult
            deviceStreams[device.uuidString]?.yield((device.uuidString, .notifications(setNotifyResult)))

            let writeResult = try await bluetooth.writeCharacteristic(Data(repeating: 1, count: 1), writeType: .withResponse, toCharacteristicWithUUID: .MDSDataExportCharacteristic, inServiceWithUUID: .MDS, from: device)
            devices[device.uuidString]?.isStreaming = true
            deviceStreams[device.uuidString]?.yield((device.uuidString, .streaming(true)))
        } catch {
            deviceStreams[device.uuidString]?.yield(with: .failure(error))
        }
    }
    
    // MARK: Upload
    
    private func listenForNewChunks<T: BluetoothDevice>(from device: T) {
        Task {
            guard let memfaultDevice = devices[device.uuidString] else {
                throw MemfaultError.mdsNotFound
            }
            
            for try await data in bluetooth.data(fromCharacteristicWithUUID: .MDSDataExportCharacteristic, inServiceWithUUID: .MDS, device: device) {
                guard let data = data else {
//                    throw MemfaultError.mdsNotFound
                    continue
                }
                
                let chunk = MemfaultChunk(data)
                deviceStreams[device.uuidString]?.yield((device.uuidString, .updatedChunk(chunk, status: .ready)))
                
                guard let chunksAuth = memfaultDevice.auth else {
                    throw MemfaultError.authDataNotFound
                }
                
                try await upload(chunk, with: chunksAuth, from: device)
            }
        }
    }
    
    private func upload<T: BluetoothDevice>(_ chunk: MemfaultChunk, with auth: MemfaultDeviceAuth, from device: T) async throws {
        do {
            deviceStreams[device.uuidString]?.yield((device.uuidString, .updatedChunk(chunk, status: .uploading)))
            try await upload(chunk, with: auth)
            deviceStreams[device.uuidString]?.yield((device.uuidString, .updatedChunk(chunk, status: .success)))
        } catch {
            deviceStreams[device.uuidString]?.yield((device.uuidString, .updatedChunk(chunk, status: .errorUploading)))
            disconnect(from: device)
        }
    }
}
