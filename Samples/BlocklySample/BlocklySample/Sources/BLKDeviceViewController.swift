/*
 * Copyright 2015 Google Inc. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Blockly
import CoreMotion
import AEXML

class BLKDeviceViewController: BLKSimulatorViewController {
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        assertionFailure("Called unsupported initializer")
        super.init(coder: aDecoder)
    }
    
    let turtle = UIImageView(image: UIImage(named: "turtle")?.withRenderingMode(.alwaysTemplate))
    
    let bleManager = BluetoothManager()
    var ble:Bluetooth?
    var cmd = 0
    
    var connectCtr:ConnectViewControler?
    var simulatorCtr:SimulatorViewController?
    
    var motionManager:CMMotionManager?
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
