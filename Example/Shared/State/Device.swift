//
//  Device.swift
//  nRF Memfault
//
//  Created by Dinesh Harjani on 3/8/22.
//

import Foundation
import CoreBluetooth
import iOS_BLE_Library
import iOS_nRF_Memfault_Library

// MARK: - Device

struct Device: Identifiable, BluetoothDevice {
    
    // MARK: Properties
    
    var id: String {
        return uuidString
    }
    
    var isConnectable: Bool {
        return state != .notConnectable
    }
    
    let uuidString: String
    let rssi: RSSI
    let advertisementData: AdvertisementData
    
    var auth: MemfaultDeviceAuth?
    var uptimeStartTimestamp: Date?
    
    private(set) var name: String
    var state: ConnectedState
    var services: [CBService]
    var chunks: [MemfaultChunk]
    var notificationsEnabled: Bool
    var streamingEnabled: Bool
    
    // MARK: Init
    
    init(name: String, uuid: UUID, rssi: RSSI, advertisementData: AdvertisementData,
         state: ConnectedState? = nil) {
        self.name = advertisementData.localName ?? name
        self.uuidString = uuid.uuidString
        self.rssi = rssi
        self.advertisementData = advertisementData
        self.state = state ?? ((advertisementData.isConnectable ?? false) ? .disconnected : .notConnectable)
        self.services = []
        self.chunks = []
        self.notificationsEnabled = false
        self.streamingEnabled = false
    }
    
    init(peripheral: CBPeripheral, state: ConnectedState, advertisementData: [String: Any], rssi: NSNumber) {
        let advertisementData = AdvertisementData(advertisementData)
        self.name = advertisementData.localName ?? (peripheral.name ?? "N/A")
        self.uuidString = peripheral.identifier.uuidString
        self.rssi = RSSI(integerLiteral: rssi.intValue)
        self.advertisementData = advertisementData
        self.state = (advertisementData.isConnectable ?? false) ? state : .notConnectable
        self.services = []
        self.chunks = []
        self.notificationsEnabled = false
        self.streamingEnabled = false
    }
    
    // MARK: API
    
    mutating func update(from advertisingData: [String: Any]) {
        self.name = advertisementData.localName ?? name
    }
    
    mutating func connectionStateChanged(to newState: ConnectedState) {
        state = newState
        
        switch newState {
        case .connected:
            uptimeStartTimestamp = Date()
        case .disconnected:
            auth = nil
        case .notConnectable, .connecting, .disconnecting:
            break
        }
    }
    
    mutating func update(_ chunk: MemfaultChunk, to status: MemfaultChunk.Status) {
        guard let i = chunks.firstIndex(where: {
            $0.sequenceNumber == chunk.sequenceNumber && $0.data == chunk.data
        }) else {
            chunks.insert(chunk, at: 0)
            return
        }
        chunks[i].status = status
    }
}

// MARK: - Equatable

extension Device: Equatable {

    public static func == (lhs: Device, rhs: CBPeripheral) -> Bool {
        return lhs.uuidString == rhs.identifier.uuidString
    }

    public static func == (lhs: Device, rhs: Device) -> Bool {
        return lhs.uuidString == rhs.uuidString
            && lhs.state == rhs.state
            && lhs.chunks == rhs.chunks
            && lhs.notificationsEnabled == rhs.notificationsEnabled
            && lhs.streamingEnabled == rhs.streamingEnabled
    }
}

// MARK: - Hashable

extension Device: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(uuidString)
        hasher.combine(state)
        hasher.combine(chunks)
        hasher.combine(notificationsEnabled)
        hasher.combine(streamingEnabled)
    }
}

// MARK: ConnectedState

public enum ConnectedState: Int, RawRepresentable, Hashable, CustomStringConvertible, CaseIterable {
    
    case notConnectable
    case connecting, connected, disconnecting, disconnected
    
    public var description: String {
        switch self {
        case .notConnectable:
            return "Not Connectable"
        case .connecting:
            return "Connecting..."
        case .connected:
            return "Connected"
        case .disconnecting:
            return "Disconnecting..."
        case .disconnected:
            return "Disconnected"
        }
    }
    
    static func from(_ cbState: CBPeripheralState) -> ConnectedState {
        switch cbState {
        case .connecting:
            return .connecting
        case .connected:
            return .connected
        case .disconnecting:
            return .disconnecting
        case .disconnected:
            fallthrough
        default:
            return .disconnected
        }
    }
}

// MARK: - Debug

#if DEBUG
extension Device {
    
    static func sample(for connectedState: ConnectedState) -> Device {
        switch connectedState {
        case .notConnectable:
            return Device(name: "#AlonsoAlpineAstonMartinPiastriRicciardoMclarenMess", uuid: UUID(), rssi: .outOfRange, advertisementData: .unconnectableMock)
        case .connecting, .connected, .disconnecting, .disconnected:
            return Device(name: "Test Device", uuid: UUID(), rssi: .outOfRange, advertisementData: .connectableMock, state: connectedState)
        }
    }
}
#endif
