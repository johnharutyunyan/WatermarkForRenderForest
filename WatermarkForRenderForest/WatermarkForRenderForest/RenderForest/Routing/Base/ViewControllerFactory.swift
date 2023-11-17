//
//  ViewControllerFactory.swift
//  WatermarkForRenderForest
//
//  Created by John Harutyunyan on 13.11.23.
//

import UIKit
import ViewModel
import Swinject
import Core

final class ViewControllerFactory {
    
    static func makeSelectVideoViewController() -> SelectVideoViewController {
        let assembler = Assembler([SelectVideoViewModelAssembly()])
        let viewController: SelectVideoViewController = UIStoryboard.instantiate()
        viewController.viewModel = assembler.resolver.resolve(SelectVideoViewModel.self)
        return viewController
    }
    
    static func makeVideoEditorViewController(navigationModel: IVideoEditorNavigationModel) -> VideoEditorViewController {
        let assembler = Assembler([VideoEditorViewModelAssembly()])
        let viewController: VideoEditorViewController = UIStoryboard.instantiate()
        viewController.viewModel = assembler.resolver.resolve(VideoEditorViewModel.self, argument: navigationModel)
        return viewController
    }
}
