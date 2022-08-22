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
import iOS_Common_Libraries

final class AppData: ObservableObject {
    
    // MARK: Public
    
    @Published var isScanning: Bool
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
    
    // MARK: Refresh
    
    func refresh() {
        scannedDevices.removeAll()
        guard !bluetooth.isScanning else { return }
        toggleScanner()
    }
    
    // MARK: Scan
    
    func toggleScanner() {
        guard !bluetooth.isScanning else {
            bluetooth.toggle()
            return
        }

        Task { @MainActor in
            for await scanData in bluetooth.scan().values {
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
                
                await open(device)
            } catch {
                await encounteredError(error)
                disconnect(from: device)
            }
        }
    }
    
    private func listenForNewChunks(from device: Device) {
        Task {
            logger.info("START listening to MDS Data Export.")
            for try await data in bluetooth.data(fromCharacteristicWithUUID: .MDSDataExportCharacteristic, inServiceWithUUID: .MDS, device: device) {
                guard let chunk = await received(data, from: device) else { continue }
                logger.info("Received Chunk \(chunk.sequenceNumber). Now sending to Memfault.")
                upload(chunk, from: device)
            }
            logger.info("STOP listening to MDS Data Export.")
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
                        Data(repeating: 0, count: 0), writeType: .withResponse, toCharacteristicWithUUID: .MDSDataExportCharacteristic, inServiceWithUUID: .MDS, from: device)
                    await updateNotifyingStatus(of: device, to: false)
                }
                
                if device.notificationsEnabled {
                    logger.debug("Turning Off Notifications from \(device.name).")
                    _ = try await bluetooth.setNotify(false, toCharacteristicWithUUID: .MDSDataExportCharacteristic, inServiceWithUUID: .MDS, from: device)
                    await updateStreamingStatus(of: device, to: false)
                }
                
                try await bluetooth.disconnect(from: device)
                logger.info("Disconnected from \(device.name)")
                await updateDeviceConnectionState(of: device, to: .disconnected)
            } catch {
                await updateDeviceConnectionState(of: device, to: .disconnected)
                await encounteredError(error)
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
    
    @MainActor
    func open(_ device: Device) async {
        openDevice = device
    }
    
    @MainActor
    func received(_ data: Data?, from device: Device) -> Chunk? {
        guard let data = data,
              let i = scannedDevices.firstIndex(where: { $0.uuidString == device.uuidString }) else { return nil }
        
        let chunk = Chunk(data)
        scannedDevices[i].chunks.append(chunk)
        return chunk
    }
    
    func upload(_ chunk: Chunk, from device: Device) {
        Task { @MainActor in
            guard let postChunkRequest = HTTPRequest.post(chunk, for: device),
                  let i = scannedDevices.firstIndex(where: { $0.uuidString == device.uuidString }),
                  let j = scannedDevices[i].chunks.firstIndex(where: { $0 == chunk }) else { return }
            scannedDevices[i].chunks[j].status = .uploading
            
            network.perform(postChunkRequest)
                .sink(receiveCompletion: { [weak self, logger] error in
                    logger.error("Error Uploading Chunk \(chunk.sequenceNumber).")
                    self?.scannedDevices[i].chunks[j].status = .errorUploading
                }, receiveValue: { [weak self, logger] data in
                    logger.debug("Successfully Sent Chunk \(chunk.sequenceNumber).")
                    self?.scannedDevices[i].chunks[j].status = .success
                })
                .store(in: &cancellables)
        }
    }
    
    func updateNotifyingStatus(of device: Device, to isNotifying: Bool) async {
        Task { @MainActor in
            guard let i = scannedDevices.firstIndex(where: { $0.uuidString == device.uuidString }) else { return }
            scannedDevices[i].notificationsEnabled = isNotifying
            objectWillChange.send()
        }
    }
    
    func updateStreamingStatus(of device: Device, to isStreaming: Bool) async {
        Task { @MainActor in
            guard let i = scannedDevices.firstIndex(where: { $0.uuidString == device.uuidString }) else { return }
            scannedDevices[i].streamingEnabled = isStreaming
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
    
    func encounteredError(_ error: Error) async {
        let errorEvent = ErrorEvent(error)
        logger.error("\(errorEvent.localizedDescription)")
        Task { @MainActor in
            self.error = errorEvent
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
