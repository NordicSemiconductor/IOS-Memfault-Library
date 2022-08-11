//
//  AppData.swift
//  nRF Memfault
//
//  Created by Dinesh Harjani on 2/8/22.
//

import Foundation
import OSLog
import CoreBluetooth

final class AppData: ObservableObject {
    
    // MARK: Public
    
    @Published var isScanning: Bool
    @Published var scannedDevices: [Device]
    
    // MARK: Private
    
    private let scanner: Scanner
    private let logger: Logger
    
    // MARK: Init
    
    init() {
        self.scanner = Scanner()
        self.isScanning = scanner.isScanning
        self.scannedDevices = []
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
                    logger.error("MDS Service not found.")
                    logger.info("Disconnecting...")
                    disconnect(from: device)
                    return
                }
                
                logger.info("Discovering MDS' Characteristics...")
                let characteristics = try await scanner.discoverCharacteristics(ofService: mdsService.uuid.uuidString, ofDeviceWithUUID: device.uuidString)
                
                logger.info("Reading Data URI...")
                guard let uriData = try await scanner.readCharacteristic(withUUID: CBUUID.MDSDataURICharacteristic.uuidString, inServiceWithUUID: CBUUID.MDS.uuidString, from: device),
                      let uriString = String(data: uriData, encoding: .utf8),
                      let uriURL = URL(string: uriString) else {
//                    throw LocalizedError
                    return
                }
                
                logger.info("Reading Auth Data...")
                guard let authData = try await scanner.readCharacteristic(withUUID: CBUUID.MDSAuthCharacteristic.uuidString, inServiceWithUUID: CBUUID.MDS.uuidString, from: device),
                      let authString = String(data: authData, encoding: .utf8) else {
                    // throw Error
                    return
                }
                
            } catch {
                logger.error("\(error.localizedDescription)")
                logger.info("Disconnecting...")
                disconnect(from: device)
            }
        }
    }
    
    // MARK: Disconnect
    
    func disconnect(from device: Device) {
        Task {
            logger.info("Disconnecting from \(device.name)")
            await updateDeviceConnectionState(of: device, to: .disconnecting)
            do {
                try await scanner.disconnect(from: device)
                logger.info("Disconnected from \(device.name)")
                await updateDeviceConnectionState(of: device, to: .disconnected)
            } catch {
                logger.error("\(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Private

private extension CBUUID {
    
    static let MDS = CBUUID(string: "54220000-F6A5-4007-A371-722F4EBD8436")
    static let MDSDataURICharacteristic = CBUUID(string: "54220003-f6a5-4007-a371-722f4ebd8436")
    static let MDSAuthCharacteristic = CBUUID(string: "54220004-f6a5-4007-a371-722f4ebd8436")
}

@MainActor
private extension AppData {
    
    func updateDeviceConnectionState(of device: Device, to newState: ConnectedState) async {
        Task { @MainActor in
            guard let i = scannedDevices.firstIndex(where: { $0.uuidString == device.uuidString }) else { return }
            var connectionCopy = scannedDevices[i]
            connectionCopy.state = newState
            scannedDevices[i] = connectionCopy
        }
    }
}
