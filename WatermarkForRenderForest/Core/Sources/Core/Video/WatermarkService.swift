//
//  WatermarkService.swift
//
//
//  Created by John Harutyunyan on 15.11.23.
//

import Foundation
import QuartzCore
import AVFoundation
import Shared

public protocol IWatermarkService {
    func setVideoURL(_ url: URL)
    func configure(videoDuration: TimeInterval, rotations: Int)
    func createWatermarkLayer(watermarkCGImage: CGImage, videoRect: CGSize) async -> CALayer
    func createRectangularPath(inside frame: CGRect) -> CGPath?
    func calculateActualVideoFrame(in videoRect: CGSize) async -> CGRect
    // Animation
    func addPositionAnimation(path: CGPath, videoDuration: TimeInterval, rotations: Int)
    func updateWatermarkPosition(for currentTime: TimeInterval)
    func removeExistingWatermarkLayer()
}

public class WatermarkService: IWatermarkService {
    
    private var videoURL: URL?
    private var watermarkLayer: CALayer?
    private var videoFrame: CGRect?
    
    private var videoDuration: TimeInterval?
    private var rotations: Int = 1
    
    private let logger: ILogger = Logger.createLogger(for: .businessRule, debugLogState: .on)
    
    // MARK: - Init
    public init() {}
    
    // MARK: - Public function
    public func setVideoURL(_ url: URL) {
        self.videoURL = url
    }
    
    public func configure(videoDuration: TimeInterval, rotations: Int) {
        self.videoDuration = videoDuration
        self.rotations = rotations
    }
    
    public func createWatermarkLayer(watermarkCGImage: CGImage, videoRect: CGSize) async -> CALayer {
        let watermarkLayer = CALayer()
        watermarkLayer.contents = watermarkCGImage
        watermarkLayer.borderWidth = 1
        // Calculate watermark size as a percentage of the video size
        let watermarkScale: CGFloat = 0.2 // Adjust the scale as needed
        let watermarkWidth = videoRect.width * watermarkScale
        let watermarkHeight = watermarkWidth * (CGFloat(watermarkCGImage.height) / CGFloat(watermarkCGImage.width))
        let actualVideoFrame = await calculateActualVideoFrame(in: videoRect)
        watermarkLayer.position = CGPoint(x: actualVideoFrame.minX, y: actualVideoFrame.minY)
        watermarkLayer.frame = CGRect(x: actualVideoFrame.minX,
                                      y: actualVideoFrame.minY,
                                      width: watermarkWidth,
                                      height: watermarkHeight)
        watermarkLayer.opacity = 0.9
        self.watermarkLayer = watermarkLayer
        return watermarkLayer
    }
    
    public func removeExistingWatermarkLayer() {
        watermarkLayer?.removeFromSuperlayer()
    }
    
    public func createRectangularPath(inside frame: CGRect) -> CGPath? {
        guard let watermarkLayer = watermarkLayer else {
            logger.logMessage(type: .error, message: "Watermark is nil")
            return nil
        }
        let insetX = watermarkLayer.frame.size.width / 2
        let insetY = watermarkLayer.frame.size.height / 2
        // Adjust the frame to account for the watermark size
        let adjustedFrame = frame.insetBy(dx: insetX, dy: insetY)
        // Create the path
        let path = CGMutablePath()
        // Start at top left, offset by half the size of the watermark
        path.move(to: CGPoint(x: adjustedFrame.minX, y: adjustedFrame.minY))
        // Top right
        path.addLine(to: CGPoint(x: adjustedFrame.maxX, y: adjustedFrame.minY))
        // Bottom right
        path.addLine(to: CGPoint(x: adjustedFrame.maxX, y: adjustedFrame.maxY))
        // Bottom left
        path.addLine(to: CGPoint(x: adjustedFrame.minX, y: adjustedFrame.maxY))
        // Close the path to return to the start point
        path.closeSubpath()
        return path
    }
    
    // MARK: - Position
    public func updateWatermarkPosition(for currentTime: TimeInterval) {
        guard let videoDuration = videoDuration else { return }
        let normalizedTime = currentTime / (videoDuration)
        let newPosition = calculatePositionAlongPath(normalizedTime: normalizedTime)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        watermarkLayer?.position = newPosition
        CATransaction.commit()
    }
    
