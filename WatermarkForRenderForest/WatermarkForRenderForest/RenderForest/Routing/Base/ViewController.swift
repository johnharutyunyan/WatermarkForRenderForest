//
//  ViewController.swift
//  WatermarkForRenderForest
//
//  Created by John Harutyunyan on 13.11.23.
//

import UIKit
import ViewModel
import Shared
import Combine

protocol Coordinated: AnyObject {
    associatedtype Coordinator
    var coordinator: Coordinator! { get set }
}

class ViewController<V: ViewModeling, C: Coordinator>: UIViewController, Coordinated {//} LoaderContainer {

    // MARK: - Property
    unowned var coordinator: C!
    var viewModel: V!
    var cancellables: Set<AnyCancellable> = []
    let logger: ILogger = Logger.createLogger(for: .ui, debugLogState: .on)
    private var spinner = UIActivityIndicatorView(style: .large)

    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        bindViewModel(viewModel: viewModel)
        bindLoader(viewModel: viewModel)
    }

    // MARK: - Public function
    func bindViewModel(viewModel: V) {}

    func bindLoader(viewModel: V) {
        viewModel.isLoading.sink { [weak self] isLoading in
            self?.handleLoading(isLoading: isLoading)
        }.store(in: &cancellables)
    }

    func setupUI() {
        view.backgroundColor = .surface
        spinner.center = view.center
        view.addSubview(spinner)
        spinner.hidesWhenStopped = true
    }

    // MARK: - Private function
    private func handleLoading(isLoading: Bool) {
        if isLoading {
            spinner.startAnimating()
        } else {
            spinner.stopAnimating()
        }
    }

    // MARK: - Deinit
    deinit {
        logger.logMessage(type: .debug, message: "deinit " + String(describing: type(of: self)))
    }
}
