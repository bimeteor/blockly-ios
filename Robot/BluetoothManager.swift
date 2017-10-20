//
//  BLE.swift
//  BLE
//
//  Created by WG on 2016/11/3.
//  Copyright © 2016年 WG. All rights reserved.
//
/*
 1. only supported in main thread
 2.同时只存在一个请求，高优先级的优先，同优先级的遵守FIFO规则
 5.除读写数据格式错误之外的故障发生时，会自动断开连接
 */
import Foundation
import CoreBluetooth

final class BluetoothManager: NSObject {
    
    public weak var delegate:BluetoothManagerDelegate?
    public var nameFilter:((String)->Bool)?
    fileprivate var manager:CBCentralManager!
    fileprivate lazy var scannedPeers = Set<CBPeripheral>()//被扫描过的，元素只增不减，防止连接和断开时的系统错误
    fileprivate var initializing = false
    fileprivate lazy var bluetoothes = [UUID:Bluetooth]()
    
    public override init() {
        super.init()
        manager=CBCentralManager.init(delegate: self, queue: nil)
    }
    
    public func update(){
        checkState()
    }
    
    public func scan(){
        manager.scanForPeripherals(withServices: nil)
    }
    
    public func stopScan(){
        manager.stopScan()
    }
    
    public func connect(_ uuid:UUID){
        if let p = manager.retrievePeripherals(withIdentifiers: [uuid]).first{//TODO:frank
            switch p.state{
            case .connected: delegate?.managerDidConnect(uuid, error: nil)
            case .connecting: Void()
            default: manager.connect(p)
            }
        }else{
            delegate?.managerDidConnect(uuid, error: .unexisting)
        }
    }
    
    public func disconnect(_ uuid:UUID){
        if let p = manager.retrievePeripherals(withIdentifiers: [uuid]).first{
            switch p.state{
            case .disconnected: delegate?.managerDidDisconnect(uuid, error: nil)
            case .disconnecting: Void()
            default: manager.cancelPeripheralConnection(p)
            }
        }else{
            delegate?.managerDidDisconnect(uuid, error: nil)
        }
    }
    public subscript(_ id:UUID)->Bluetooth?{
        if let b = bluetoothes[id]{
            return b
        }else if let p = manager.retrievePeripherals(withIdentifiers: [id]).first{
            let b = Bluetooth(p)
            bluetoothes[id] = b
            return b
        }else{
            return nil
        }
    }
    
    fileprivate func checkState() {
        print("manager state:\(manager.state.rawValue)")
        switch manager.state {
        case .unsupported:
            delegate?.managerDidUpdate(error: .unsupported)
        case .poweredOn:
            delegate?.managerDidUpdate(error: nil)
        case .unauthorized:
            delegate?.managerDidUpdate(error:.unauthorized)
        case .poweredOff:
            delegate?.managerDidUpdate(error:.powerOff)
        default: Void()
        }
    }
}

public enum PhoneStateError:Int{
    case unsupported    = 1
    case unauthorized
    case powerOff
}

public enum ConnectError:Int{
    case unexisting = 1
    case systemError
}

public enum DisconnectError:Int{
    case systemError    = 1
}

protocol BluetoothManagerDelegate: class{
    func managerDidUpdate(error:PhoneStateError?)
    func managerDidScan(_ uuid:UUID, name:String)
    func managerDidConnect(_ uuid:UUID, error:ConnectError?)
    func managerDidDisconnect(_ uuid:UUID, error:DisconnectError?)
}

extension BluetoothManager:CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        checkState()
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let name = peripheral.name, nameFilter == nil || nameFilter!(name){
            scannedPeers.insert(peripheral)
            delegate?.managerDidScan(peripheral.identifier, name: name)
        }
    }
    
    func centralManager(_ centralManager: CBCentralManager, didConnect peripheral: CBPeripheral) {
        delegate?.managerDidConnect(peripheral.identifier, error:nil)
    }
    
    func centralManager(_ centralManager: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("didFailToConnect \(peripheral.state == .connected)" )
        delegate?.managerDidConnect(peripheral.identifier, error: .systemError)
    }
    
    func centralManager(_ centralManager: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("didDisconnectPeripheral \(peripheral.state == .connected)" )
        delegate?.managerDidDisconnect(peripheral.identifier, error: error == nil ? nil : .systemError)
    }
}
