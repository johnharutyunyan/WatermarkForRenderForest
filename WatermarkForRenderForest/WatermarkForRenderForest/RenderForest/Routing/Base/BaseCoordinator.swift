//
//  BaseCoordinator.swift
//  WatermarkForRenderForest
//
//  Created by John Harutyunyan on 13.11.23.
//

import UIKit
import Shared
import Combine

protocol Coordinator: AnyObject {
    func start()
    func back()
    func backToRoot()
}

class BaseCoordinator<T: UIViewController>: Coordinator {

    weak var parentCoordinator: Coordinator?
    var childCoordinators: [Coordinator] = []
    var rootViewController: T
    let logger: ILogger = Logger.createLogger(for: .navigation)

    required init(rootViewController: T) {
        self.rootViewController = rootViewController
    }

    func start() {
        preconditionFailure()
    }

    func back() {
        preconditionFailure()
    }

    func backToRoot() {
        preconditionFailure()
    }

    func addDependency(_ coordinator: Coordinator) {
        childCoordinators.append(coordinator)
    }

    func removeLast() {
        childCoordinators.removeLast()
    }
}

// MARK: - UINavigationController
extension BaseCoordinator where T: UINavigationController {

    func back() {
        _ = rootViewController.popViewController(animated: true)
    }

    func backToRoot() {
        childCoordinators.removeAll()
        rootViewController.viewControllers.removeAll()
    }
}

