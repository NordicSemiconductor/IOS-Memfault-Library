//
//  MemfaultManager+Internal.swift
//  iOS-nRF-Memfault-Library
//
//  Created by Dinesh Harjani on 30/8/22.
//

import Foundation
import iOS_BLE_Library

// MARK: - Internal

extension MemfaultManager {
    
    // MARK: Connection
    
    func connectAndAuthenticate<T: BluetoothDevice>(from device: T) async {
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
            
            let setNotifyResult = try await bluetooth.setNotify(true, toCharacteristicWithUUID: .MDSDataExportCharacteristic, inServiceWithUUID: .MDS, from: device)
            devices[device.uuidString]?.isNotifying = setNotifyResult
            deviceStreams[device.uuidString]?.yield((device.uuidString, .notifications(setNotifyResult)))

            let writeResult = try await bluetooth.writeCharacteristic(Data(repeating: 1, count: 1), writeType: .withResponse, toCharacteristicWithUUID: .MDSDataExportCharacteristic, inServiceWithUUID: .MDS, from: device)
            devices[device.uuidString]?.isStreaming = true
            deviceStreams[device.uuidString]?.yield((device.uuidString, .streaming(true)))
            
            guard let leftoverChunkData = writeResult else { return }
            
            let leftoverChunk = MemfaultChunk(leftoverChunkData)
            received(leftoverChunk, from: device)
            try await upload(leftoverChunk, with: auth, from: device)
        } catch {
            deviceStreams[device.uuidString]?.yield(with: .failure(error))
        }
    }
    
    func received<T: BluetoothDevice>(_ chunk: MemfaultChunk, from device: T) {
        devices[device.uuidString]?.chunks.append(chunk)
        deviceStreams[device.uuidString]?.yield((device.uuidString, .updatedChunk(chunk, status: .ready)))
    }
    
    // MARK: Upload
    
    func listenForNewChunks<T: BluetoothDevice>(from device: T) {
        Task {
            var auth: MemfaultDeviceAuth!
            do {
                for try await data in bluetooth.data(fromCharacteristicWithUUID: .MDSDataExportCharacteristic, inServiceWithUUID: .MDS, device: device) {
                    guard let data = data else { continue }
                    
                    let chunk = MemfaultChunk(data)
                    received(chunk, from: device)
                    
                    if auth == nil {
                        auth = devices[device.uuidString]?.auth
                    }
                    
                    guard let chunksAuth = auth else {
                        throw MemfaultError.authDataNotFound
                    }
                    try await upload(chunk, with: chunksAuth, from: device)
                }
            } catch let bluetoothError as BluetoothError {
                switch bluetoothError {
                case .unexpectedDeviceDisconnection(description: _):
                    deviceStreams[device.uuidString]?.yield((device.uuidString, .notifications(false)))
                    deviceStreams[device.uuidString]?.yield((device.uuidString, .streaming(false)))
                    fallthrough
                default:
                    deviceStreams[device.uuidString]?.yield(with: .failure(bluetoothError))
                    disconnect(from: device)
                }
            } catch {
                deviceStreams[device.uuidString]?.yield(with: .failure(error))
                disconnect(from: device)
            }
        }
    }
    
    func upload<T: BluetoothDevice>(_ chunk: MemfaultChunk, with auth: MemfaultDeviceAuth, from device: T) async throws {
        
        guard let i = devices[device.uuidString]?.chunks.firstIndex(where: {
            $0.sequenceNumber == chunk.sequenceNumber && $0.data == chunk.data
        }) else { return }
        
        do {
            devices[device.uuidString]?.chunks[i].status = .uploading
            deviceStreams[device.uuidString]?.yield((device.uuidString, .updatedChunk(chunk, status: .uploading)))
            try await upload(chunk, with: auth)
            devices[device.uuidString]?.chunks[i].status = .success
            deviceStreams[device.uuidString]?.yield((device.uuidString, .updatedChunk(chunk, status: .success)))
        } catch {
            devices[device.uuidString]?.chunks[i].status = .errorUploading
            deviceStreams[device.uuidString]?.yield((device.uuidString, .updatedChunk(chunk, status: .errorUploading)))
            disconnect(from: device)
        }
    }
}
