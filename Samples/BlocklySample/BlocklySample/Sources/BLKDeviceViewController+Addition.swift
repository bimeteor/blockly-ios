//
//  SimpleWorkbenchViewController+Addition.swift
//  BlocklySample
//
//  Created by WG on 2017/9/8.
//  Copyright © 2017年 Google Inc. All rights reserved.
//

import Foundation
import UIKit
import CoreMotion

var mm:CMDeviceMotion?

extension BLKDeviceViewController{
    func tilt() {
        mm = CMDeviceMotion.init()
        motionManager = CMMotionManager.init()
        motionManager?.accelerometerUpdateInterval = 1.0/20
        motionManager?.startAccelerometerUpdates(to: OperationQueue.main) {
            if $1 == nil, let acc = $0{
                let x = acc.acceleration.x/acc.acceleration.z
                let y = acc.acceleration.y/acc.acceleration.z
                let cutX = 0.35
                let cutY = 0.3
                var res = ""
                if abs(x) >= cutX || abs(y) >= cutY{
                    let dir = UIApplication.shared.statusBarOrientation
                    if abs(x)/cutX > abs(y)/cutY{
                        if x >= cutX{
                            switch dir{
                            case .portrait:res = "right"
                            case .portraitUpsideDown:res = "left"
                            case .landscapeLeft:res = "forward"
                            case .landscapeRight:res = "backward"
                            default: res = ""
                            }
                        }else{
                            switch dir{
                            case .portrait:res = "left"
                            case .portraitUpsideDown:res = "right"
                            case .landscapeLeft:res = "backward"
                            case .landscapeRight:res = "forward"
                            default: res = ""
                            }
                        }
                    }else{//y
                        if y >= cutY{
                            switch dir{
                            case .portrait:res = "forward"
                            case .portraitUpsideDown:res = "backward"
                            case .landscapeLeft:res = "left"
                            case .landscapeRight:res = "right"
                            default: res = ""
                            }
                        }else{
                            switch dir{
                            case .portrait:res = "backward"
                            case .portraitUpsideDown:res = "forward"
                            case .landscapeLeft:res = "right"
                            case .landscapeRight:res = "left"
                            default: res = ""
                            }
                        }
                    }
                }
                self.vm?.performer.update(ABPerformer.Direction.init(res)?.rawValue ?? 0, type: "phone_tilt", id: 1)
            }
        }
    }
}

extension BLKDeviceViewController{
    @objc func act() {
        if case let str?? = try? workspace?.toXML(){
            print(str)
            vm?.performer.delegate = nil
            vm?.stop()
            vm = ABVirtulMachine.init(str)
            vm?.performer.delegate = self
            vm?.start()
            let ctr = SimulatorViewController()
            simulatorCtr = ctr
            ctr.modalPresentationStyle = .overCurrentContext
            ctr.modalTransitionStyle = .crossDissolve
            present(ctr, animated: true, completion: nil)
            ctr.delegate = self
        }
    }
    @objc func act1() {
//        vm?.performer.delegate = nil
//        vm?.stop()
//        unhighlightAllBlocks()
//        if simulator.superview == nil {
//            loadSimulator()
//        }
//        if running{
//            simulator.isHidden = true
//            running = false
//        }else{
//            simulator.isHidden = false
//            running = true
//            tilt()
//            if case let str?? = try? workspace?.toXML(){
//                print(str)
//                vm = ABVirtulMachine.init(str)
//                vm?.performer.delegate = self
//                vm?.start()
//            }
//            turtle.transform = CGAffineTransform.identity
//            turtle.center = CGPoint.init(x: simulator.bounds.width/2, y: simulator.bounds.height/2)
//        }
    }
    func move(_ step:Int) {
        UIView.animate(withDuration: 0.3, animations: {
            let size = CGSize.init(width: 0, height: -step).applying(self.turtle.transform)
            self.turtle.center = CGPoint.init(x: self.turtle.center.x+size.width, y: self.turtle.center.y+size.height)
        }) {_ in
            self.vm?.performer.endCurrent()
        }
    }
    func turn(_ angle:Int) {
        UIView.animate(withDuration: 0.3, animations: {
            self.turtle.transform = self.turtle.transform.rotated(by: -CGFloat(angle)*CGFloat.pi/180)
        }) {_ in
            self.vm?.performer.endCurrent()
        }
    }
    func color(_ rgb:Int) {
        UIView.animate(withDuration: 0.3, animations: {
            self.turtle.tintColor = UIColor.init(rgb)
        }) {_ in
            self.vm?.performer.endCurrent()
        }
    }
}

