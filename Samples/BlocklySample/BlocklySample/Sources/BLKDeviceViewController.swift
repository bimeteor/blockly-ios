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

func infraredLevel(_ value:Int)->Int
{
    let realValue = value - 850;
    var level = 0.0
    
    if realValue < 0 {
        level = 0
    } else if realValue < 70 {
        level = (Double(realValue - 15) / 13.5)
    } else if realValue < 1210 {
        level = Double(realValue + 1134) / 288.0
    } else if realValue < 1565 {
        level = Double(realValue + 206) / 177
    } else if realValue < 1821 {
        level = Double(realValue - 1033) / 53.75
    } else if realValue < 2200 {
        level = Double(realValue - 1462) / 22.75
    } else {
        level = 20 // 此值不可达,因为realValue最大值为2800左右
    }
    
    if(level>20)
    {
        level=20
    }
    
    return Int(level)
}

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
    var cmds = [(UInt8, [UInt8])]()
    var cmd = UInt8(0)
    var sensorTimer:Timer?
    
    var connectCtr:ConnectViewControler?
    
    lazy var motionManager:CMMotionManager = CMMotionManager()
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func start() {
        cmds = []
        cmd = 0
        ble?.startSensor([1], type: .fir)
        sensorTimer?.invalidate()
        sensorTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true){_ in
            self.ble?.write(0x72, array: [1, 1, 0])
        }
        super.start()
        monitorTilt()
    }
    override func _stop() {
        super._stop()
        motionManager.stopAccelerometerUpdates()
        sensorTimer?.invalidate()
    }
    //btn
    override func ation(){
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
        start()
    }
    
    override func onCancel(_ ctr: UIViewController) {
        ctr.dismiss(animated: true)
        connectCtr = nil
        codeCtr = nil
    }
    
    override func onRead(_ ctr: UIViewController, obj: Any) {
        if ctr is SimulatorViewController {

        }
    }
    func tryWriting() {
        if ble?.state == .connected, ble?.handshaked == true{
            if cmds.count > 0{
                if cmd == 0{
                    let c = cmds[0]
                    cmd = c.0
                    ble?.write(c.0, array: c.1)
                    cmds.removeFirst()
                }
            }else{
                vm?.performer.continue()
            }
        }else{
            _stop()
        }
    }
    //run
    override func run(_ cmd:String, value:Any){
        print("\(#line) \(cmd) \(value)")
        switch cmd {
        case "move_action":
            guard let dir = value as? String else{vm?.performer.continue(); break}
            switch dir{
            case "forward":
                cmds = [(UInt8(7), [2, 1, 3, 1, 2, 0x92]), (UInt8(7), [2, 2, 4, 2, 2, 0x92])]
                self.cmd = 0
                tryWriting()
            case "backward":
                cmds = [(UInt8(7), [2, 1, 3, 2, 2, 0x92]), (UInt8(7), [2, 2, 4, 1, 2, 0x92])]
                self.cmd = 0
                tryWriting()
            case "left":
                cmds = [(UInt8(7), [2, 2, 4, 2, 0, 0x40]), (UInt8(7), [2, 1, 3, 1, 2, 0x92])]
                self.cmd = 0
                tryWriting()
            case "right":
                cmds = [(UInt8(7), [2, 2, 4, 2, 2, 0x92]), (UInt8(7), [2, 1, 3, 1, 0, 0x40])]
                self.cmd = 0
                tryWriting()
            default:vm?.performer.continue()
            }
        default:
            vm?.performer.continue()
        }
    }
    override func stop() {
        _stop()
    }
}
