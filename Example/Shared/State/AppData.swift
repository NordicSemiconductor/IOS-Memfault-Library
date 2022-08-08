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
    
    func refresh() {
        scannedDevices.removeAll()
        guard !scanner.isScanning else { return }
        toggleScanner()
    }
    
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
    
    func connect(to device: Device) {
        guard let i = scannedDevices.firstIndex(of: device) else { return }
        var copy = scannedDevices[i]
        copy.state = .connecting
        scannedDevices[i] = copy
        
        Task { @MainActor in
            do {
                switch try await scanner.connect(to: device) {
                case .success(let a):
                    var connectionCopy = scannedDevices[i]
                    connectionCopy.state = a ? .connected : .disconnected
                    scannedDevices[i] = connectionCopy
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func disconnect(from device: Device) {
        guard let i = scannedDevices.firstIndex(of: device) else { return }
        var copy = scannedDevices[i]
        copy.state = .disconnecting
        scannedDevices[i] = copy
        
        Task { @MainActor in
            do {
                switch try await scanner.disconnect(from: device) {
                case .success(let a):
                    var connectionCopy = scannedDevices[i]
                    connectionCopy.state = a ? .disconnected : .connected
                    scannedDevices[i] = connectionCopy
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}
