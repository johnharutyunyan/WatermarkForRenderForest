//
//  ApplicationStartController.swift
//  WatermarkForRenderForest
//
//  Created by John Harutyunyan on 13.11.23.
//

import UIKit

final class ApplicationStartController: UINavigationController {
    
    lazy var applicationCoordinator: ApplicationCoordinator = {
        let coordinator = ApplicationCoordinator(rootViewController: self)
        return coordinator
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.isHidden = true
        applicationCoordinator.start()
    }
}
