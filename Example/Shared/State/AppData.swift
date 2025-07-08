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
@preconcurrency import iOS_nRF_Memfault_Library

// MARK: - AppData

final class AppData: ObservableObject {
    
    // MARK: Public
    
    @Published var isScanning: Bool
    @Published var scannedDevices: [Device]
    @Published var error: ErrorEvent?
    
    // MARK: Private
    
    private let bluetooth: Bluetooth
    private lazy var manager = MemfaultManager()
    private lazy var log = NordicLog(Self.self)
    private lazy var scanningCancellables = Set<AnyCancellable>()
    
    // MARK: init
    
    init() {
        self.bluetooth = Bluetooth()
        self.isScanning = bluetooth.isScanning
        self.scannedDevices = []
        
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
            // Turn off.
            toggleScanner()
        }
        assert(!bluetooth.isScanning)
        scannedDevices = connectedDevices
        toggleScanner()
    }
    
    // MARK: Error
    
    func encounteredError(_ error: Error) {
        let errorEvent = ErrorEvent(error)
        log.error("\(errorEvent.localizedDescription)")
        Task { @MainActor in
            self.error = errorEvent
        }
    }
    
    // MARK: Scan
    
    func toggleScanner() {
        guard !bluetooth.isScanning else {
            // Turn off.
            bluetooth.toggleScanner()
            scanningCancellables.removeAll()
            return
        }

        let filters: [Bluetooth.ScannerFilter] = [.connectable]
        bluetooth.scan(with: filters)
            .map { (scanData: Bluetooth.ScanData) -> Device in
                let state = ConnectedState.from(scanData.peripheral.state)
                return Device(peripheral: scanData.peripheral, state: state, advertisementData: scanData.advertisementData, rssi: scanData.RSSI)
            }
            .receive(on: RunLoop.main)
            .sink { [weak self] device in
                if let i = self?.scannedDevices.firstIndex(where: \.uuidString, equals: device.uuidString) {
                    self?.scannedDevices[i].update(from: device.advertisementData)
                } else {
                    self?.scannedDevices.append(device)
                }
            }
            .store(in: &scanningCancellables)
    }
    
    // MARK: Connect
    
    func connect(to device: Device) {
        Task { @MainActor in
            if isScanning {
                bluetooth.toggleScanner()
            }
            
            updateDeviceConnectionState(of: device, to: .connecting)
            let connectionStream = await manager.connect(to: device)
            do {
                log.debug("STARTED Listening to \(device.name) Connection Events.")
                for try await newEvent in connectionStream {
                    log.debug("RECEIVED \(device.name) \(String(describing: newEvent)).")
                    switch newEvent.event {
                    case .connected:
                        updateDeviceConnectionState(of: device, to: .connected)
                    case .disconnected:
                        updateDeviceConnectionState(of: device, to: .disconnected)
                    case .notifications(let enabled):
                        updateNotifyingStatus(of: device, to: enabled)
                    case .streaming(let enabled):
                        updateStreamingStatus(of: device, to: enabled)
                    case .authenticated(let deviceAuth):
                        update(authData: deviceAuth, of: device)
                    case .updatedChunk(let chunk, status: let status):
                        received(chunk, from: device, with: status)
                    }
                }
                log.debug("STOPPED Listening to \(device.name) Connection Events.")
            } catch {
                log.debug("CAUGHT Error Listening to \(device.name) Connection Events.")
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
            log.debug("Successfully Sent Chunk \(chunk.sequenceNumber).")
        } catch {
            scannedDevices[i].chunks[j].status = .errorUploading
            log.error("Error Uploading Chunk \(chunk.sequenceNumber).")
            throw error
        }
    }
    
    // MARK: Disconnect
    
    func disconnect(from device: Device) {
        Task { @MainActor in
            log.info("Disconnecting from \(device.name)")
            updateDeviceConnectionState(of: device, to: .disconnecting)
            
            await manager.disconnect(from: device)
            
            log.info("Disconnected from \(device.name)")
            updateDeviceConnectionState(of: device, to: .disconnected)
        }
    }
}

@MainActor
private extension AppData {
    
    func updateDeviceConnectionState(of device: Device, to newState: ConnectedState) {
        guard let i = scannedDevices.firstIndex(where: \.uuidString, equals: device.uuidString) else { return
        }
        scannedDevices[i].connectionStateChanged(to: newState)
    }
    
    func received(_ chunk: MemfaultChunk, from device: Device, with status: MemfaultChunk.Status) {
        guard let i = scannedDevices.firstIndex(where: \.uuidString, equals: device.uuidString) else {
            return
        }
        scannedDevices[i].update(chunk, to: status)
    }
    
    func updateNotifyingStatus(of device: Device, to isNotifying: Bool) {
        guard let i = scannedDevices.firstIndex(where: \.uuidString, equals: device.uuidString) else {
            return
        }
        scannedDevices[i].notificationsEnabled = isNotifying
    }
    
    func updateStreamingStatus(of device: Device, to isStreaming: Bool) {
        guard let i = scannedDevices.firstIndex(where: \.uuidString, equals: device.uuidString) else {
            return
        }
        scannedDevices[i].streamingEnabled = isStreaming
    }
    
    func update(authData: MemfaultDeviceAuth, of device: Device) {
        guard let i = scannedDevices.firstIndex(where: \.uuidString, equals: device.uuidString) else {
            return
        }
        scannedDevices[i].auth = authData
    }
}
