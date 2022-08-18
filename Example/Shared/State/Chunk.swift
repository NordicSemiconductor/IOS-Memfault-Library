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
        self.data = data
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(data)
    }
}
