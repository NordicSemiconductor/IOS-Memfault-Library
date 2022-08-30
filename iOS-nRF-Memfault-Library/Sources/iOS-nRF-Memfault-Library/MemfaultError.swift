//
//  MemfaultError.swift
//  iOS-nRF-Memfault-Library
//
//  Created by Dinesh Harjani on 26/8/22.
//

import Foundation

public enum MemfaultError: Error, LocalizedError {
    
    case mdsNotFound, authDataNotFound
    case unableToReadDeviceIdentifier, unableToReadDeviceURI, unableToReadAuthData
    
    public var failureReason: String? { errorDescription }
    
    public var errorDescription: String? {
        switch self {
        case .mdsNotFound:
            return "MDS Service not found."
        case .authDataNotFound:
            return "Unable to find Chunk Auth Data for device."
        case .unableToReadDeviceIdentifier:
            return "Unable to Read Device Identifier."
        case .unableToReadDeviceURI:
            return "Unable to Read Device URI."
        case .unableToReadAuthData:
            return "Unable to Read Auth Data."
        }
    }
}
