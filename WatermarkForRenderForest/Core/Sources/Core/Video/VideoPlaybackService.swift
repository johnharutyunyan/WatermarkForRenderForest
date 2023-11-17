//
//  VideoPlaybackService.swift
//
//
//  Created by John Harutyunyan on 15.11.23.
//

import Foundation
import AVFoundation
import Combine
import Shared

public protocol IVideoPlaybackService {
    var durationSubject: PassthroughSubject<Float64, Never> { get }
    var secondsSubject: CurrentValueSubject<Float64, Never> { get }
    var playPauseSubject: CurrentValueSubject<AVPlayer.TimeControlStatus, Never> { get }

    func setupPlayer(with videoURL: URL, rotations: Int) -> AVPlayer
    func playPauseToggle()
    func pause()
    func changeToNewTime(_ seconds: Float64)
    func createWatermarkLayer(watermarkCGImage: CGImage, videoRect: CGSize) async -> CALayer
}

public class VideoPlaybackService: IVideoPlaybackService {
    
    // MARK: - Property
    private let watermark: IWatermarkService
    private var videoURL: URL?
    private var player: AVPlayer?
    public let durationSubject = PassthroughSubject<Float64, Never>()
    public let secondsSubject = CurrentValueSubject<Float64, Never>(0.0)
    public let playPauseSubject = CurrentValueSubject<AVPlayer.TimeControlStatus, Never>(.paused)
    private var isFirstPlay = true
    
    private let logger: ILogger = Logger.createLogger(for: .businessRule, debugLogState: .on)
    private var playerItemStatusObserver: AnyCancellable?
    private var rotations: Int = 1
    
    // MARK: - Init
    public init(watermark: IWatermarkService) {
        self.watermark = watermark
    }
    
    public func setupPlayer(with videoURL: URL, rotations: Int) -> AVPlayer {
        self.rotations = rotations
        watermark.setVideoURL(videoURL)
        let playerItem = AVPlayerItem(url: videoURL)
        let player = AVPlayer(playerItem: playerItem)
        self.player = player
        registerNotification()
        playerItemStatusObserver = playerItem.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self = self else { return }
                switch status {
                case .readyToPlay:
                    updateDuration()
                default:
                    break
                }
            }
    
        return player
    }
    
    public func playPauseToggle() {
        guard let player = player else { return }

        if player.timeControlStatus == .paused {
            player.playImmediately(atRate: 1)
            trackProgress()
        } else {
            player.pause()
        }
        playPauseSubject.send(player.timeControlStatus)
    }
    
    public func pause() {
        player?.pause()
        playPauseSubject.send(player?.timeControlStatus ?? .paused)
    }
    
    public func changeToNewTime(_ seconds: Float64) {
        let newTime = CMTimeMakeWithSeconds(seconds, preferredTimescale: 60)
        player?.seek(to: newTime)
        watermark.updateWatermarkPosition(for: seconds)
    }
    
    // MARK: - Watermark
    public func createWatermarkLayer(watermarkCGImage: CGImage, videoRect: CGSize) async -> CALayer {
        watermark.removeExistingWatermarkLayer() // Sure to not have watermark there
        let watermarkLayer = await watermark.createWatermarkLayer(watermarkCGImage: watermarkCGImage, videoRect: videoRect)
        await configureWatermarkAnimation(videoRect: videoRect)
        return watermarkLayer
    }
    
    // MARK: - Watermark Animation Configuration
    private func configureWatermarkAnimation(videoRect: CGSize) async {
        do {
            let currentItemDuration = try await player?.currentItem?.asset.load(.duration) ?? CMTime()
            let duration = CMTimeGetSeconds(currentItemDuration)
            let actualFrame = await watermark.calculateActualVideoFrame(in: videoRect)
            guard let path = watermark.createRectangularPath(inside: actualFrame) else {
                logger.logMessage(type: .error, message: "createRectangularPath is nil")
                return
            }
            watermark.configure(videoDuration: duration, rotations: rotations)
        } catch {
            logger.logMessage(type: .error, message: error.localizedDescription)
        }
    }
    
    // MARK: - Private function
    private func updateDuration() {
        if let duration = player?.currentItem?.duration.seconds, !duration.isNaN {
            durationSubject.send(duration)
        }
    }
    
    private func trackProgress() {
        let time = CMTimeMake(value: 1, timescale: 60)
        player?.addPeriodicTimeObserver(forInterval: time, queue: .main) { [weak self] current in
            guard let self = self else { return }
            let seconds = CMTimeGetSeconds(current)
            self.watermark.updateWatermarkPosition(for: seconds)
            self.secondsSubject.send(seconds)
        }
    }
    
    // MARK: - Notification
    private func registerNotification() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerDidFinishPlaying),
                                               name: .AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    @objc
    private func playerDidFinishPlaying() {
        guard let player = player else { return }
        player.seek(to: .zero)
        player.playImmediately(atRate: 0)
        playPauseSubject.send(player.timeControlStatus)
    }
}
