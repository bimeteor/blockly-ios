//
//  BLKSimulatorViewController.swift
//  BlocklySample
//
//  Created by WG on 2017/10/26.
//  Copyright © 2017年 Google Inc. All rights reserved.
//

import Foundation
import Blockly
class BLKSimulatorViewController: BLKBaseViewController {
    fileprivate var simulatorCtr:SimulatorViewController?
    override func viewDidLoad() {
        libPath = Bundle.main.path(forResource: "turtle_blocks.json", ofType: nil)
        toolPath = Bundle.main.path(forResource: "turtle.xml", ofType: nil)
        super.viewDidLoad()
    }
    override func ation(){
        if case _?? = try? workspace?.toXML(){
            let ctr = SimulatorViewController()
            simulatorCtr = ctr
            ctr.modalPresentationStyle = .overCurrentContext
            ctr.modalTransitionStyle = .crossDissolve
            present(ctr, animated: true, completion: nil)
            ctr.delegate = self
            super.ation()
        }
    }
    //present ctr

    override func onCancel(_ ctr: UIViewController) {
        ctr.dismiss(animated: true)
        simulatorCtr = nil
        codeCtr = nil
    }
    
    //run
    override func run(_ cmd:String, value:Any){
        print("\(#line) \(cmd) \(value)")
        switch cmd {
        case "turtle_move":
            simulatorCtr?.move(value as? Int ?? 0)
        case "turtle_turn":
            simulatorCtr?.turn(value as? String == "left" ? 1 : 2)
        case "turtle_color":
            simulatorCtr?.actor(value as? Int ?? 0)
        case "turtle_collect":
            simulatorCtr?.collect()
        default:
            vm?.performer.continue()
        }
    }
    override func stop() {super.stop()}
}
