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
import iOSOtaLibrary

// MARK: - AppData

@MainActor
final class AppData: ObservableObject {
    
    // MARK: Public
    
    @Published var isScanning: Bool
    @Published var scannedDevices: [Device]
    @Published var error: ErrorEvent?
    
    // MARK: Private
    
    private let bluetooth: CentralManager
    private lazy var manager = ObservabilityManager()
    private lazy var log = NordicLog(Self.self)
    private lazy var scanningCancellables = Set<AnyCancellable>()
    
    // MARK: init
    
    init() {
        self.bluetooth = CentralManager()
        self.isScanning = false
        self.scannedDevices = []
    }
}

// MARK: - API

extension AppData {
    
    // MARK: UI
    
    func refresh() async {
        let connectedDevices = scannedDevices.filter({ $0.state == .connected })
        if isScanning {
            // Turn off.
            await toggleScanner()
        }
        assert(!isScanning)
        scannedDevices = connectedDevices
        await toggleScanner()
    }
    
    // MARK: Error
    
    func encounteredError(_ error: Error) {
        let errorEvent = ErrorEvent(error)
        log.error("\(errorEvent.localizedDescription)")
        self.error = errorEvent
    }
    
    // MARK: Scan
    
    func toggleScanner() async {
        guard !isScanning else {
            // Turn off.
            bluetooth.stopScan()
            scanningCancellables.removeAll()
            return
        }
        
        // Listen to Bluetooth @isScanning changes.
        bluetooth.isScanningChannel
            .assign(to: \.isScanning, on: self)
            .store(in: &scanningCancellables)
        
        // Start Scanning
        bluetooth.scanForPeripherals(withServices: nil)
            .filter { scanResult in
                scanResult.name != nil
            }
            .map { (scanResult: ScanResult) -> Device in
                let state = ConnectedState.from(scanResult.peripheral.state)
                return Device(peripheral: scanResult.peripheral, state: state,
                              advertisementData: scanResult.advertisementData, rssi: scanResult.rssi)
            }
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { _ in
                
            }, receiveValue: { [weak self] device in
                if let i = self?.scannedDevices.firstIndex(where: \.uuidString, equals: device.uuidString) {
                    self?.scannedDevices[i].update(from: device.advertisementData)
                } else {
                    self?.scannedDevices.append(device)
                }
            })
            .store(in: &scanningCancellables)
    }
    
    // MARK: Connect
    
    func connect(to device: Device) {
        Task { @MainActor in
            if isScanning {
                bluetooth.stopScan()
            }
            
            updateDeviceConnectionState(of: device, to: .connecting)
            let connectionStream = manager.connectToDevice(device.uuid)
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
                        update(\.notificationsEnabled, to: enabled, of: device)
                    case .online(let enabled):
                        update(\.online, to: enabled, of: device)
                    case .authenticated(let deviceAuth):
                        update(\.auth, to: deviceAuth, of: device)
                    case .updatedChunk(let chunk):
                        received(chunk, from: device)
                    }
                }
                log.debug("STOPPED Listening to \(device.name) Connection Events.")
            } catch {
                log.debug("CAUGHT Error Listening to \(device.name) Connection Events.")
                if let bluetoothError = error as? ObservabilityError, bluetoothError == .pairingError {
                    encounteredError(bluetoothError)
                    return
                }
                encounteredError(error)
                await disconnect(from: device)
            }
        }
    }
    
    // MARK: Upload
    
    func upload(_ chunk: ObservabilityChunk, from device: Device) async throws {
        guard let i = scannedDevices.firstIndex(where: { $0.uuidString == device.uuidString }),
              let j = scannedDevices[i].chunks.firstIndex(where: { $0.sequenceNumber == chunk.sequenceNumber && $0.data == chunk.data }) else {
            throw ObservabilityError.peripheralNotFound
        }
        
        scannedDevices[i].chunks[j].status = .uploading
        do {
            try manager.continuePendingUploads(for: device.id)
        } catch {
            scannedDevices[i].chunks[j].status = .pendingUpload
            log.error("Error Uploading Chunk \(chunk.sequenceNumber).")
            throw error
        }
    }
    
    // MARK: Disconnect
    
    func disconnect(from device: Device) async {
        log.info("Disconnecting from \(device.name)")
        updateDeviceConnectionState(of: device, to: .disconnecting)
        
        await manager.disconnect(from: device.uuid)
        updateDeviceConnectionState(of: device, to: .disconnected)
    }
}

@MainActor
private extension AppData {
    
    // MARK: updateDeviceConnectionState(of:to:)
    
    func updateDeviceConnectionState(of device: Device, to newState: ConnectedState) {
        guard let i = scannedDevices.firstIndex(where: \.uuidString, equals: device.uuidString) else { return
        }
        scannedDevices[i].connectionStateChanged(to: newState)
    }
    
    // MARK: update(:to:of:)
    
    func update<T>(_ key: WritableKeyPath<Device, T>, to value: T, of device: Device) {
        guard let i = scannedDevices.firstIndex(where: \.uuidString, equals: device.uuidString) else {
            return
        }
        scannedDevices[i][keyPath: key] = value
    }
    
    // MARK: received(:from:with:)
    
    func received(_ chunk: ObservabilityChunk, from device: Device) {
        guard let i = scannedDevices.firstIndex(where: \.uuidString, equals: device.uuidString) else {
            return
        }
        scannedDevices[i].update(chunk)
        guard chunk.status == .success else { return }
        update(\.online, to: true, of: device)
    }
}
