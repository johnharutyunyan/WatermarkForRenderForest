//
//  UIImage+Extension.swift
//  WatermarkForRenderForest
//
//  Created by John Harutyunyan on 17.11.23.
//

import UIKit

extension UIImage {
    
    // MARK: - Resize
    func resize(_ width: CGFloat) -> UIImage? {
        let imageView = UIImageView(frame: CGRect(origin: .zero,
                                                  size: CGSize(width: width,
                                                               height: CGFloat(ceil(width / size.width * size.height)))))
        imageView.image = self
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        imageView.layer.render(in: context)
        guard let result = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        UIGraphicsEndImageContext()
        return result
    }
}