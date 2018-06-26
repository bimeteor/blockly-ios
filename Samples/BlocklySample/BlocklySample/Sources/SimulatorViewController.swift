//
//  SimulatorViewController.swift
//  BlocklySample
//
//  Created by WG on 2017/10/26.
//  Copyright © 2017年 Google Inc. All rights reserved.
//

import Foundation
import UIKit
import SceneKit

class SimulatorViewController: UIViewController {
    
    @IBOutlet weak var container: UIView!
    @IBOutlet weak var stage: SCNView!
    public weak var delegate: PresentViewControllerDelegate?
    private lazy var actor = GameLoader.loadGameWithScnView(stage)
    private var ob:NSObjectProtocol?
    
    public func move(_ step:Int) {
        actor?.move(distance: step)
    }
    
    //1:left 2:right
    public func turn(_ dir:Int){
        if 1 == dir {
            actor?.turnLeft()
        } else if 2 == dir {
            actor?.turnRight()
        }
    }
    
    public func collect(){
        
    }
    
    public func jump(){
        actor?.jump()
    }
    
    public func actor(_ index:Int){
        
    }
    
    public func reset(){
        actor?.reset()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ob = NotificationCenter.default.addObserver(forName: Notification.Name(ActionDidCompletedNotificaitonName), object: nil, queue: nil){_ in
            self.delegate?.onOther(self, obj: 0)
        }
        GameLoader.bgmStart()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        GameLoader.silent()
        if let o = ob {
            NotificationCenter.default.removeObserver(o)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        container.layer.cornerRadius = 16
        actor?.reset()
    }
    
    @IBAction func onTap(_ sender: Any) {
        delegate?.onCancel(self)
    }
}
