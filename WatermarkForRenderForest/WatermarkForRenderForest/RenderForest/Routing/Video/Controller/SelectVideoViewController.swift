//
//  SelectVideoViewController.swift
//  WatermarkForRenderForest
//
//  Created by John Harutyunyan on 13.11.23.
//

import UIKit
import ViewModel
import Core

final class SelectVideoViewController: ViewController<SelectVideoViewModel, VideoCoordinator> {
        
    // MARK: - Outlet
    @IBOutlet var rotationsLabel: UILabel!
    
    // MARK: - Property
    private lazy var imagePickerManager: ImagePickerManager = {
        let imagePickerManager = ImagePickerManager()
        imagePickerManager.capturedVideoURLSubject.sink { [weak self] videoURL in
            guard let self = self else { return }
            let navigationModel = VideoEditorNavigationModel(videoURL: videoURL, rotations: rotations)
            self.coordinator.showWatermarkScreen(navigationModel: navigationModel)
        }.store(in: &cancellables)
        return imagePickerManager
    }()
    
    private var rotations = 1
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Action
    @IBAction func rotationSliderValueChanged(sender: UISlider) {
        rotationsLabel.text = "Rotations count: \(Int(sender.value))"
        rotations = Int(sender.value)
    }
    
    @IBAction private func selectVideoAction() {
        imagePickerManager.selectVideo()
    }
}
