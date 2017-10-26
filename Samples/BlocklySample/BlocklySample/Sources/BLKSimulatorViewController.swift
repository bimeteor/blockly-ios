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
    override public init() {
        super.init()
        libPath = Bundle.main.path(forResource: "turtle_blocks.json", ofType: nil)
        toolPath = Bundle.main.path(forResource: "turtle.xml", ofType: nil)
    }
    required init?(coder aDecoder: NSCoder) {
        assertionFailure("Called unsupported initializer")
        super.init(coder: aDecoder)
    }
}
