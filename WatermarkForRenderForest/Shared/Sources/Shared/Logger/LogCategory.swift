//
//  LogCategory.swift
//  
//
//  Created by John Harutyunyan on 13.11.23.
//

import Foundation

public enum LogCategory: String {
    case businessRule = "BUSINESS_RULE"
    case ui = "UI"
    case navigation = "NAVIGATION"
}

public enum LogType: Int {
    case fault
    case error
    case info
    case debug

    public var symbolicIcon: String {
        switch self {
        case .fault:
            return "🛑"
        case .error:
            return "⚠️"
        case .info:
            return "ℹ️"
        case .debug:
            return "✅"
        }
    }
}

public enum LogState {
    case off
    case on
}
