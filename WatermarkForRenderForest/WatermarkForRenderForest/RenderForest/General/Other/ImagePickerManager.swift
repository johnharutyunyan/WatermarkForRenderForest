//
//  ImagePickerManager.swift
//  WatermarkForRenderForest
//
//  Created by John Harutyunyan on 14.11.23.
//

import UIKit
import AVFoundation
import Combine

enum ImagePickerManagerStatus {
    case denied
    case authorized
}

final class ImagePickerManager: NSObject {

    // MARK: - Property
    private lazy var imagePicker: UIImagePickerController = {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
//        imagePicker.allowsEditing = true
        imagePicker.sourceType = .photoLibrary
        return imagePicker
    }()

    let statusSubject = PassthroughSubject<ImagePickerManagerStatus, Never>()
    let capturedImageSubject = PassthroughSubject<UIImage, Never>()
    let capturedVideoURLSubject = PassthroughSubject<URL, Never>()

    // MARK: - Internal function
    func checkAuthorizationStatus() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            statusSubject.send(.authorized)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.statusSubject.send(granted ? .authorized : .denied)
                }
            }
        case .denied, .restricted:
            statusSubject.send(.denied)
        default:
            break
        }
    }
    
    func selectVideo() {
        imagePicker.mediaTypes = ["public.movie"]
        UIApplication.shared.keyWindow?.rootViewController?.present(imagePicker, animated: true)
    }
    
    func selectImage() {
        imagePicker.mediaTypes = [UTType.image.identifier]
        UIApplication.shared.keyWindow?.rootViewController?.present(imagePicker, animated: true)
    }

    func presentPicker() {
        let alertController = UIAlertController(title: "cameraManager.source.select".localized,
                                                message: nil,
                                                preferredStyle: .actionSheet)
        if let action = self.action(for: .camera,
                                    title: "cameraManager.source.camera".localized) {
            alertController.addAction(action)
        }
        if let action = self.action(for: .savedPhotosAlbum,
                                    title: "cameraManager.source.photoLibrary".localized) {
            alertController.addAction(action)
        }

        alertController.addAction(UIAlertAction(title: "general.cancel".localized, style: .cancel, handler: nil))
    }

    // MARK: - Private function
    private func action(for type: UIImagePickerController.SourceType,
                        title: String) -> UIAlertAction? {
        guard UIImagePickerController.isSourceTypeAvailable(type) else {
            return nil
        }

        return UIAlertAction(title: title, style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.imagePicker.sourceType = type
        }
    }
}

// MARK: - UIImagePickerControllerDelegate
extension ImagePickerManager: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        if let image = info[.originalImage] as? UIImage {
            capturedImageSubject.send(image)
        } else if let videoURL = info[.mediaURL] as? URL {
            capturedVideoURLSubject.send(videoURL)
        }
    }
}
