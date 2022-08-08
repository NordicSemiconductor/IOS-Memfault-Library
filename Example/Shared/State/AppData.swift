//
//  AppData.swift
//  nRF Memfault
//
//  Created by Dinesh Harjani on 2/8/22.
//

import Foundation

final class AppData: ObservableObject {
    
    // MARK: Public
    
    @Published var isScanning: Bool
    @Published var scannedDevices: [Device]
    
    // MARK: Private
    
    private let scanner: Scanner
    
    // MARK: Init
    
    init() {
        self.scanner = Scanner() { peripheral, state, advertisementData, RSSI in
            return Device(peripheral: peripheral, state: state, advertisementData: advertisementData,
                          rssi: RSSI)
        }
        self.isScanning = scanner.isScanning
        self.scannedDevices = []
        
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
            for await anyDevice in scanner.scan().values {
                guard let device = anyDevice as? Device, !scannedDevices.contains(device) else { continue }
                scannedDevices.append(device)
            }
        }
    }
    
    // MARK: Connect
    
    func connect(to device: Device) {
        Task {
            await updateDeviceConnectionState(of: device, to: .connecting)
            
            do {
                switch try await scanner.connect(to: device) {
                case .success(let newState):
                    await updateDeviceConnectionState(of: device, to: newState)
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    // MARK: Disconnect
    
    func disconnect(from device: Device) {
        Task {
            await updateDeviceConnectionState(of: device, to: .disconnecting)
            do {
                switch try await scanner.disconnect(from: device) {
                case .success(let newState):
                    await updateDeviceConnectionState(of: device, to: newState)
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}

// MARK: - Private

@MainActor
private extension AppData {
    
    func updateDeviceConnectionState(of device: Device, to newState: ConnectedState) async {
        Task { @MainActor in
            guard let i = scannedDevices.firstIndex(where: { $0.uuid == device.uuid }) else { return }
            var connectionCopy = scannedDevices[i]
            connectionCopy.state = newState
            scannedDevices[i] = connectionCopy
        }
    }
}
