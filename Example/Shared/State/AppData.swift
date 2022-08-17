//
//  AppData.swift
//  nRF Memfault
//
//  Created by Dinesh Harjani on 2/8/22.
//

import Foundation
import OSLog
import CoreBluetooth
import iOS_Common_Libraries

final class AppData: ObservableObject {
    
    // MARK: Public
    
    @Published var isScanning: Bool
    @Published var scannedDevices: [Device]
    @Published var openDevice: Device?
    @Published var error: ErrorEvent?
    
    // MARK: Private
    
    private let scanner: Scanner
    private let logger: Logger
    
    // MARK: Init
    
    init() {
        self.scanner = Scanner()
        self.isScanning = scanner.isScanning
        self.scannedDevices = []
        self.openDevice = nil
        self.logger = Logger(Self.self)
        
        _ = scanner.turnOnBluetoothRadio()
        Task { @MainActor in
            for await newValue in scanner.$isScanning.values {
                isScanning = newValue
            }
        }
    }
}

// MARK: - API

extension AppData {
    
    // MARK: Refresh
    
    func refresh() {
        scannedDevices.removeAll()
        guard !scanner.isScanning else { return }
        toggleScanner()
    }
    
    // MARK: Scan
    
    func toggleScanner() {
        guard !scanner.isScanning else {
            scanner.toggle()
            return
        }

        Task { @MainActor in
            for await scanData in scanner.scan().values {
                let state = ConnectedState.from(scanData.peripheral.state)
                let device = Device(peripheral: scanData.peripheral, state: state, advertisementData: scanData.advertisementData, rssi: scanData.RSSI)
                
                if let i = scannedDevices.firstIndex(of: device) {
                    scannedDevices[i].update(from: scanData.advertisementData)
                } else {
                    scannedDevices.append(device)
                }
            }
        }
    }
    
    // MARK: Connect
    
    func connect(to device: Device) {
        Task {
            await updateDeviceConnectionState(of: device, to: .connecting)
            
            do {
                try await scanner.connect(to: device)
                logger.info("Connecting to \(device.name)")
                await updateDeviceConnectionState(of: device, to: .connected)
                logger.info("Connected to \(device.name)")
                logger.info("Discovering \(device.name)'s Services...")
                let cbServices = try await scanner.discoverServices(of: device)
                
                guard let mdsService = cbServices.first(where: { $0.uuid == .MDS }) else {
                    throw AppError.mdsNotFound
                }
                
                logger.info("Discovering MDS' Characteristics...")
                let characteristics = try await scanner.discoverCharacteristics(ofService: mdsService.uuid.uuidString, ofDeviceWithUUID: device.uuidString)
                
                logger.info("Reading Device Identifier...")
                guard let uriData = try await scanner.readCharacteristic(withUUID: .MDSDeviceIdentifierCharacteristic, inServiceWithUUID: .MDS, from: device),
                      let deviceIdentifierString = String(data: uriData, encoding: .utf8) else {
                    throw AppError.unableToReadDeviceIdentifier
                }
                logger.debug("Device Identifier: \(deviceIdentifierString)")
                
                logger.info("Reading Data URI...")
                guard let uriData = try await scanner.readCharacteristic(withUUID: .MDSDataURICharacteristic, inServiceWithUUID: .MDS, from: device),
                      let uriString = String(data: uriData, encoding: .utf8),
                      let uriURL = URL(string: uriString) else {
                    throw AppError.unableToReadDeviceURI
                }
                logger.debug("Data URI: \(uriURL.absoluteString)")
                
                logger.info("Reading Auth Data...")
                guard let authData = try await scanner.readCharacteristic(withUUID: .MDSAuthCharacteristic, inServiceWithUUID: .MDS, from: device),
                      let authString = String(data: authData, encoding: .utf8) else {
                    throw AppError.unableToReadAuthData
                }
                logger.debug("Auth Data: \(authString)")
                
                let isNotifying = try await scanner.setNotify(true, toCharacteristicWithUUID: .MDSDataExportCharacteristic, inServiceWithUUID: .MDS, from: device)
                await updateNotifyingStatus(of: device, to: isNotifying)
                
                logger.debug("setNotify: \(isNotifying)")
                
                let writeResult = try await scanner.writeCharacteristic(Data(repeating: 1, count: 1), writeType: .withResponse, toCharacteristicWithUUID: .MDSDataExportCharacteristic, inServiceWithUUID: .MDS, from: device)
                logger.debug("Write Enable Result: \(writeResult ?? Data())")
                await updateStreamingStatus(of: device, to: true)
                
                openDevice = device
            } catch {
                await encounteredError(error)
                disconnect(from: device)
            }
        }
    }
    
