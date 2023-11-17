//
//  SelectWatermarkNavigationModel.swift
//
//
//  Created by John Harutyunyan on 14.11.23.
//

import Foundation

public protocol IVideoEditorNavigationModel {
    var videoURL: URL { get }
    var rotations: Int { get }
}

public struct VideoEditorNavigationModel: IVideoEditorNavigationModel {
    
    public let videoURL: URL
    public let rotations: Int

    public init(videoURL: URL,
                rotations: Int) {
        self.rotations = rotations
        self.videoURL = videoURL
    }
}
