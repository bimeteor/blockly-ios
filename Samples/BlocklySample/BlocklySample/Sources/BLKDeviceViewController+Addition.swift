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
    func bluetoothDidUpdateAcc(_ info: AccInfo, type: AccInfo.AccType) {
        guard info.errors.isEmpty else {
            print("bluetoothDidUpdateAcc error \(info.errors)")
            return
        }
        if let p = vm?.performer {
            info.values[type]?.forEach{
                if let v = $1 as? Int{
                    p.update(Int(v), type: "\(type)", id: $0)
                    label.text = "\(Int(v))"
                }
            }
        }
    }
    
    func bluetoothDidWrite(_ cmd: UInt8, error: WriteError?) {
        print("bluetoothDidWrite \(cmd)  \(error)")
    }
    
    func bluetoothDidVerify(_ error: VerifyError?) {
        print("bluetoothDidVerify \(error)")
    }
    
    func bluetoothDidRead(_ data: (UInt8, [UInt8])?, error: ReadError?) {
        print("bluetoothDidRead \(data?.0) \(data?.1) \(error)")
        if error == .restarted {
            ble?.handshake()
        }
        if let _ = error {
            _stop()
        }else{
            guard let _ = data else{
                _stop()
                return
            }
            if cmd == data?.0{
                cmd = 0
                tryWriting()
            }
        }
    }
    
    func bluetoothDidHandshake(_ result: Bool) {
        print("bluetoothDidHandshake \(result)")
    }
    
    func bluetoothDidUpdateDevice(_ info: DeviceInfo) {
        print("bluetoothDidHandshake \(info)")
    }
}
