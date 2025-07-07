//
//  NordicLog.swift
//  nRF Memfault
//
//  Created by Nick Kibysh on 12/04/2021.
//  Created by Dinesh Harjani on 3/8/22.
//

import Foundation
import iOS_Common_Libraries

// MARK: - NordicLog

extension NordicLog {
   
    private static let nRFMemfaultSubsystem = "com.nordicsemi.nRF-Memfault"
    
    // MARK: - Init
    
    init(_ clazz: AnyClass) {
        self.init(category: String(describing: clazz))
    }
    
    init(category: String) {
        self.init(category: category, subsystem: Self.nRFMemfaultSubsystem)
    }
}
