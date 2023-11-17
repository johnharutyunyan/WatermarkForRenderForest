//
//  SelectVideoViewModelAssembly.swift
//
//
//  Created by John Harutyunyan on 13.11.23.
//

import Foundation
import Swinject
import SwinjectAutoregistration
import Core

final public class SelectVideoViewModelAssembly: Assembly {

    public init() {}

    public func assemble(container: Container) {
        registerViewModel(in: container)
        registerViewModelServices(in: container)
    }

    private func registerViewModel(in container: Container) {
        container.autoregister(SelectVideoViewModel.self, initializer: SelectVideoViewModel.init)
    }

    private func registerViewModelServices(in container: Container) {
        container.autoregister(SelectVideoViewModelServices.self, initializer: SelectVideoViewModelServices.init)
    }
 }
