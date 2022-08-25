//
//  AppData.swift
//  nRF Memfault
//
//  Created by Dinesh Harjani on 2/8/22.
//

import Foundation
import OSLog
import CoreBluetooth
import Combine
import iOS_BLE_Library
import iOS_Common_Libraries

final class AppData: ObservableObject {
    
    // MARK: Public
    
    @Published var isScanning: Bool
    @Published var showOnlyMDSDevices: Bool {
        didSet {
            guard isScanning else { return }
            refresh()
        }
    }
    @Published var showOnlyConnectableDevices: Bool {
        didSet {
            guard isScanning else { return }
            refresh()
        }
    }
    
    @Published var scannedDevices: [Device]
    @Published var openDevice: Device?
    @Published var error: ErrorEvent?
    
    // MARK: Private
    
    private let bluetooth: Bluetooth
    private let network: Network
    private let logger: Logger
    private lazy var cancellables = Set<AnyCancellable>()
    
    // MARK: Init
    
    init() {
        self.bluetooth = Bluetooth()
        self.network = Network("chunks.memfault.com")
        self.isScanning = bluetooth.isScanning
        self.showOnlyMDSDevices = true
        self.showOnlyConnectableDevices = true
        self.scannedDevices = []
        self.openDevice = nil
        self.logger = Logger(Self.self)
        
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
        if bluetooth.isScanning {
            toggleScanner()
        }
        scannedDevices.removeAll()
        toggleScanner()
    }
    
    // MARK: Error
    
    func encounteredError(_ error: Error) {
        let errorEvent = ErrorEvent(error)
        logger.error("\(errorEvent.localizedDescription)")
        Task { @MainActor in
            self.error = errorEvent
        }
    }
    
    // MARK: Scan
    
    func toggleScanner() {
        guard !bluetooth.isScanning else {
            bluetooth.toggleScanner()
            return
        }

        Task { @MainActor in
            var filters = [Bluetooth.ScannerFilter]()
            if showOnlyMDSDevices {
                filters.append(.matchingServiceUUID(.MDS))
            }
            if showOnlyConnectableDevices {
                filters.append(.connectable)
            }
            for await scanData in bluetooth.scan(with: filters).values {
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
                try await bluetooth.connect(to: device)
                logger.info("Connecting to \(device.name)")
                await updateDeviceConnectionState(of: device, to: .connected)
                logger.info("Connected to \(device.name)")
                
                open(device)
                listenForNewChunks(from: device)
                
                logger.info("Discovering \(device.name)'s Services...")
                let cbServices = try await bluetooth.discoverServices(of: device)
                guard let mdsService = cbServices.first(where: { $0.uuid == .MDS }) else {
                    throw AppError.mdsNotFound
                }
                
                logger.info("Discovering MDS' Characteristics...")
                try await bluetooth.discoverCharacteristics(ofService: mdsService.uuid.uuidString, ofDeviceWithUUID: device.uuidString)
                
                logger.info("Reading Device Identifier...")
                guard let uriData = try await bluetooth.readCharacteristic(withUUID: .MDSDeviceIdentifierCharacteristic, inServiceWithUUID: .MDS, from: device),
                      let deviceIdentifierString = String(data: uriData, encoding: .utf8) else {
                    throw AppError.unableToReadDeviceIdentifier
                }
                logger.debug("Device Identifier: \(deviceIdentifierString)")
                
                logger.info("Reading Data URI...")
                guard let uriData = try await bluetooth.readCharacteristic(withUUID: .MDSDataURICharacteristic, inServiceWithUUID: .MDS, from: device),
                      let uriString = String(data: uriData, encoding: .utf8),
                      let uriURL = URL(string: uriString) else {
                    throw AppError.unableToReadDeviceURI
                }
                
                logger.info("Reading Auth Data...")
                guard let authData = try await bluetooth.readCharacteristic(withUUID: .MDSAuthCharacteristic, inServiceWithUUID: .MDS, from: device),
                      let authString = String(data: authData, encoding: .utf8)?.split(separator: ":") else {
                    throw AppError.unableToReadAuthData
                }
                await update(chunksURL: uriURL,
                             authKey: (key: String(authString[0]), auth: String(authString[1])),
                             of: device)
                
                let isNotifying = try await bluetooth.setNotify(true, toCharacteristicWithUUID: .MDSDataExportCharacteristic, inServiceWithUUID: .MDS, from: device)
                await updateNotifyingStatus(of: device, to: isNotifying)
                logger.debug("setNotify: \(isNotifying)")
                
                let writeResult = try await bluetooth.writeCharacteristic(Data(repeating: 1, count: 1), writeType: .withResponse, toCharacteristicWithUUID: .MDSDataExportCharacteristic, inServiceWithUUID: .MDS, from: device)
                logger.debug("Write Enable Result: \(writeResult ?? Data())")
                await updateStreamingStatus(of: device, to: true)
            } catch {
                encounteredError(error)
                disconnect(from: device)
            }
        }
    }
    
