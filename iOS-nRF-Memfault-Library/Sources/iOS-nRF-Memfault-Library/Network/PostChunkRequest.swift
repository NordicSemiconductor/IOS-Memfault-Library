//
//  PostChunkRequest.swift
//  iOS-nRF-Memfault-Library
//
//  Created by Dinesh Harjani on 19/8/22.
//

import Foundation
import iOS_Common_Libraries

extension HTTPRequest {
    
    static func post(_ chunk: MemfaultChunk, with chunkAuth: MemfaultDeviceAuth) -> HTTPRequest {
        var httpRequest = HTTPRequest(url: chunkAuth.url)
        httpRequest.setMethod(.POST)
        httpRequest.setHeaders([
            "Content-Type": "application/octet-stream",
            chunkAuth.authKey: chunkAuth.authValue
        ])
        httpRequest.setBody(chunk.data)
        return httpRequest
    }
}
