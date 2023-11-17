//
//  VideoCompositionService.swift
//
//
//  Created by John Harutyunyan on 14.11.23.
//

import Foundation
import AVFoundation
import Combine
import Shared

public protocol IVideoCompositionService {
    
    var mutableCompositionSubject: PassthroughSubject<AVMutableComposition, Never> { get }
    var mutableVideoCompositionSubject: PassthroughSubject<AVMutableVideoComposition, Never> { get }
    
    func createCompositionAndVideoComposition(videoUrl: URL, rotations: Int, watermarkCGImage: CGImage) async
}

public final class VideoCompositionService: IVideoCompositionService {
    
    // MARK: - Property
    public let mutableCompositionSubject = PassthroughSubject<AVMutableComposition, Never>()
    public let mutableVideoCompositionSubject = PassthroughSubject<AVMutableVideoComposition, Never>()
    
    let watermark: IWatermarkService
    private let logger: ILogger = Logger.createLogger(for: .businessRule, debugLogState: .on)
    
    // MARK: - Init
    public init(watermark: IWatermarkService) {
        self.watermark = watermark
    }
    
    // MARK: - Public function
    public func createCompositionAndVideoComposition(videoUrl: URL, rotations: Int, watermarkCGImage: CGImage) async {
        
        let mixComposition = AVMutableComposition()
        guard let videoTrack = mixComposition.addMutableTrack(withMediaType: .video,
                                                              preferredTrackID: Int32(kCMPersistentTrackID_Invalid)),
              let audioTrack = mixComposition.addMutableTrack(withMediaType: .audio,
                                                              preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else {
            logger.logMessage(type: .error, message: "Failed to add tracks to composition ")
            return
        }
        
        let videoAsset = AVAsset(url: videoUrl)
        let videoAssetTrack = try! await videoAsset.loadTracks(withMediaType: .video).first!
        let audioAssetTrack = try! await videoAsset.loadTracks(withMediaType: .audio).first!
        do {
            try await videoTrack.insertTimeRange(CMTimeRange(start: .zero, duration: videoAsset.load(.duration)),
                                                 of: videoAssetTrack, at: .zero)
            try await audioTrack.insertTimeRange(CMTimeRange(start: .zero, duration: videoAsset.load(.duration)),
                                                 of: audioAssetTrack, at: .zero)
        } catch {
            logger.logMessage(type: .error, message: error.localizedDescription)
        }
        
        let videoTransform = try! await videoAssetTrack.load(.preferredTransform)
        let videoAngle = atan2(videoTransform.b, videoTransform.a)
        let isVideoPortrait = abs(videoAngle) == .pi / 2

        // Create video composition
        let videoComposition = AVMutableVideoComposition(propertiesOf: mixComposition)
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        // Set renderSize and apply transform based on orientation
        if isVideoPortrait {
            videoComposition.renderSize = CGSize(width: videoTrack.naturalSize.height, height: videoTrack.naturalSize.width)
        } else {
            videoComposition.renderSize = videoTrack.naturalSize
        }

        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(start: .zero, duration: mixComposition.duration)

        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        if isVideoPortrait {
            let transform = CGAffineTransform(rotationAngle: videoAngle).translatedBy(x: 0, y: -videoComposition.renderSize.width)
            layerInstruction.setTransform(transform, at: .zero)
        } else {
            layerInstruction.setTransform(videoTransform, at: .zero)
        }

        instruction.layerInstructions = [layerInstruction]
        videoComposition.instructions = [instruction]
        
        let watermarkLayer = await watermark.createWatermarkLayer(watermarkCGImage: watermarkCGImage, videoRect: videoComposition.renderSize)        
        guard let path = watermark.createRectangularPath(inside: CGRect(x: 0,
                                                                  y: 0,
                                                                  width: videoComposition.renderSize.width,
                                                                  height: videoComposition.renderSize.height)) else {
            logger.logMessage(type: .error, message: "Rectangular path for animation is nil")
            return
        }
        
        let exportPath = flipPathVertically(path, in: CGRect(x: 0, y: 0,
                                                             width: videoComposition.renderSize.width,
                                                             height: videoComposition.renderSize.height))
        let compositionDuration = mixComposition.duration.seconds
        watermark.addPositionAnimation(path: exportPath, videoDuration: compositionDuration, rotations: rotations)
        // Create parent and video layers for animation tool
        let parentLayer = CALayer()
        let videoLayer = CALayer()
        parentLayer.frame = CGRect(x: 0, y: 0, width: videoComposition.renderSize.width, height: videoComposition.renderSize.height)
        videoLayer.frame = parentLayer.frame
        parentLayer.addSublayer(videoLayer)
        parentLayer.addSublayer(watermarkLayer)
        
        // Apply animation tool
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)
        mutableVideoCompositionSubject.send(videoComposition)
        mutableCompositionSubject.send(mixComposition)
    }
    
    private func flipPathVertically(_ path: CGPath, in frame: CGRect) -> CGPath {
        var transform = CGAffineTransform(scaleX: 1, y: -1)
        transform = transform.translatedBy(x: 0, y: -frame.height)
        return path.copy(using: &transform) ?? path
    }
}
