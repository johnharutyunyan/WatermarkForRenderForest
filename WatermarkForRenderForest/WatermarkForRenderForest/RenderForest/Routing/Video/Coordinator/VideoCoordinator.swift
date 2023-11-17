//
//  VideoCoordinator.swift
//  WatermarkForRenderForest
//
//  Created by John Harutyunyan on 13.11.23.
//

import UIKit
import ViewModel
import Core

final class VideoCoordinator: BaseCoordinator<UINavigationController> {
    
    override func start() {
        showSelectVideoScreen()
    }
    
    // MARK: - Flow
    private func showSelectVideoScreen() {
        logger.logMessage(type: .info, message: "Show Select Video Screen")
        let selectVideoViewController = ViewControllerFactory.makeSelectVideoViewController()
        selectVideoViewController.coordinator = self
        rootViewController.pushViewController(selectVideoViewController, animated: true)
    }
    
    // MARK: - Watermark Screen
    func showWatermarkScreen(navigationModel: IVideoEditorNavigationModel) {
        logger.logMessage(type: .info, message: "Show Video Editor Screen")
        let selectWatermarkViewController = ViewControllerFactory.makeVideoEditorViewController(navigationModel: navigationModel)
        selectWatermarkViewController.coordinator = self
        rootViewController.pushViewController(selectWatermarkViewController, animated: true)
    }
}
