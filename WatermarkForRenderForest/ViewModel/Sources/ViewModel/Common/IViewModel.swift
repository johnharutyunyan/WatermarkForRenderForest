//
//  File.swift
//  
//
//  Created by John Harutyunyan on 13.11.23.
//

import Foundation
import Combine
import Core
import Shared

public protocol ViewModeling: AnyObject {
    var isLoading: CurrentValueSubject<Bool, Never> { get }
}

open class ViewModel<Services>: ViewModeling where Services: CommonServices {
    
    public let isLoading = CurrentValueSubject<Bool, Never>(false)

    var logger: ILogger = Logger.createLogger(for: .businessRule)
    public var services: Services

    public var cancellables: Set<AnyCancellable> = []

    init(services: Services) {
        self.services = services
    }

    open func handleServiceError(error: Error, showAlert: Bool = true) {
        logger.logMessage(type: .error, message: error.localizedDescription)
    }
}
