//
//  VideoEditorViewModel.swift
//
//
//  Created by John Harutyunyan on 15.11.23.
//

import Foundation
import Core
import Combine
import AVFoundation

public final class VideoEditorViewModelServices: CommonServices {
    
    public let videoExport: IVideoExportService
    public let videoComposition: IVideoCompositionService
    public let playback: IVideoPlaybackService
    
    public init(videoExport: IVideoExportService,
                videoComposition: IVideoCompositionService,
                playback: IVideoPlaybackService) {
        self.videoExport = videoExport
        self.videoComposition = videoComposition
        self.playback = playback
        super.init()
    }
}

public protocol IVideoEditorViewModelInputs: AnyObject {
    func retrievePlayerLayer() -> AVPlayerLayer?
    func pause()
    func playPauseToggle()
    func changeToNewTime(_ seconds: Float64)
    func createWaterkmarkForPlayback(watermarkCGImage: CGImage, videoRect: CGSize) async -> CALayer
    func exportVideo(watermarkCGImage: CGImage) async
}

public protocol IVideoEditorViewModelOutputs: AnyObject {
    var outputs: VideoEditorViewModelOutputs { get }
}

public final class VideoEditorViewModelOutputs {
    public var navigationModel: IVideoEditorNavigationModel?
    public let secondsSubject = CurrentValueSubject<Float64, Never>(0.0)
    public let durationSubject = PassthroughSubject<Float64, Never>()
    public var player: AVPlayer?
}

public typealias IVideoEditorViewModel = ViewModel<VideoEditorViewModelServices>
& IVideoEditorViewModelInputs & IVideoEditorViewModelOutputs


public final class VideoEditorViewModel: IVideoEditorViewModel {
    
    public var outputs = VideoEditorViewModelOutputs()
    
    public init(services: VideoEditorViewModelServices, navigationModel: IVideoEditorNavigationModel) {
        super.init(services: services)
        outputs.navigationModel = navigationModel
    }
    
    // MARK: - Playback
    public func retrievePlayerLayer() -> AVPlayerLayer? {
        guard let videoURL = outputs.navigationModel?.videoURL,
              let rotations = outputs.navigationModel?.rotations else {
            logger.logMessage(type: .error, message: "Video URL is nil")
            return nil
        }
        let player = services.playback.setupPlayer(with: videoURL, rotations: rotations)
        return AVPlayerLayer(player: player)
    }
    
    public func playPauseToggle() {
        services.playback.playPauseToggle()
    }
    
    public func pause() {
        services.playback.pause()
    }
    
    public func changeToNewTime(_ seconds: Float64) {
        services.playback.changeToNewTime(seconds)
    }
    
    // MARK: - Watermark for Playback
    public func createWaterkmarkForPlayback(watermarkCGImage: CGImage, videoRect: CGSize) async -> CALayer {
        return await services.playback.createWatermarkLayer(watermarkCGImage: watermarkCGImage, videoRect: videoRect)
    }
    
    // MARK: - Export
    public func exportVideo(watermarkCGImage: CGImage) async {
        guard let videoURL = outputs.navigationModel?.videoURL,
        let rotations = outputs.navigationModel?.rotations else { return }
        services.videoComposition.mutableCompositionSubject
            .zip(services.videoComposition.mutableVideoCompositionSubject)
            .sink { [weak self] (composition, videoComposition) in
                self?.services.videoExport.exportVideo(composition: composition, videoComposition: videoComposition)
            }.store(in: &cancellables)
        await services.videoComposition.createCompositionAndVideoComposition(videoUrl: videoURL,
                                                                             rotations: rotations,
                                                                             watermarkCGImage: watermarkCGImage)
    }
}