    // MARK: Upload
    
    private func listenForNewChunks(from device: Device) {
        Task {
            logger.info("START listening to MDS Data Export.")
            for try await data in bluetooth.data(fromCharacteristicWithUUID: .MDSDataExportCharacteristic, inServiceWithUUID: .MDS, device: device) {
                guard let chunk = await received(data, from: device) else { continue }
                
                do {
                    logger.info("Received Chunk \(chunk.sequenceNumber). Now sending to Memfault.")
                    try await upload(chunk, from: device)
                } catch {
                    logger.info("Error Uploading Chunk \(chunk.sequenceNumber). Disconnecting from device.")
                    disconnect(from: device)
                    
                    encounteredError(error)
                }
            }
            logger.info("STOP listening to MDS Data Export.")
        }
    }
    
    @MainActor
    func upload(_ chunk: Chunk, from device: Device) async throws {
        guard let postChunkRequest = HTTPRequest.post(chunk, for: device),
              let i = scannedDevices.firstIndex(where: { $0.uuidString == device.uuidString }),
              let j = scannedDevices[i].chunks.firstIndex(where: { $0 == chunk }) else {
            
            throw BluetoothError.cantRetrievePeripheral
        }
        
        scannedDevices[i].chunks[j].status = .uploading
        do {
            for try await _ in network.perform(postChunkRequest).values {
                scannedDevices[i].chunks[j].status = .success
                logger.debug("Successfully Sent Chunk \(chunk.sequenceNumber).")
                return
            }
        } catch {
            scannedDevices[i].chunks[j].status = .errorUploading
            logger.error("Error Uploading Chunk \(chunk.sequenceNumber).")
            throw error
        }
    }
    
    // MARK: Disconnect
    
    func disconnect(from device: Device) {
        Task {
            logger.info("Disconnecting from \(device.name)")
            await updateDeviceConnectionState(of: device, to: .disconnecting)
            
            do {
                if device.streamingEnabled {
                    logger.debug("Disabling Streaming from \(device.name).")
                    _ = try await bluetooth.writeCharacteristic(
                        Data(repeating: 0, count: 1), writeType: .withResponse, toCharacteristicWithUUID: .MDSDataExportCharacteristic, inServiceWithUUID: .MDS, from: device)
                await updateStreamingStatus(of: device, to: false)
                }
                
                if device.notificationsEnabled {
                    logger.debug("Turning Off Notifications from \(device.name).")
                    _ = try await bluetooth.setNotify(false, toCharacteristicWithUUID: .MDSDataExportCharacteristic, inServiceWithUUID: .MDS, from: device)
                    await updateNotifyingStatus(of: device, to: false)
                }
                
                try await bluetooth.disconnect(from: device)
                logger.info("Disconnected from \(device.name)")
                await updateDeviceConnectionState(of: device, to: .disconnected)
            } catch {
                await updateDeviceConnectionState(of: device, to: .disconnected)
                encounteredError(error)
            }
        }
    }
}

private extension AppData {
    
    func updateDeviceConnectionState(of device: Device, to newState: ConnectedState) async {
        Task { @MainActor in
            guard let i = scannedDevices.firstIndex(where: { $0.uuidString == device.uuidString }) else { return }
            scannedDevices[i].state = newState
            objectWillChange.send()
        }
    }
    
    func open(_ device: Device) {
        Task { @MainActor in
            openDevice = device
        }
    }
    
    @MainActor
    func received(_ data: Data?, from device: Device) -> Chunk? {
        guard let data = data,
              let i = scannedDevices.firstIndex(where: { $0.uuidString == device.uuidString }) else { return nil }
        
        let chunk = Chunk(data)
        scannedDevices[i].chunks.append(chunk)
        scannedDevices[i].chunks.sort(by: { a, b in
            return a.timestamp.timeIntervalSince1970 > b.timestamp.timeIntervalSince1970
        })
        return chunk
    }
    
    func updateNotifyingStatus(of device: Device, to isNotifying: Bool) async {
        Task { @MainActor in
            guard let i = scannedDevices.firstIndex(where: { $0.uuidString == device.uuidString }) else { return }
            scannedDevices[i].notificationsEnabled = isNotifying
            scannedDevices[i].objectWillChange.send()
            objectWillChange.send()
        }
    }
    
    func updateStreamingStatus(of device: Device, to isStreaming: Bool) async {
        Task { @MainActor in
            guard let i = scannedDevices.firstIndex(where: { $0.uuidString == device.uuidString }) else { return }
            scannedDevices[i].streamingEnabled = isStreaming
            scannedDevices[i].objectWillChange.send()
            objectWillChange.send()
        }
    }
    
    func update(chunksURL: URL, authKey: Device.ChunksURLAuthKey, of device: Device) async {
        Task { @MainActor in
            guard let i = scannedDevices.firstIndex(where: { $0.uuidString == device.uuidString }) else { return }
            scannedDevices[i].chunksURL = chunksURL
            scannedDevices[i].chunksURLAuthKey = authKey
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
