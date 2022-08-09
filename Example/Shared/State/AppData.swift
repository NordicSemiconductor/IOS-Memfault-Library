//
//  AppData.swift
//  nRF Memfault
//
//  Created by Dinesh Harjani on 2/8/22.
//

import Foundation
import OSLog

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
                guard !scannedDevices.contains(device) else { continue }
                scannedDevices.append(device)
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
                for service in cbServices {
                    logger.info("Discovered Service \(service.uuid)")
                }
            } catch {
                logger.error("\(error.localizedDescription)")
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
