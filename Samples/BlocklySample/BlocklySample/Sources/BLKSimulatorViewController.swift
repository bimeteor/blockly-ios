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
    override public init() {
        super.init()
        libPath = Bundle.main.path(forResource: "turtle_blocks.json", ofType: nil)
        toolPath = Bundle.main.path(forResource: "turtle.xml", ofType: nil)
    }
    required init?(coder aDecoder: NSCoder) {
        assertionFailure("Called unsupported initializer")
        super.init(coder: aDecoder)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        btn2.addTarget(self, action: #selector(run), for: .touchUpInside)
    }
    override func run(){
        if case _?? = try? workspace?.toXML(){
            let ctr = SimulatorViewController()
            simulatorCtr = ctr
            ctr.modalPresentationStyle = .overCurrentContext
            ctr.modalTransitionStyle = .crossDissolve
            present(ctr, animated: true, completion: nil)
            ctr.delegate = self
            super.run()
        }
    }
    //present ctr

    override func onCancel(_ ctr: UIViewController) {
        ctr.dismiss(animated: true)
        simulatorCtr = nil
        codeCtr = nil
    }
    
    override func onRead(_ ctr: UIViewController, obj: Any) {
        if ctr is SimulatorViewController {
            vm?.endCurrent()
        }
    }
    //run
    override func highlight(_ id:String){highlightBlock(blockUUID: id); print("\(#line) \(id)")}
    override func unhighlight(_ id:String){unhighlightBlock(blockUUID: id); print("\(#line) \(id)")}
    override func begin(_ cmd:String, value:Any){
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
            vm?.performer.endCurrent()
        }
    }
    override func end(){unhighlightAllBlocks(); print("end \(#line)")}
}