//
//  AppData.swift
//  nRF Memfault
//
//  Created by Dinesh Harjani on 2/8/22.
//

import Foundation
import OSLog
import Combine
import iOS_BLE_Library
import iOS_Common_Libraries
import iOS_nRF_Memfault_Library

final class AppData: ObservableObject {
    
    // MARK: Public
    
    @Published var isScanning: Bool
    @Published var showOnlyMDSDevices: Bool {
        didSet {
            guard isScanning else { return }
            refresh()
        }
    }
    @Published var showOnlyConnectableDevices: Bool {
        didSet {
            guard isScanning else { return }
            refresh()
        }
    }
    
    @Published var scannedDevices: [Device]
    @Published var error: ErrorEvent?
    
    // MARK: Private
    
    private let bluetooth: Bluetooth
    private let manager: MemfaultManager
    private let logger: Logger
    
    // MARK: Init
    
    init() {
        self.bluetooth = Bluetooth()
        self.manager = MemfaultManager()
        self.isScanning = bluetooth.isScanning
        self.showOnlyMDSDevices = true
        self.showOnlyConnectableDevices = true
        self.scannedDevices = []
        self.logger = Logger(Self.self)
        
        _ = bluetooth.turnOnBluetoothRadio()
        Task { @MainActor in
            for await newValue in bluetooth.$isScanning.values {
                isScanning = newValue
            }
        }
    }
}

// MARK: - API

extension AppData {
    
    // MARK: UI
    
    func refresh() {
        let connectedDevices = scannedDevices.filter({ $0.state == .connected })
        if bluetooth.isScanning {
            toggleScanner()
        }
        assert(!bluetooth.isScanning)
        scannedDevices = connectedDevices
        toggleScanner()
    }
    
    // MARK: Error
    
    func encounteredError(_ error: Error) {
        let errorEvent = ErrorEvent(error)
        logger.error("\(errorEvent.localizedDescription)")
        Task { @MainActor in
            self.error = errorEvent
        }
    }
    
    // MARK: Scan
    
    func toggleScanner() {
        guard !bluetooth.isScanning else {
            bluetooth.toggleScanner()
            return
        }

        Task { @MainActor in
            var filters = [Bluetooth.ScannerFilter]()
            if showOnlyMDSDevices {
                filters.append(.matchingServiceUUID(.MDS))
            }
            if showOnlyConnectableDevices {
                filters.append(.connectable)
            }
            for await scanData in bluetooth.scan(with: filters).values {
                let state = ConnectedState.from(scanData.peripheral.state)
                let device = Device(peripheral: scanData.peripheral, state: state, advertisementData: scanData.advertisementData, rssi: scanData.RSSI)
                
                if let i = scannedDevices.firstIndex(where: { $0.uuidString == device.uuidString }) {
                    scannedDevices[i].update(from: scanData.advertisementData)
                } else {
                    scannedDevices.append(device)
                }
            }
        }
    }
    
    // MARK: Connect
    
    func connect(to device: Device) {
        Task { @MainActor in
            if isScanning {
                bluetooth.toggleScanner()
            }
            
            await updateDeviceConnectionState(of: device, to: .connecting)
            let connectionStream = await manager.connect(to: device)
            do {
                logger.debug("STARTED Listening to \(device.name) Connection Events.")
                for try await newEvent in connectionStream {
                    logger.debug("RECEIVED \(device.name) \(String(describing: newEvent)).")
                    switch newEvent.event {
                    case .connected:
                        await updateDeviceConnectionState(of: device, to: .connected)
                    case .disconnected:
                        await updateDeviceConnectionState(of: device, to: .disconnected)
                    case .notifications(let enabled):
                        await updateNotifyingStatus(of: device, to: enabled)
                    case .streaming(let enabled):
                        await updateStreamingStatus(of: device, to: enabled)
                    case .authenticated(let deviceAuth):
                        await update(authData: deviceAuth, of: device)
                    case .updatedChunk(let chunk, status: let status):
                        received(chunk, from: device, with: status)
                    }
                }
                logger.debug("STOPPED Listening to \(device.name) Connection Events.")
            } catch {
                logger.debug("CAUGHT Error Listening to \(device.name) Connection Events.")
                if let bluetoothError = error as? BluetoothError, bluetoothError == .pairingRequired {
                    encounteredError(bluetoothError)
                    return
                }
                encounteredError(error)
                disconnect(from: device)
            }
        }
    }
    
    // MARK: Upload
    
    @MainActor
    func upload(_ chunk: MemfaultChunk, from device: Device) async throws {
        guard let i = scannedDevices.firstIndex(where: { $0.uuidString == device.uuidString }),
              let j = scannedDevices[i].chunks.firstIndex(where: { $0.sequenceNumber == chunk.sequenceNumber && $0.data == chunk.data }),
              let chunkAuth = device.auth else {
            throw BluetoothError.cantRetrievePeripheral
        }
        
        scannedDevices[i].chunks[j].status = .uploading
        do {
            try await manager.upload(chunk, with: chunkAuth)
            scannedDevices[i].chunks[j].status = .success
            logger.debug("Successfully Sent Chunk \(chunk.sequenceNumber).")
        } catch {
            scannedDevices[i].chunks[j].status = .errorUploading
            logger.error("Error Uploading Chunk \(chunk.sequenceNumber).")
            throw error
        }
    }
    
    // MARK: Disconnect
    
    func disconnect(from device: Device) {
        Task { @MainActor in
            logger.info("Disconnecting from \(device.name)")
            await updateDeviceConnectionState(of: device, to: .disconnecting)
            
            await manager.disconnect(from: device)
            
            logger.info("Disconnected from \(device.name)")
            await updateDeviceConnectionState(of: device, to: .disconnected)
        }
    }
}

private extension AppData {
    
    func updateDeviceConnectionState(of device: Device, to newState: ConnectedState) async {
        Task { @MainActor in
            guard let i = scannedDevices.firstIndex(where: { $0.uuidString == device.uuidString }) else { return }
            scannedDevices[i].connectionStateChanged(to: newState)
        }
    }
    
    @MainActor
    func received(_ chunk: MemfaultChunk, from device: Device, with status: MemfaultChunk.Status) {
        guard let i = scannedDevices.firstIndex(where: { $0.uuidString == device.uuidString }) else {
            return
        }
        scannedDevices[i].update(chunk, to: status)
    }
    
    func updateNotifyingStatus(of device: Device, to isNotifying: Bool) async {
        Task { @MainActor in
            guard let i = scannedDevices.firstIndex(where: { $0.uuidString == device.uuidString }) else { return }
            scannedDevices[i].notificationsEnabled = isNotifying
        }
    }
    
    func updateStreamingStatus(of device: Device, to isStreaming: Bool) async {
        Task { @MainActor in
            guard let i = scannedDevices.firstIndex(where: { $0.uuidString == device.uuidString }) else { return }
            scannedDevices[i].streamingEnabled = isStreaming
        }
    }
    
    func update(authData: MemfaultDeviceAuth, of device: Device) async {
        Task { @MainActor in
            guard let i = scannedDevices.firstIndex(where: { $0.uuidString == device.uuidString }) else { return }
            scannedDevices[i].auth = authData
        }
    }
}
