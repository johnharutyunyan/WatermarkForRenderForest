//
//  ApplicationCoordinator.swift
//  WatermarkForRenderForest
//
//  Created by John Harutyunyan on 13.11.23.
//

import UIKit
//import ViewModel
//import Core

final class ApplicationCoordinator: BaseCoordinator<UINavigationController> {

    override func start() {
        runSelectVideoFlow()
    }

    // MARK: - Flow
    private func runSelectVideoFlow() {
        backToRoot()
        let coordinator = VideoCoordinator(rootViewController: rootViewController)
        coordinator.parentCoordinator = self
        addDependency(coordinator)
        coordinator.start()
    }
}

