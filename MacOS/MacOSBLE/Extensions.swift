//
//  Extensions.swift
//  MacOSBLE
//
//  Created by Tomasz on 19/12/2022.
//

import Foundation

extension Data {
    public var hexString: String {
        "0x" + self.map{ String(format: "%02hhx", $0).uppercased() }.joined()
    }
}

extension Optional {
    var isNil: Bool {
        switch self {
        case .none:
            return true
        case .some:
            return false
        }
    }

    var notNil: Bool {
        !self.isNil
    }
}

extension Optional where Wrapped == String {
    var readable: String {
        switch self {
        case .some(let value):
            return value
        case .none:
            return "nil"
        }
    }
}
