//
//  File.swift
//  
//
//  Created by John Harutyunyan on 13.11.23.
//

import Foundation
import os.log

final public class Logger: ILogger {
    private static var sharedLoggers: [LogCategory: Logger] = [:]
    private let category: LogCategory
    private let log: OSLog
    private let debugLogState: LogState

    private init(category: LogCategory, debugLogState: LogState) {
        self.category = category
        self.debugLogState = debugLogState
        let subsystem = "Podcastle"
        log = OSLog(subsystem: subsystem, category: category.rawValue)
    }

    public static func createLogger(for category: LogCategory, debugLogState: LogState = .off) -> Logger {
        if let logger = sharedLoggers[category] {
            return logger
        }

        let logger = Logger(category: category, debugLogState: debugLogState)
        sharedLoggers[category] = logger
        return logger
    }

    private func nativeLogType(_ type: LogType) -> OSLogType {
        switch type {
        case .debug:
            return .debug
        case .error:
            return .error
        case .info:
            return .info
        case .fault:
            return .fault
        }
    }

    public func logMessage(type: LogType, message: String, privateMessage: String? = nil) {
        // Local logging
        guard debugLogState == .on || type != .debug else { return }
        let nativeType = nativeLogType(type)
        let finalMessage = "\(type.symbolicIcon) - \(message)"
        if let privateMessage = privateMessage {
            os_log(nativeType, log: self.log, "%{public}@. %{private}@", finalMessage, privateMessage)
        } else {
            os_log(nativeType, log: self.log, "%{public}@.", finalMessage)
        }
    }

    public func logMessage(type: LogType, message: String) {
        logMessage(type: type, message: message, privateMessage: nil)
    }
}
