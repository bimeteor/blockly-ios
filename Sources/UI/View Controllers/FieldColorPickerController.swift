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
    func fieldColorPickerControllerDidCancel(_ controller: FieldColorPickerController)
}

open class FieldColorPickerController: UIViewController {
    public weak var delegate: FieldColorPickerControllerDelegate?
    
    public var color: UIColor? {
        didSet {
            _refreshColorItems()
        }
    }
    
    private lazy var _contentView: UIView = {
        return UIView()
    }()
    
    
    // MARK: - View life cycle
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor(white: 0, alpha: 0.6)
        
        _contentView.backgroundColor = UIColor.white
        _contentView.layer.shadowColor = UIColor.black.cgColor
        _contentView.layer.shadowOffset = CGSize(width: 0.5, height: 1)
        _contentView.layer.shadowOpacity = 1.0
        self.view.addSubview(_contentView)
        
        _buildColorItems()
        _refreshColorItems()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(onTapAction(_:)))
        self.view.addGestureRecognizer(tap)
    }
    
    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        // Layout content view at center.
        let viewSize = self.view.frame.size
        let hContent = viewSize.height * 0.5
        let margin: CGFloat = 40
        _contentView.frame = CGRect(x: margin,
                                    y: (viewSize.height - hContent) / 2.0,
                                    width: viewSize.width - margin*2, height: hContent)
        
        // Layout color items.
        let space: CGFloat = 10
        let count = _contentView.subviews.count
        let buttonWidth = _contentView.frame.width/CGFloat(count) - space*2
        for btn in _contentView.subviews {
            let idx = CGFloat(btn.tag)
            let x = (2*idx+1)*space + buttonWidth*idx
            btn.frame = CGRect(x: x, y: 5, width: buttonWidth, height: _contentView.frame.height-5*2)
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
            _contentView.addSubview(btn)
        }
    }
    
    func onColorButtonAction(_ sender: UIButton) {
        delegate?.fieldColorPickerController(self, didSelect: sender.backgroundColor!)
    }
    
    private func _refreshColorItems() {
        
    }
    
    
    // MAKR: - On tap action
    
    func onTapAction(_ sender: Any) {
        delegate?.fieldColorPickerControllerDidCancel(self)
    }
}
