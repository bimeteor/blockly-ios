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

class BLKDeviceViewController: BLKBaseViewController {
    override init() {
        super.init()
        libPath = Bundle.main.path(forResource: "rover.json", ofType: nil)
        toolPath = Bundle.main.path(forResource: "rover.xml", ofType: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        assertionFailure("Called unsupported initializer")
        super.init(coder: aDecoder)
    }
    
    let bleManager = BluetoothManager()
    var ble:Bluetooth?
    var cmd = 0
    
    var connectCtr:ConnectViewControler?
    var simulatorCtr:SimulatorViewController?
    
    var motionManager:CMMotionManager?
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    //btn
    override func run(){
        let ctr = ConnectViewControler(bleManager)
        ctr.modalPresentationStyle = .overCurrentContext
        ctr.modalTransitionStyle = .crossDissolve
        present(ctr, animated: true, completion: nil)
        ctr.delegate = self
    }
    //present ctr
    override func onConfirm(_ ctr: UIViewController, obj:Any) {
        guard let d = obj as? Bluetooth else { return }
        d.delegate = self
        ble = d
        ctr.dismiss(animated: true)
        connectCtr = nil
        codeCtr = nil
    }
    
    override func onCancel(_ ctr: UIViewController) {
        ctr.dismiss(animated: true)
        connectCtr = nil
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
