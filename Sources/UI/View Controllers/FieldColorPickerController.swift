//
//  FieldColorPickerController.swift
//  Blockly
//
//  Created by ubt on 2017/9/7.
//  Copyright © 2017年 Google Inc. All rights reserved.
//

import UIKit

public protocol FieldColorPickerControllerDelegate: class {
    func fieldColorPickerController(_ controller: FieldColorPickerController, didSelect color: UIColor)
}

open class FieldColorPickerController: TranslucentModalViewController {
    public weak var delegate: FieldColorPickerControllerDelegate?
    
    public var color: UIColor? {
        didSet {
            _refreshColorItems()
        }
    }
    
    
    // MARK: - View life cycle
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        _buildColorItems()
        _refreshColorItems()
    }
    
    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        // Layout color items.
        let space: CGFloat = 10
        let count = contentView.subviews.count
        let buttonWidth = contentView.frame.width/CGFloat(count) - space*2
        for btn in contentView.subviews {
            let idx = CGFloat(btn.tag)
            let x = (2*idx+1)*space + buttonWidth*idx
            btn.frame = CGRect(x: x, y: 5, width: buttonWidth, height: contentView.frame.height-5*2)
        }
    }

    open override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Build & refresh color items

    private func _buildColorItems() {
        func _createButton(with color: UIColor) -> UIButton {
            let btn = UIButton(type: .custom)
            btn.backgroundColor = color
            btn.layer.shadowColor = UIColor.black.cgColor
            btn.layer.shadowOffset = CGSize(width: 0.5, height: 0.5)
            btn.layer.shadowRadius = 2.0
            btn.layer.shadowOpacity = 1.0
            btn.addTarget(self, action: #selector(onColorButtonAction(_:)), for: .touchUpInside)
            return btn
        }
        
        let allColors: [UIColor] = [.green, .red, .yellow, .blue, .brown, .black]
        for (idx, color) in allColors.enumerated() {
            let btn = _createButton(with: color)
            btn.tag = idx
            contentView.addSubview(btn)
        }
    }
    
    func onColorButtonAction(_ sender: UIButton) {
        delegate?.fieldColorPickerController(self, didSelect: sender.backgroundColor!)
    }
    
    private func _refreshColorItems() {
        
    }
}
