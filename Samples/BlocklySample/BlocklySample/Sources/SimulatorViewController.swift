//
//  SimulatorViewController.swift
//  BlocklySample
//
//  Created by WG on 2017/10/26.
//  Copyright © 2017年 Google Inc. All rights reserved.
//

import Foundation
import UIKit

class SimulatorViewController: UIViewController {
    
    public weak var delegate: PresentViewControllerDelegate?
    public func move(_ step:Int) {
        
    }
    //1:left 2:right
    public func turn(_ dir:Int){
        
    }
    public func collect(){
        
    }
    public func jump(){
        
    }
    public func actor(_ index:Int){
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        container.layer.cornerRadius = 16
    }
    @IBOutlet weak var container: UIView!
    @IBAction func onTap(_ sender: Any) {
        delegate?.onCancel(self)
    }
}
