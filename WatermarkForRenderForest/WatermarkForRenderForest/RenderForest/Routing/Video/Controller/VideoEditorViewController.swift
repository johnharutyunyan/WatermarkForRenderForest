//
//  VideoEditorViewController.swift
//  WatermarkForRenderForest
//
//  Created by John Harutyunyan on 11.11.23.
//

import UIKit
import AVFoundation
import MobileCoreServices
import UniformTypeIdentifiers
import Photos
import ViewModel

final class VideoEditorViewController: ViewController<VideoEditorViewModel, VideoCoordinator> {
    
    // MARK: - Outlet
    @IBOutlet private var playerContainerView: UIView!
    @IBOutlet private var seekSlider: UISlider!
    @IBOutlet private var playPauseButton: UIButton!
    
    // MARK: - Property
    private lazy var imagePickerManager: ImagePickerManager = {
        let imagePickerManager = ImagePickerManager()
        imagePickerManager.capturedImageSubject.sink { [weak self] image in
            guard let self = self,
                  let resizedImage = image.resize(300),
            let watermarkCGImage = resizedImage.cgImage else { return }
            self.watermarkCGImage = watermarkCGImage
            Task {
                let layer = await self.viewModel.createWaterkmarkForPlayback(watermarkCGImage: watermarkCGImage,
                                                                             videoRect: self.playerContainerView.bounds.size)
                self.playerLayer?.addSublayer(layer)
            }
        }.store(in: &cancellables)
        return imagePickerManager
    }()
    
    private var playerLayer: AVPlayerLayer?
    private var duration: Float64?
    private var watermarkCGImage: CGImage?
    private var lastUpdateTime: TimeInterval = 0
    private let updateInterval: TimeInterval = 1.0 / 60.0 // 60 FPS
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = playerContainerView.bounds
    }
    
    override func bindViewModel(viewModel: VideoEditorViewModel) {
        super.bindViewModel(viewModel: viewModel)
        if let playerLayer = viewModel.retrievePlayerLayer() {
            self.playerLayer = playerLayer
            playerContainerView.layer.addSublayer(playerLayer)
        }
        viewModel.services.playback.durationSubject.sink { [weak self] duration in
            self?.duration = duration
        }.store(in: &cancellables)
        viewModel.services.playback.secondsSubject.sink { [weak self] currentSecond in
            self?.updateProgressSlider(currentSecond)
        }.store(in: &cancellables)
        viewModel.services.playback.playPauseSubject.sink { [weak self] timeControlStatus in
            self?.playPauseButton.isSelected = timeControlStatus != .paused
        }.store(in: &cancellables)
        viewModel.services.videoExport.exportStatusSubject.sink { [weak self] status in
            guard let self = self else { return }
            DispatchQueue.main.async {
                viewModel.isLoading.send(false)
                let alert = UIAlertController(title: status ? "Successfully saved to your Photos": "Failed to save",
                                              message: nil,
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK",
                                              style: .default))
                self.present(alert, animated: true, completion: nil)
            }
        }.store(in: &cancellables)
    }
    
    // MARK: - Private function
    private func updateProgressSlider(_ currentSecond: Float64) {
        guard let duration = duration else { return }
        let ratio = currentSecond / duration
        seekSlider.setValue(Float(ratio), animated: true)
    }
    
    // MARK: - Action
    @IBAction private func selectImage() {
        imagePickerManager.selectImage()
    }
    
    @IBAction private func playPauseAction() {
        viewModel.playPauseToggle()
    }
    
    @IBAction private func exportAction() {
        Task {
            viewModel.isLoading.send(true)
            guard let watermarkCGImage = watermarkCGImage else { return }
            await viewModel.exportVideo(watermarkCGImage: watermarkCGImage)
        }
    }
    
    // Slider
    @IBAction private func sliderChangedAction() {
        viewModel.pause()
        let seconds = (duration ?? 0) * Float64(seekSlider.value)
        viewModel.changeToNewTime(seconds)
    }
}
