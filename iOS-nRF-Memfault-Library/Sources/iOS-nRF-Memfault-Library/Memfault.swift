//
//  Memfault.swift
//  iOS-nRF-Memfault-Library
//
//  Created by Dinesh Harjani on 25/8/22.
//

import Foundation
import iOS_BLE_Library
import iOS_Common_Libraries

// MARK: - Memfault

public final class Memfault {
    
    // MARK: Private
    
    private let bluetooth: Bluetooth
    private let network: Network
    
    // MARK: Init
    
    public init() {
        self.bluetooth = Bluetooth()
        self.network = Network("chunks.memfault.com")
    }
    
    // MARK: Bluetooth
    
    public func connect<T: BluetoothDevice>(to device: T) {
        // To-Do
    }
    
    public func disconnect<T: BluetoothDevice>(from device: T) {
        // To-Do
    }
    
    // MARK: Network
    
    public func upload(_ chunk: MemfaultChunk, with chunkURL: URL, chunkAuthKey: String,
                       chunkAuthValue: String) async throws {
        guard let postChunkRequest = HTTPRequest.post(chunk, with: chunkURL, chunkAuthKey: chunkAuthKey, chunkAuthValue: chunkAuthValue) else {
            throw BluetoothError.cantRetrievePeripheral
        }
        
        // If there's an error it'll be thrown and caught by the caller.
        for try await _ in network.perform(postChunkRequest).values {
            return
        }
    }
}

