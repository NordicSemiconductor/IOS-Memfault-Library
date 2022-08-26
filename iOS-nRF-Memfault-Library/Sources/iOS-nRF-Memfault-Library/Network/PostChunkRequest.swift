//
//  PostChunkRequest.swift
//  iOS-nRF-Memfault-Library
//
//  Created by Dinesh Harjani on 19/8/22.
//

import Foundation
import iOS_Common_Libraries

extension HTTPRequest {
    
    static func post(_ chunk: MemfaultChunk, with chunkURL: URL,
                     chunkAuthKey: String, chunkAuthValue: String) -> HTTPRequest? {
        var httpRequest = HTTPRequest(url: chunkURL)
        httpRequest.setMethod(.POST)
        httpRequest.setHeaders([
            "Content-Type": "application/octet-stream",
            chunkAuthKey: chunkAuthValue
        ])
        httpRequest.setBody(chunk.data)
        return httpRequest
    }
}
