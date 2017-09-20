//
//  TranslucentModalViewController.swift
//  Blockly
//
//  Created by ubt on 2017/9/18.
//  Copyright © 2017年 Google Inc. All rights reserved.
//

import UIKit

public protocol TranslucentModalViewControllerDelegate: class {
    func didTapOK(_ viewController: TranslucentModalViewController)
    func didTapBackground(_ viewController: TranslucentModalViewController)
}

open class TranslucentModalViewController: UIViewController {
    public weak var modalDelegate: TranslucentModalViewControllerDelegate?
    
    // 控制弹窗的大小
    public enum ModalContentSize: Int {
        case small = 5
        case medium = 7
        case large = 11
    }
    public var modalContentSize: ModalContentSize = .medium {
        didSet {
            _layoutSubviews()
        }
    }
    
    private lazy var _backgroundView: UIView = {
        return UIView()
    }()
    
    public lazy var contentView: UIView = {
        return UIView()
    }()
    
    public lazy var okButton: UIButton = {
        return UIButton(type: .custom)
    }()

    public var shouldShowOkButton = true {
        didSet {
            okButton.isHidden = !shouldShowOkButton
            _layoutSubviews()
        }
    }

    
    // MARK: - View life cycle
    
    private func _init() {
        self.modalPresentationStyle = .overCurrentContext // 实现背景半透明的modal
        self.modalTransitionStyle = .crossDissolve
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _init()
    }
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        _init()
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor(white: 0, alpha: 0.6)

        _backgroundView.backgroundColor = UIColor.white
        _backgroundView.layer.shadowColor = UIColor.black.cgColor
        _backgroundView.layer.shadowOffset = CGSize(width: 0.5, height: 1)
        _backgroundView.layer.shadowOpacity = 1.0
        _backgroundView.layer.cornerRadius = 8
        _backgroundView.layer.masksToBounds = true
        self.view.addSubview(_backgroundView)
        
        contentView.backgroundColor = UIColor.white
        _backgroundView.addSubview(contentView)
        
        let img = ImageLoader.loadImage(named: "ok", forClass: type(of: self))
        okButton.setImage(img, for: .normal)
        okButton.addTarget(self, action: #selector(onOkButtonAction(_:)), for: .touchUpInside)
        if shouldShowOkButton {
            self.view.addSubview(okButton)
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTapAction(_:)))
        self.view.addGestureRecognizer(tapGesture)
    }
    
    private func _layoutSubviews() {
        okButton.sizeToFit()

        let scale = CGFloat(modalContentSize.rawValue)
        let inset = self.view.frame.width / scale
        _backgroundView.frame = self.view.frame.insetBy(dx: inset, dy: inset*0.6)
        
        let offset: CGFloat = shouldShowOkButton ? (okButton.frame.height/2.0 + 5) : 0
        var contentFrame = _backgroundView.bounds
        contentFrame.size.height -= offset
        contentView.frame = contentFrame
        
        var okframe = okButton.frame
        okframe.origin.x = (self.view.frame.width - okButton.frame.width) / 2.0
        okframe.origin.y = _backgroundView.frame.maxY - okButton.frame.height/2.0
        okButton.frame = okframe
    }
    
    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        _layoutSubviews()
    }
    
    open override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - On ok button action
    
    func onOkButtonAction(_ sender: Any) {
        modalDelegate?.didTapOK(self)
    }
    
    
    // MARK: - On tap action
    
    func onTapAction(_ sender: Any) {
        let tapGesture = sender as! UITapGestureRecognizer
        let tapPoint = tapGesture.location(in: self.view)
        if !(_backgroundView.frame.contains(tapPoint)) {
            modalDelegate?.didTapBackground(self)
        }
    }
}
