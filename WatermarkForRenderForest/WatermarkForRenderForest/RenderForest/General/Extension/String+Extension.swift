//
//  String+Extension.swift
//  WatermarkForRenderForest
//
//  Created by John Harutyunyan on 14.11.23.
//

import Foundation

extension String {
    
    var localized: String {
        NSLocalizedString(self, comment: "")
    }
}
