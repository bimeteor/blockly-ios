//
//  SpeedPickerController.swift
//  Blockly
//
//  Created by ubt on 2017/9/21.
//  Copyright © 2017年 Google Inc. All rights reserved.
//

import UIKit

class SpeedPickerController: TranslucentModalViewController {

    // MARK: - Properties
    
    /// The current angle value.
    public var speed: SpeedPicker.SpeedType = .normal {
        didSet {
            speedPicker.speed = speed
        }
    }
    
    /// Delegate for events that occur on this controller.
    public weak var delegate: AnglePickerViewControllerDelegate?
    
    /// Angle picker control.
    public private(set) lazy var speedPicker: SpeedPicker = {
        let picker = SpeedPicker(frame: .zero, options: self._speedPickerOptions)
        picker.speed = self.speed
        return picker
    }()
    
    /// Options used when initializing the angle picker.
    private var _speedPickerOptions = SpeedPicker.Options()
    
    
    // MARK: - Initializers
    
    public init(options: SpeedPicker.Options? = nil) {
        if let options = options {
            _speedPickerOptions = options
        }
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    // MARK: - View life cycle
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        contentView.addSubview(speedPicker)
    }
    
    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        speedPicker.frame = contentView.bounds
    }
}
