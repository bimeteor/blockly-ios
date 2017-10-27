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
    
    public var nameFilter:((String)->Bool)?
    fileprivate let serviceUuid = CBUUID.init(string: serviceStr)
    fileprivate var manager:CBCentralManager!
    fileprivate var scannedPeers = Set<CBPeripheral>()//被扫描过的，元素只增不减，防止连接和断开时的系统错误
    fileprivate var initializing = false
    fileprivate var bluetoothes = [UUID:Bluetooth]()
    fileprivate var delegates = [BluetoothManagerDelegate]()
    public var connected:[(UUID, String)]{
        return manager.retrieveConnectedPeripherals(withServices: [serviceUuid]).filter{$0.state == .connected}.map{($0.identifier, $0.name ?? "")}
    }
    
    public func addDelegate(_ delegate:BluetoothManagerDelegate){
        for e in delegates {
            if e === delegate{
                return
            }
        }
        delegates += [delegate]
    }
    
    public func removeDelegate(_ delegate:BluetoothManagerDelegate){
        var idx = -1
        for e in delegates.enumerated() {
            if (e.element === delegate){
                idx = e.offset
                break
            }
        }
        if idx >= 0 {
            delegates.remove(at: idx)
        }
    }
    
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
    
    func connect(_ uuid:UUID){
        if let p = manager.retrievePeripherals(withIdentifiers: [uuid]).first{//TODO:frank
            switch p.state{
            case .connected: delegates.forEach{$0.managerDidConnect(uuid, error: nil)}
            case .connecting: Void()
            default: manager.connect(p)
            }
        }else{
            delegates.forEach{$0.managerDidConnect(uuid, error: .unexisting)}
        }
    }
    
    func disconnect(_ uuid:UUID){
        if let p = manager.retrievePeripherals(withIdentifiers: [uuid]).first{
            switch p.state{
            case .disconnected: delegates.forEach{$0.managerDidDisconnect(uuid, error: nil)}
            case .disconnecting: Void()
            default: manager.cancelPeripheralConnection(p)
            }
        }else{
            delegates.forEach{$0.managerDidDisconnect(uuid, error: nil)}
        }
    }
    
    fileprivate func checkState() {
        print("manager state:\(manager.state.rawValue)")
        switch manager.state {
        case .unsupported:
            delegates.forEach{$0.managerDidUpdate(error: .unsupported)}
        case .poweredOn:
            delegates.forEach{$0.managerDidUpdate(error: nil)}
        case .unauthorized:
            delegates.forEach{$0.managerDidUpdate(error:.unauthorized)}
        case .poweredOff:
            delegates.forEach{$0.managerDidUpdate(error:.powerOff)}
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
            delegates.forEach{$0.managerDidScan(peripheral.identifier, name: name)}
        }
    }
    
    func centralManager(_ centralManager: CBCentralManager, didConnect peripheral: CBPeripheral) {
        delegates.forEach{$0.managerDidConnect(peripheral.identifier, error:nil)}
    }
    
    func centralManager(_ centralManager: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("didFailToConnect \(peripheral.state == .connected)" )
        delegates.forEach{$0.managerDidConnect(peripheral.identifier, error: .systemError)}
    }
    
    func centralManager(_ centralManager: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("didDisconnectPeripheral \(peripheral.state == .connected)" )
        delegates.forEach{$0.managerDidDisconnect(peripheral.identifier, error: error == nil ? nil : .systemError)}
    }
}
