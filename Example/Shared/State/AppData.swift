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
    @Published var scannedDevices: Set<ScannedDevice>
    
    // MARK: Private
    
    private let scanner: Scanner
    
    // MARK: Init
    
    init() {
        self.scanner = Scanner()
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
    
    func toggleScanner() {
        guard !scanner.isScanning else {
            scanner.toggle()
            return
        }

        Task { @MainActor in
            for await newDevice in scanner.scan().values {
                scannedDevices.insert(newDevice)
            }
        }
    }
}
