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
    
    internal lazy var logger = Logger(Self.self)
    private lazy var bluetoothManager = CBCentralManager(delegate: self, queue: nil)
    
    typealias ScanData = (peripheral: CBPeripheral, advertisementData: [String: Any], RSSI: NSNumber)
    private (set) lazy var devicePublisher = PassthroughSubject<ScanData, Never>()
    
    @Published internal var managerState: CBManagerState = .unknown
    
    @Published internal var scanConditions: [Condition] = [.matchingAll]
    @Published internal var shouldScan = false
    @Published private(set) var isScanning = false
    
    private var cancellable = Set<AnyCancellable>()
    
    internal var continuations = [String: CheckedContinuation<CBPeripheral, Error>]()
    private var connectedPeripherals = [String: CBPeripheral]()
}

// MARK: - API

extension Scanner {
    
    // MARK: Scan
    
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
    
    func scan(with conditions: [Condition] = [.matchingAll]) -> AnyPublisher<ScanData, Never> {
        scanConditions = conditions
        
        return turnOnBluetoothRadio()
            .filter { $0 == .poweredOn }
            .combineLatest($shouldScan, $scanConditions)
            .flatMap { (_, isScanning, scanConditions) -> PassthroughSubject<ScanData, Never> in
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
    
    // MARK: Connect
    
    func connect<T: ScannerDevice>(to device: T) async throws {
        try await connect(toDeviceWithUUID: device.uuidString)
    }
    
    func connect(toDeviceWithUUID deviceUUID: String) async throws {
        guard let uuid = UUID(uuidString: deviceUUID),
              let peripheral = bluetoothManager.retrievePeripherals(withIdentifiers: [uuid]).first else {
            throw BluetoothError.cantRetrievePeripheral
        }
        
        peripheral.delegate = self
        guard continuations[deviceUUID] == nil else { throw BluetoothError.operationInProgress }
        do {
            let connectedPeripheral = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CBPeripheral, Error>) -> Void in
                continuations[deviceUUID] = continuation
                bluetoothManager.connect(peripheral)
            }
            connectedPeripherals[deviceUUID] = connectedPeripheral
            continuations.removeValue(forKey: deviceUUID)
        }
        catch {
            continuations.removeValue(forKey: deviceUUID)
            throw BluetoothError.coreBluetoothError(description: error.localizedDescription)
        }
    }
    
    // MARK: Discover Services
    
    func discoverServices<T: ScannerDevice>(_ serviceUUIDs: [String] = [], of device: T) async throws -> [CBService] {
        try await discoverServices(serviceUUIDs, ofDeviceWithUUID: device.uuidString)
    }
    
    func discoverServices(_ serviceUUIDs: [String] = [], ofDeviceWithUUID deviceUUID: String) async throws -> [CBService] {
        guard let peripheral = connectedPeripherals[deviceUUID] else {
            throw BluetoothError.cantRetrievePeripheral
        }
        peripheral.delegate = self
        guard continuations[deviceUUID] == nil else { throw BluetoothError.operationInProgress }
        
        do {
            let peripheralWithServices = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CBPeripheral, Error>) -> Void in
                continuations[deviceUUID] = continuation
                let cbUUIDServices = serviceUUIDs.map { CBUUID(string: $0) }
                peripheral.discoverServices(cbUUIDServices)
            }
            connectedPeripherals[deviceUUID] = peripheralWithServices
            continuations.removeValue(forKey: deviceUUID)
            return peripheralWithServices.services ?? []
        }
        catch {
            continuations.removeValue(forKey: deviceUUID)
            throw BluetoothError.coreBluetoothError(description: error.localizedDescription)
        }
    }
    
    // MARK: Disconnect
    
    func disconnect<T: ScannerDevice>(from device: T) async throws {
        try await disconnect(fromWithUUID: device.uuidString)
    }
    
    func disconnect(fromWithUUID deviceUUID: String) async throws {
        guard let peripheral = connectedPeripherals[deviceUUID] else {
            throw BluetoothError.cantRetrievePeripheral
        }
        
        peripheral.delegate = self
        guard continuations[deviceUUID] == nil else { throw BluetoothError.operationInProgress }
        do {
            let disconnectedPeripheral = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CBPeripheral, Error>) -> Void in
                continuations[deviceUUID] = continuation
                bluetoothManager.cancelPeripheralConnection(peripheral)
            }
            connectedPeripherals.removeValue(forKey: disconnectedPeripheral.identifier.uuidString)
            continuations.removeValue(forKey: deviceUUID)
        }
        catch {
            continuations.removeValue(forKey: deviceUUID)
            throw BluetoothError.coreBluetoothError(description: error.localizedDescription)
        }
    }
}