    // MARK: Disconnect
    
    func disconnect(from device: Device) {
        Task {
            logger.info("Disconnecting from \(device.name)")
            await updateDeviceConnectionState(of: device, to: .disconnecting)
            
            if device.streamingEnabled {
                logger.debug("Disabling Streaming from \(device.name).")
                _ = try await scanner.writeCharacteristic(
                    Data(repeating: 0, count: 0), writeType: .withResponse, toCharacteristicWithUUID: .MDSDataExportCharacteristic, inServiceWithUUID: .MDS, from: device)
                await updateNotifyingStatus(of: device, to: false)
            }
            
            if device.notificationsEnabled {
                logger.debug("Turning Off Notifications from \(device.name).")
                _ = try await scanner.setNotify(false, toCharacteristicWithUUID: .MDSDataExportCharacteristic, inServiceWithUUID: .MDS, from: device)
                await updateStreamingStatus(of: device, to: false)
            }
            
            do {
                try await scanner.disconnect(from: device)
                logger.info("Disconnected from \(device.name)")
                await updateDeviceConnectionState(of: device, to: .disconnected)
            } catch {
                logger.error("\(error.localizedDescription)")
                await updateDeviceConnectionState(of: device, to: .disconnected)
            }
        }
    }
}

// MARK: - Private

private extension CBUUID {
    
    static let MDS = CBUUID(string: "54220000-F6A5-4007-A371-722F4EBD8436")
    static let MDSDeviceIdentifierCharacteristic = CBUUID(string: "54220002-f6a5-4007-a371-722f4ebd8436")
    static let MDSDataURICharacteristic = CBUUID(string: "54220003-f6a5-4007-a371-722f4ebd8436")
    static let MDSAuthCharacteristic = CBUUID(string: "54220004-f6a5-4007-a371-722f4ebd8436")
    static let MDSDataExportCharacteristic = CBUUID(string: "54220005-f6a5-4007-a371-722f4ebd8436")
}

@MainActor
private extension AppData {
    
    func updateDeviceConnectionState(of device: Device, to newState: ConnectedState) async {
        Task { @MainActor in
            guard let i = scannedDevices.firstIndex(where: { $0.uuidString == device.uuidString }) else { return }
            scannedDevices[i].connectionStateChanged(to: newState)
        }
    }
    
    func updateNotifyingStatus(of device: Device, to isNotifying: Bool) async {
        Task { @MainActor in
            guard let i = scannedDevices.firstIndex(where: { $0.uuidString == device.uuidString }) else { return }
            scannedDevices[i].updateNotifyingStatus(to: isNotifying)
        }
    }
    
    func updateStreamingStatus(of device: Device, to isStreaming: Bool) async {
        Task { @MainActor in
            guard let i = scannedDevices.firstIndex(where: { $0.uuidString == device.uuidString }) else { return }
            scannedDevices[i].updateStreamingStatus(to: isStreaming)
        }
    }
    
    func encounteredError(_ error: Error) async {
        let errorEvent = ErrorEvent(error)
        logger.error("\(errorEvent.localizedDescription)")
        Task { @MainActor in
            self.error = errorEvent
        }
    }
}
