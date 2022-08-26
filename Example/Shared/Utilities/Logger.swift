//
//  Logger.swift
//  nRF Memfault
//
//  Created by Nick Kibysh on 12/04/2021.
//  Created by Dinesh Harjani on 3/8/22.
//

import Foundation
import os

extension Logger {
   
    static let nRFCommonLibrariesSubsystem = "com.nordicsemi.nRF-Common-Libraries"
    
    // MARK: - Init
    
    init(_ clazz: AnyClass) {
        self.init(category: String(describing: clazz))
    }
    
    init(category: String) {
        self.init(subsystem: Self.nRFCommonLibrariesSubsystem, category: category)
    }
}
