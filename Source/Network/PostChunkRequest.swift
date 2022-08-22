//
//  PostChunkRequest.swift
//  nRF Memfault
//
//  Created by Dinesh Harjani on 19/8/22.
//

import Foundation
import iOS_Common_Libraries

extension HTTPRequest {
    
    static func postChunk(_ chunk: Chunk, for device: Device) -> HTTPRequest? {
        guard let url = device.chunksURL,
              let authPair = device.chunksURLAuthKey else { return nil }
        
        var httpRequest = HTTPRequest(url: url)
        httpRequest.setMethod(.POST)
        httpRequest.setHeaders([
            "Content-Type": "application/octet-stream",
            authPair.key: authPair.auth
        ])
        httpRequest.setBody(chunk.data)
        return httpRequest
    }
}
