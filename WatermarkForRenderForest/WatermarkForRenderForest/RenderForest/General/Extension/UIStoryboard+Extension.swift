//
//  UIStoryboard+Extension.swift
//  WatermarkForRenderForest
//
//  Created by John Harutyunyan on 13.11.23.
//

import UIKit

extension UIStoryboard {

    static func instantiate<T>() -> T where T: UIViewController {
        let storyboard = UIStoryboard(name: String(describing: T.self), bundle: nil)
        guard let viewController = storyboard.instantiateViewController(withIdentifier: String(describing: T.self)) as? T else {
            return T()
        }

        return viewController
    }
}
