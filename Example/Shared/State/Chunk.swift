//
//  Chunk.swift
//  nRF Memfault
//
//  Created by Dinesh Harjani on 18/8/22.
//

import Foundation

struct Chunk: Identifiable, Hashable {
    
    let data: Data
    
    var id: Int {
        hashValue
    }
    
    init(_ data: Data) {
        // Requirement to drop first byte, since it's an index / sequence number
        // and not part of the Data itself.
        self.data = data.dropFirst()
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(data)
    }
}
