//
//  RSSI.swift
//  nRF Memfault
//
//  Created by Dinesh Harjani on 3/8/22.
//

import Foundation

// MARK: - RSSI

public struct RSSI: ExpressibleByIntegerLiteral, Equatable, Hashable {
    
    // MARK: Condition
    
    public typealias IntegerLiteralType = Int
    
    enum Condition: Int {
        case outOfRange = 127
        case practicalWorst = -100
        case bad
        case ok
        case good
        
        init(value: Int) {
            switch value {
            case (5)... : self = .outOfRange
            case (-60)...(-20): self = .good
            case (-89)...(-20): self = .ok
            default: self = .bad
            }
        }
    }
    
    // MARK: Properties
    
    let value: Int
    let condition: Condition
    
    // MARK: Init
    
    public init(integerLiteral value: Int) {
        self.value = value
        self.condition = Condition(value: value)
    }
}
