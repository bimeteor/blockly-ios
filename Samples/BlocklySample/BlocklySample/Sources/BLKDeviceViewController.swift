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
import AEXML

class BLKDeviceViewController: BLKBaseViewController {
    let bleManager = BluetoothManager()
    var ble:Bluetooth?
    var cmds = [(UInt8, [UInt8])]()
    var cmd = UInt8(0)
    let label = UILabel(frame: CGRect(x: UIScreen.main.bounds.width - 250, y: 150, width: 200, height: 20))
    var connectCtr:ConnectViewControler?
    
    override func viewDidLoad() {
        libPath = Bundle.main.path(forResource: "rover.json", ofType: nil)
        toolPath = Bundle.main.path(forResource: "rover.xml", ofType: nil)
        super.viewDidLoad()
        view.addSubview(label)
        label.textColor = .red
        label.text = "0"
    }
    override func start() {
        cmds = []
        cmd = 0
        ble?.startAcc()
        super.start()
    }
//    override func _stop() {
//        super._stop()
//    }
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
    
    override func onOther(_ ctr: UIViewController, obj: Any) {
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
        case "light_left_right"://TODO:frank
            cmds = [(0x78, [4, 3, 12, 0, 1, 0, 0, 0])]
            self.cmd = 0
            tryWriting()
            vm?.performer.continue()
        case "move_speed_duration"://TODO:frank
            cmds = [(0x78, [4, 3, 12, 0, 1, 0, 0, 0])]
            self.cmd = 0
            tryWriting()
        case "move_stop"://TODO:frank
            cmds = [(0x78, [4, 3, 12, 0, 1, 0, 0, 0])]
            self.cmd = 0
            tryWriting()
        case "move_myaction_duration"://TODO:frank
            cmds = [(0x78, [4, 3, 12, 0, 1, 0, 0, 0])]
            self.cmd = 0
            tryWriting()
        case "move_machine_rotate_duration"://TODO:frank
            cmds = [(0x78, [4, 3, 12, 0, 1, 0, 0, 0])]
            self.cmd = 0
            tryWriting()
        case "move_machine_rotate_speed"://TODO:frank
            cmds = [(0x78, [4, 3, 12, 0, 1, 0, 0, 0])]
            self.cmd = 0
            tryWriting()
        case "light_playvoice_pat"://TODO:frank
            break
        case "light_play_sound":
            break
        case "light_myvoice":
            break
        case "light_stop":
            break
        case "light_color_duration":
            break
        default:
            vm?.performer.continue()
        }
    }
    override func stop() {
        _stop()
    }
}
