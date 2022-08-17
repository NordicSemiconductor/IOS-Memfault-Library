//
//  AppError.swift
//  nRF Memfault
//
//  Created by Dinesh Harjani on 17/8/22.
//

import Foundation

enum AppError: LocalizedError {
    
    case mdsNotFound
    case unableToReadDeviceIdentifier, unableToReadDeviceURI, unableToReadAuthData
    
    var failureReason: String? { errorDescription }
    
    var errorDescription: String? {
        switch self {
        case .mdsNotFound:
            return "MDS Service not found."
        case .unableToReadDeviceIdentifier:
            return "Unable to Read Device Identifier."
        case .unableToReadDeviceURI:
            return "Unable to Read Device URI."
        case .unableToReadAuthData:
            return "Unable to Read Auth Data."
        }
    }
}