extension UIColor{
    @inline(__always)
    public convenience init(_ rgb:Int) {
        self.init(red: CGFloat((rgb & 0xff0000)>>16)/255.0, green: CGFloat((rgb & 0xff00)>>8)/255.0, blue: CGFloat(rgb & 0xff)/255.0, alpha: 1)
    }
}

extension BLKDeviceViewController:ABPerformerDelegate{
    func highlight(_ id:String){highlightBlock(blockUUID: id); print("\(#line) \(id)")}
    func unhighlight(_ id:String){unhighlightBlock(blockUUID: id); print("\(#line) \(id)")}
    func begin(_ cmd:String, value:Any){
        print("\(#line) \(cmd) \(value)")
        switch cmd {
        case "turtle_move":
            move(value as? Int ?? 0)
        case "turtle_turn":
            turn(value as? String == "left" ? 90 : -90)
        case "turtle_color":
            color(value as? Int ?? 0)
        default:
            vm?.performer.endCurrent()
        }
    }
    func end(){unhighlightAllBlocks(); print("end \(#line)")}
}

protocol PresentViewControllerDelegate: class{
    func onConfirm(_ ctr: UIViewController, obj:Any)
    func onCancel(_ ctr: UIViewController)
    func onRead(_ ctr:UIViewController, obj:Any)
}

extension BLKDeviceViewController:PresentViewControllerDelegate{
    func onConfirm(_ ctr: UIViewController, obj:Any) {
        if let u = obj as? UUID {
            ble = bleManager[u]
        }
        ctr.dismiss(animated: true)
        connectCtr = nil
        codeCtr = nil
    }
    
    func onCancel(_ ctr: UIViewController) {
        ctr.dismiss(animated: true)
        connectCtr = nil
        codeCtr = nil
    }
    
    func onRead(_ ctr: UIViewController, obj: Any) {
        if ctr is SimulatorViewController {
            vm?.endCurrent()
        }
    }
    
    @objc func popupConnect() {
        let ctr = ConnectViewControler(bleManager)
        connectCtr = ctr
        ctr.modalPresentationStyle = .overCurrentContext
        ctr.modalTransitionStyle = .crossDissolve
        present(ctr, animated: true, completion: nil)
        ctr.delegate = self
    }
    
    @objc func popupCode(){
        if case let str?? = try? workspace?.toXML(){
            saveBlocks()
            let ctr = CodeViewControler(str)
            codeCtr = ctr
            ctr.modalPresentationStyle = .overCurrentContext
            ctr.modalTransitionStyle = .crossDissolve
            present(ctr, animated: true, completion: nil)
            ctr.delegate = self
        }
    }
}

extension BLKDeviceViewController{
    
}

extension BLKDeviceViewController:BluetoothManagerDelegate{
    func managerDidUpdate(error: PhoneStateError?) {
        if let e = error {
            print(e);
        }else{
            bleManager.scan()
        }
    }
    
    func managerDidScan(_ uuid: UUID, name: String) {
        
    }
    
    func managerDidConnect(_ uuid: UUID, error: ConnectError?) {
        
    }
    
    func managerDidDisconnect(_ uuid: UUID, error: DisconnectError?) {
        
    }
}

extension BLKDeviceViewController:BluetoothDelegate{
    func bluetoothDidWrite(_ cmd: UInt8, error: WriteError?) {
        
    }
    
    func bluetoothDidVerify(_ error: VerifyError?) {
        
    }
    
    func bluetoothDidRead(_ data: (UInt8, [UInt8])?, error: ReadError?) {
        
    }
    
    func bluetoothDidHandshake(_ result: Bool) {
        
    }
    
    func bluetoothDidUpdateInfo(_ info: DeviceInfo) {
        
    }
}
