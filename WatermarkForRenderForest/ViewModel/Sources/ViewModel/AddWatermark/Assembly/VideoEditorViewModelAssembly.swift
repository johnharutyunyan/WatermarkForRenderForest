//
//  VideoEditorViewModelAssembly.swift
//
//
//  Created by John Harutyunyan on 14.11.23.
//

import Foundation
import Swinject
import SwinjectAutoregistration
import Core

final public class VideoEditorViewModelAssembly: Assembly {

    public init() {}

    public func assemble(container: Container) {
        registerViewModel(in: container)
        registerViewModelServices(in: container)
    }

    private func registerViewModel(in container: Container) {
        container.autoregister(VideoEditorViewModel.self,
                               argument: IVideoEditorNavigationModel.self,
                               initializer: VideoEditorViewModel.init)
    }

    private func registerViewModelServices(in container: Container) {
        container.autoregister(VideoEditorViewModelServices.self, initializer: VideoEditorViewModelServices.init)
        container.autoregister(IVideoExportService.self, initializer: VideoExportService.init)
        container.autoregister(IVideoPlaybackService.self, initializer: VideoPlaybackService.init)
        container.autoregister(IVideoCompositionService.self, initializer: VideoCompositionService.init)
        container.autoregister(IWatermarkService.self, initializer: WatermarkService.init)

    }
 }
