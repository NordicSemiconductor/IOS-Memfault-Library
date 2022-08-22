//
//  Chunk.swift
//  nRF Memfault
//
//  Created by Dinesh Harjani on 18/8/22.
//

import Foundation

struct Chunk: Identifiable, Hashable {
    
    // MARK: Status
    
    enum Status: Equatable, Hashable {
        case ready
        case uploading
        case success
        case errorUploading
    }
    
    // MARK: Properties
    
    let sequenceNumber: UInt8
    let data: Data
    let timestamp: Date
    var status: Status
    
    var id: Int {
        hashValue
    }
    
    // MARK: Init
    
    init(_ data: Data) {
        // Requirement to drop first byte, since it's an index / sequence number
        // and not part of the Data itself.
        self.sequenceNumber = data.first ?? .max
        self.data = data.dropFirst()
        self.timestamp = Date()
        self.status = .ready
    }
    
    // MARK: Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(sequenceNumber)
        hasher.combine(data)
        hasher.combine(status)
        hasher.combine(timestamp)
    }
}
