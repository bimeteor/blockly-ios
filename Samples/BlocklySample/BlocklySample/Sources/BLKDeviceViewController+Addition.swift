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

extension UIColor{
    @inline(__always)
    public convenience init(_ rgb:Int) {
        self.init(red: CGFloat((rgb & 0xff0000)>>16)/255.0, green: CGFloat((rgb & 0xff00)>>8)/255.0, blue: CGFloat(rgb & 0xff)/255.0, alpha: 1)
    }
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
