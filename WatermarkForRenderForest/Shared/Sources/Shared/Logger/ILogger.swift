//
//  ILogger.swift
//  
//
//  Created by John Harutyunyan on 13.11.23.
//

import Foundation

public protocol ILogger {
    func logMessage(type: LogType, message: String, privateMessage: String?)
    func logMessage(type: LogType, message: String)
}
