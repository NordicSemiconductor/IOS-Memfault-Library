//
//  Scanner.swift
//  nRF Memfault
//
//  Created by Nick Kibysh on 15/04/2021.
//  Created by Dinesh Harjani on 3/8/22.
//

import Foundation
import Combine
import os
import CoreBluetooth

// MARK: - Scanner

final class Scanner: NSObject {
    
    // MARK: - Condition
    
    enum Condition: Equatable {
        case matchingAll
        case matchingServiceUUID(_ uuid: CBUUID)
        case connectable
        
        fileprivate func scanServices() -> [CBUUID] {
            switch self {
            case .matchingServiceUUID(let uuid):
                return [uuid]
            case .connectable, .matchingAll:
                return []
            }
        }
    }
    
    // MARK: - Private Properties
    
    private lazy var logger = Logger(Self.self)
    private lazy var bluetoothManager = CBCentralManager(delegate: self, queue: nil)
    private (set) lazy var devicePublisher = PassthroughSubject<ScannedDevice, Never>()
    
    @Published private (set) var managerState: CBManagerState = .unknown
    
    @Published private var scanConditions: [Condition] = [.matchingAll]
    @Published private var shouldScan = false
    @Published private (set) var isScanning = false
    
    private var cancellable = Set<AnyCancellable>()
}

// MARK: - API

extension Scanner {
    
    /**
     Needs to be called before any attempt to Scan is made.
     
     The first call to `CBCentralManager.state` is the one that turns on the BLE Radio if it's available, and successive calls check whether it turned on or not, but they cannot be made one after the other or the second will return an error. This is why we make this first call ahead of time.
     */
    func turnOnBluetoothRadio() -> AnyPublisher<CBManagerState, Never> {
        shouldScan = true
        _ = bluetoothManager.state
        return $managerState.eraseToAnyPublisher()
    }
    
    func toggle() {
        shouldScan.toggle()
    }
    
    func scan(with conditions: [Condition] = [.matchingAll]) -> AnyPublisher<ScannedDevice, Never> {
        scanConditions = conditions
        
        return turnOnBluetoothRadio()
            .filter { $0 == .poweredOn }
            .combineLatest($shouldScan, $scanConditions)
            .flatMap { (_, isScanning, scanConditions) -> PassthroughSubject<ScannedDevice, Never> in
                if isScanning {
                    let scanServices = scanConditions.flatMap { $0.scanServices() }
                    self.bluetoothManager.scanForPeripherals(withServices: scanServices,
                                                             options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
                    self.isScanning = true
                } else {
                    self.bluetoothManager.stopScan()
                    self.isScanning = false
                }
                
                return self.devicePublisher
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - CBCentralManagerDelegate

extension Scanner: CBCentralManagerDelegate {
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let device = ScannedDevice(peripheral: peripheral, advertisementData: advertisementData,
                                   rssi: RSSI)
        if scanConditions.contains(where: { $0 == .connectable }) {
            if device.advertisementData.isConnectable == true {
                devicePublisher.send(device)
            }
        } else {
            devicePublisher.send(device)
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        managerState = central.state
        logger.info("Bluetooth changed state: \(central.state)")
        
        if central.state != .poweredOn {
            shouldScan = false
        }
    }
}