    private func calculatePositionAlongPath(normalizedTime: Double) -> CGPoint {
        guard let frame = videoFrame else { return .zero }
        let watermarkSize = watermarkLayer?.frame.size ?? .zero
        let topEdgeLength = frame.width - watermarkSize.width
        let rightEdgeLength = frame.height - watermarkSize.height
        let bottomEdgeLength = topEdgeLength
        let leftEdgeLength = frame.height - watermarkSize.height
        let totalPathLength = topEdgeLength + rightEdgeLength + bottomEdgeLength + leftEdgeLength
        let totalLength = topEdgeLength + rightEdgeLength + bottomEdgeLength + leftEdgeLength
        let adjustedNormalizedTime = normalizedTime * Double(rotations)
        let currentPathPosition = adjustedNormalizedTime.truncatingRemainder(dividingBy: 1.0) * totalPathLength
        let adjustedDistance = currentPathPosition.truncatingRemainder(dividingBy: totalLength)
        switch adjustedDistance {
        case 0 ..< topEdgeLength:
            // Moving along the top edge
            return CGPoint(x: frame.minX + adjustedDistance + watermarkSize.width / 2, y: frame.minY + watermarkSize.height / 2)
        case topEdgeLength ..< (topEdgeLength + rightEdgeLength):
            // Moving down the right edge
            let verticalDistance = adjustedDistance - topEdgeLength
            return CGPoint(x: frame.maxX - watermarkSize.width / 2, y: frame.minY + verticalDistance + watermarkSize.height / 2)
        case (topEdgeLength + rightEdgeLength) ..< (topEdgeLength + rightEdgeLength + bottomEdgeLength):
            // Moving along the bottom edge
            let horizontalDistance = adjustedDistance - (topEdgeLength + rightEdgeLength)
            return CGPoint(x: frame.maxX - horizontalDistance - watermarkSize.width / 2, y: frame.maxY - watermarkSize.height / 2)
        default:
            // Moving up the left edge
            let verticalDistance = adjustedDistance - (topEdgeLength + rightEdgeLength + bottomEdgeLength)
            return CGPoint(x: frame.minX + watermarkSize.width / 2, y: frame.maxY - verticalDistance - watermarkSize.height / 2)
        }
    }
    
    // MARK: - Animation
    public func addPositionAnimation(path: CGPath,
                                     videoDuration: TimeInterval,
                                     rotations: Int) {
        guard let watermarkLayer = watermarkLayer else { return }
        let positionAnimation = CAKeyframeAnimation(keyPath: "position")
        positionAnimation.path = path
        positionAnimation.duration = videoDuration / Double(rotations)
        positionAnimation.repeatCount = Float(rotations)
        positionAnimation.isRemovedOnCompletion = false
        positionAnimation.fillMode = .forwards
        positionAnimation.beginTime = AVCoreAnimationBeginTimeAtZero  // Ensures synchronization
        watermarkLayer.add(positionAnimation, forKey: "position")
    }
    
    // MARK: - Frame
    public func calculateActualVideoFrame(in videoRect: CGSize) async -> CGRect {
        guard let videoAspectRatio = await getVideoAspectRatio() else { return .zero }

        let playerAspectRatio = videoRect.width / videoRect.height
        var actualVideoFrame = CGRect.zero

        if videoAspectRatio > playerAspectRatio {
            // Video is wider than the player view
            let scaledHeight = videoRect.width / videoAspectRatio
            actualVideoFrame = CGRect(x: 0, y: (videoRect.height - scaledHeight) / 2, width: videoRect.width, height: scaledHeight)
        } else {
            // Video is taller than the player view
            let scaledWidth = videoRect.height * videoAspectRatio
            actualVideoFrame = CGRect(x: (videoRect.width - scaledWidth) / 2, y: 0, width: scaledWidth, height: videoRect.height)
        }
        videoFrame = actualVideoFrame
        return actualVideoFrame
    }
    
    private func getVideoAspectRatio() async -> CGFloat? {
        guard let videoURL = videoURL else { return nil }
        let asset = AVAsset(url: videoURL)
        guard let track = try? await asset.loadTracks(withMediaType: .video).first,
        let videoSize = try? await track.load(.naturalSize).applying(track.load(.preferredTransform)) else { return nil  }
        return abs(videoSize.width / videoSize.height)
    }
}
