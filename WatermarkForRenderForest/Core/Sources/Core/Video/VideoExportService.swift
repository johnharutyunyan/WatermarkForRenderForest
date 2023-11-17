//
//  VideoExportService.swift
//
//
//  Created by John Harutyunyan on 14.11.23.
//

import Foundation
import AVFoundation
import Combine
import Photos
import Shared

public protocol IVideoExportService {
    
    var exportStatusSubject: PassthroughSubject<Bool, Never> { get }
    func exportVideo(composition: AVMutableComposition, videoComposition: AVMutableVideoComposition)
}

public final class VideoExportService: IVideoExportService {
    
    // MARK: - Property
    public let exportStatusSubject = PassthroughSubject<Bool, Never>()
    private let logger: ILogger = Logger.createLogger(for: .businessRule, debugLogState: .on)
    
    // MARK: - Init
    public init() {}
    
    // MARK: - Public function
    public func exportVideo(composition: AVMutableComposition, videoComposition: AVMutableVideoComposition)  {
        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            logger.logMessage(type: .error, message: "Export session allocation issue")
            return
        }
        let outputURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("render.mov")
        do {
            try FileManager.default.removeItem(atPath: outputURL.path)
        } catch {
            logger.logMessage(type: .error, message: error.localizedDescription)
        }
        exportSession.videoComposition = videoComposition
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.exportAsynchronously { [weak self] in 
            guard let self = self else { return }
            switch exportSession.status {
            case .completed:
                if let outputURL = exportSession.outputURL {
                    saveVideoToPhotoLibrary(outputURL)
                    logger.logMessage(type: .info, message: "Export completed successfully")
                } else {
                    logger.logMessage(type: .error, message: "OutputURL is nil")
                }
                self.exportStatusSubject.send(true)
            case .failed, .cancelled:
                if let error = exportSession.error {
                    logger.logMessage(type: .error, message: error.localizedDescription)
                }
                self.exportStatusSubject.send(false)
            default:
                break
            }
        }        
    }
    
    private func saveVideoToPhotoLibrary(_ videoURL: URL) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
        }) { [weak self] success, error in
            if success {
                self?.logger.logMessage(type: .info, message: "Video saved to Photo Library successfully.")
            } else {
                if let error = error {
                    self?.logger.logMessage(type: .error, message: error.localizedDescription)
                }
            }
        }
    }
}
