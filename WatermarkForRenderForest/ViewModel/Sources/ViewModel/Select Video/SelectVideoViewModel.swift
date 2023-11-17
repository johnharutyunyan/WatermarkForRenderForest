//
//  SelectVideoViewModel.swift
//
//
//  Created by John Harutyunyan on 13.11.23.
//

import Foundation
import Core

public final class SelectVideoViewModelServices: CommonServices {
    
    public override init() {
        
    }
}

public protocol ISelectVideoViewModelInputs: AnyObject {
}

public protocol ISelectVideoViewModelOutputs: AnyObject {
    var outputs: SelectVideoViewModelOutputs { get }
}

public final class SelectVideoViewModelOutputs {
//    public var navigationModel: IPlayerNavigationModel!
//    public var title: String?
//    public let durationSubject = PassthroughSubject<Float64, Never>()
//    public let secondsSubject = CurrentValueSubject<Float64, Never>(0.0)
//    public var speedNavigationModel: IPlayerSpeedNavigationModel?
}

public typealias ISelectVideoViewModel = ViewModel<SelectVideoViewModelServices> & ISelectVideoViewModelInputs & ISelectVideoViewModelOutputs

public final class SelectVideoViewModel: ISelectVideoViewModel {
    
    public var outputs = SelectVideoViewModelOutputs()
    
    override init(services: SelectVideoViewModelServices) {
        super.init(services: services)
    }
}
