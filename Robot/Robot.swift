//
//  Robot.swift
//  BLE
//
//  Created by WG on 2016/11/3.
//  Copyright © 2016年 WG. All rights reserved.
//

import Foundation
import CoreBluetooth

/*
 1.同时连接多个设备，而且可以和多个设备同时通信。可以指定设备名进行操作，也可以不指定设备名，使用最近连接上的设备
 2.所有接口只能在主线程调用，所有回调也只运行于主线程
 */

let serviceUuid = "49535343-FE7D-4AE5-8FA9-9FAFD205E455"
let readCharacteristicUuid = "49535343-1E4D-4BD9-BA61-23C647249616"
let writeCharacteristicUuid = "49535343-8841-43F4-A8D4-ECBE34729BB3"
let lengthIndex = 2
let identifierIndex = 3

open class Robot:NSObject{
    override init(){
        super.init()
        bluetooth = Bluetooth(serviceUuid: CBUUID(string:serviceUuid), queue: dispatchQueue)
        bluetooth.delegate = self
        bluetooth.nameFilter = {Robot.nameFilter($0)}
        bluetooth.identifierIndex = identifierIndex
        bluetooth.serviceUuid = CBUUID(string:serviceUuid)
        bluetooth.readCharacteristicUuid = CBUUID(string:readCharacteristicUuid)
        bluetooth.writeCharacteristicUuid = CBUUID(string:writeCharacteristicUuid)
        bluetooth.readDataFormatCheck = {Robot.readDataFormatCheck($0)}
        bluetooth.writeDataFormatCheck = {Robot.writeDataFormatCheck($0)}
        bluetooth.devidePackage = {Robot.devidePackage($0)}
    }
    
    public lazy var dispatchQueue = DispatchQueue.main
    public weak var delegate:RobotProtocol?
    public var deviceInfo:Data?
    //仅在指定线程安全
    public var currentConnectedUuid:UUID?{
        get{
            if let uuid = _currentConnectedUuid{
                if bluetooth.connectState(uuid) == .connected{
                    return uuid
                }
            }
            _currentConnectedUuid = nil
            return nil
        }
    }
    
    public var scannedPeers:Dictionary<UUID, String>{
        get{
            let arr = _scannedPeers
            return arr
        }
    }
    
    public func update(){
        self.bluetooth.update()
    }
    
    public func scan(){
        _scannedPeers.removeAll()
        self.bluetooth.scan()
    }
    
    public func stopScan(){
        self.bluetooth.stopScan()
    }
    
    //回调是robotDidConnect。连接成功的话会自动发1，8，5命令握手。如果握手成功则会收到回调robotDidHandShake
    public func connect(_ uuid:UUID){
        print("robot connect")
        currentConnectingUuid = uuid
        if uuid == _currentConnectedUuid{
            self.delegate?.robotDidConnect(uuid, error: nil)
        }else{
            _currentConnectedUuid = nil
            self.bluetooth.connect(uuid)
        }
    }
    
    public func connectLast(){
        dispatchQueue.async {
            //            self.bluetooth.scan()
        }
    }
    
    // no error reported if uuid is wrong
    public func disconnect(_ uuid:UUID? = nil){
        var tmp = uuid
        if tmp == nil{
            tmp = _currentConnectedUuid
        }
        if tmp == nil{
            self.delegate?.robotDidDisconnect(nil, error:nil)
        }else{
            aliveTimers[tmp!]?.invalidate()
            powerTimers[tmp!]?.invalidate()
            handShakeSteps[tmp!] = nil
            if tmp == _currentConnectedUuid{
                _currentConnectedUuid = nil
            }
            self.bluetooth.disconnect(tmp!)
        }
    }
    
    //回调是robotDidReceive，但两者不是一对一的关系。
    public func write(_ data:Data, uuid:UUID? = nil){
        var tmp = uuid
        if tmp == nil{
            tmp = _currentConnectedUuid
        }
        if tmp == nil{
            self.delegate?.robotDidReceive(nil, response: nil, error: .unconnected)
        }else{
            self.bluetooth.write(tmp!, data:data)
            aliveTimers[tmp!]?.invalidate()
        }
    }
    
    public func cancelAllWriting(_ uuid:UUID?){
        var tmp = uuid
        if tmp == nil{
            tmp = _currentConnectedUuid
        }
        if tmp == nil{
            self.delegate?.robotDidCancelAllWriting(nil)
        }else{
            self.bluetooth.cancelAllWriting(tmp!)
        }
    }
    
    public func deviceInfo(_ uuid:UUID? = nil)->DeviceInfo?{
        var tmp = uuid
        if tmp == nil{
            tmp = _currentConnectedUuid
        }
        if tmp == nil{
            return nil
        }else{
            return deviceInfos[tmp!]
        }
    }
    
    //private
    var bluetooth:Bluetooth!
    lazy var _scannedPeers = Dictionary<UUID, String>()//<uuid:name>
    var currentConnectingUuid:UUID?
    var _currentConnectedUuid:UUID?
    lazy var handShakeSteps = Dictionary<UUID, Int>()  //握手依次发1，8，5命令，如果8命令返回EE，则需要继续发8命令。收到回复则用命令号标记，握手成功，标志为100
    lazy var deviceInfos = Dictionary<UUID, DeviceInfo>()//收到8命令会重新生成，一直缓存，不会删除
    lazy var aliveTimers = Dictionary<UUID, Timer>()
    lazy var powerTimers = Dictionary<UUID, Timer>()
}

public protocol RobotProtocol:NSObjectProtocol {
    func robotDidUpdate(error:PhoneStateError?)
    func robotDidScan(_ uuid:UUID, name:String)
    func robotWillConnect(_ uuid:UUID)
    func robotDidConnect(_ uuid:UUID, error:ConnectError?)
    func robotDidReceive(_ uuid:UUID?, response:Data?, error:TransmissionError?)
    func robotDidCancelAllWriting(_ uuid:UUID?)
    func robotDidDisconnect(_ uuid:UUID?, error:DisconnectError?)
    
    func robotDidHandShake(_ uuid:UUID)   //1，8，5命令回复正常
    func robotDidUpdateDevice(_ uuid:UUID, info:DeviceInfo)
}

extension Robot:BluetoothProtocol
{
    func bluetoothDidUpdate(error:PhoneStateError?){
        delegate?.robotDidUpdate(error: error)
        if error != nil {
            aliveTimers.forEach({
                $1.invalidate()
            })
            powerTimers.forEach({
                $1.invalidate()
            })
        }
    }
    
    func bluetoothDidScan(_ uuid: UUID, name:String){
        if _scannedPeers[uuid] == nil{
            _scannedPeers[uuid] = name
            delegate?.robotDidScan(uuid, name:name)
        }
    }
    
    func bluetoothWillConnectTo(_ uuid:UUID, name:String) {
        self.connect(uuid)
    }
    
    
    func bluetoothDidConnect(_ uuid:UUID, error: ConnectError?) {
        print("bluetoothDidConnect")
        delegate?.robotDidConnect(uuid, error:error)
        if error == nil{
            onConnected(uuid)
        }else{
            _currentConnectedUuid = nil
        }
    }
    
    func bluetoothDidDisconnect(_ uuid: UUID, error: DisconnectError?){
        aliveTimers[uuid]?.invalidate()
        powerTimers[uuid]?.invalidate()
        if uuid == _currentConnectedUuid{
            _currentConnectedUuid = nil
        }
        delegate?.robotDidDisconnect(uuid, error:error)
    }
    
    func bluetoothDidReceive(_ uuid:UUID, response:Data?, error:TransmissionError?, moreCammands:Bool) {
        aliveTimers[uuid]?.invalidate()
        if error == nil{
            //补00的漏洞
            if response == Data(bytes:[0]){
                disconnect(uuid)
                connect(uuid)
            }else{
                onReceived(uuid, response: response!, moreCammands:moreCammands)
            }
        }else{
            delegate?.robotDidReceive(uuid, response: response, error:error)
        }
    }
    
    func bluetoothDidCancelWriting(_ uuid: UUID) {
        
    }
}

/*
 1.握手
 1）蓝牙连接成功后，握手依次发1，8，5命令，如果8命令返回EE，则需要继续发8命令
 2）换连或断连都会停止握手
 2.心跳
 1）从握手成功开始，每收到消息若空闲3秒就发送
 2）收到消息且写列表为空时开始计时
 3）写数据，收到数据，换连，主动或被动断连，会取消计时
 3.电量
 1）从握手成功开始，3分钟请求一次
 2）换连，主动或被动断连，会取消计时
 3）连接和断开交流电时主板会主动上报0x27命令
 */

let interval_alive = 3.0
let interval_power = 180.0
let level_power_low:Float = 6.5

extension Robot{
    
    public func writeRawArray(_ array:[UInt8], uuid:UUID? = nil) {
        write(Data(Robot.package(array:array)), uuid:uuid)
    }
    
    //duration:毫秒
    public func setServos(_ angles:[UInt8?], duration:UInt, uuid:UUID? = nil) {
        var arr = [UInt8]()
        var flags:[UInt8] = [0,0,0,0]
        for (i, e) in angles.enumerated() {
            if let ee = e {
                arr.append(ee)
                flags[3 - i/8] |= UInt8(1<<(i%8))
            }
        }
        let time = duration/20
        let array = [UInt8(9)] + flags + arr + [UInt8(time & 0xff), UInt8((time & 0xff00)>>16), UInt8(time & 0xff)]
        writeRawArray(array, uuid:uuid)
    }
    
    func onConnected(_ uuid:UUID) {
        writeRawArray([1,0], uuid:uuid)
        handShakeSteps[uuid] = 0
    }
    
    //握手依次发1，8，5命令，如果8命令返回EE，则需要1s后重发8命令
    func onReceived(_ uuid:UUID, response:Data, moreCammands:Bool) {
        let t = Robot.unpackage(response)
        print("onReceived cmd = \(t.cmd) step = \(handShakeSteps[uuid] ?? 0)")
        //连接成功且没有换连
        if currentConnectingUuid == uuid && handShakeSteps[uuid] != nil {
            let tuple = Robot.unpackage(response)
            print("onReceived cmd = \(tuple.cmd) data = \(tuple.data.string) more = \(moreCammands)")
            print("onReceived cmd = \(tuple.cmd) more = \(moreCammands)")
            switch tuple.cmd {
            case 1:
                handShakeSteps[uuid] = 1
                writeRawArray([8,0], uuid:uuid)
                break
            case 8:
                handShakeSteps[uuid] = 8
                switch tuple.data[0] {
                case 1:
                    let info = DeviceInfo(uuid, error:DeviceError(true))
                    deviceInfos[uuid] = info
                    delegate?.robotDidUpdateDevice(uuid, info: info)
                    break
                case 0xEE:
                    //1s后重发一次
                    dispatchQueue.asyncAfter(deadline: DispatchTime.now()+1, execute: {
                        if self.currentConnectingUuid == uuid {
                            self.writeRawArray([8,0], uuid:uuid)
                        }
                    })
                    break
                case 0:
                    break
                default:
                    guard tuple.data.count >= 49 else {
                        fatalError("cmd = 8 sub =0 length error")
                        break
                    }
                    updateInfo0x8(uuid, data: tuple.data)
                    print(deviceInfos[uuid] ?? 0)
                    if let i = deviceInfos[uuid] {
                        delegate?.robotDidUpdateDevice(uuid, info: i)
                    }
                    if let e = deviceInfos[uuid]?.error {
                        if e.hasError {
                            break
                        }
                    }
                    writeRawArray([5,0], uuid:uuid)
                    break
                }
                break
            case 5:
                var first = false
                if handShakeSteps[uuid] == 8 {
                    handShakeSteps[uuid] = 5
                    first = true
                }
                switch tuple.data[0] {
                case 1:
                    deviceInfos[uuid]?.error.power = true
                    if let i = deviceInfos[uuid] {
                        delegate?.robotDidUpdateDevice(uuid, info: i)
                    }
                    break
                case 2:
                    guard tuple.data.count >= 29 else {
                        fatalError("cmd = 5 sub =2 length error")
                        break
                    }
                    updateInfo0x5(uuid, data: tuple.data)
                    if let info = deviceInfos[uuid] {
                        if info.error.hasError {
                            if info.error.servo.contains(.blocked) {
                                if let v = info.version {
                                    if let r = v.range(of: "_p")  {
                                        if !r.isEmpty {
                                            //可修复
                                            if v[r.upperBound...].compare("1.36") != .orderedAscending {
                                                writeRawArray([0x3b,0])
                                                _ = deviceInfos[uuid]?.error.servo.remove(.blocked)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    if let i = deviceInfos[uuid] {
                        delegate?.robotDidUpdateDevice(uuid, info: i)
                    }
                    break
                case 0:
                    //握手成功
                    if first {
                        _currentConnectedUuid = uuid
                        handShakeSteps[uuid] = 100
                        print("did shaked \(uuid)")
                        writeRawArray([0x27,0])
                        delegate?.robotDidHandShake(uuid)
                    }
                    if !moreCammands {
                        aliveTimers[uuid] = Timer.scheduledTimer(withTimeInterval: interval_alive, repeats: false, block: {_ in
                            if (uuid == self._currentConnectedUuid) {
                                self.writeRawArray([3,0])
                            }
                        })
                    }
                    break
                default:
                    break
                }
                break
            case 3://心跳，不上报
                if !moreCammands {
                    aliveTimers[uuid] = Timer.scheduledTimer(withTimeInterval: interval_alive, repeats: false, block: {_ in
                        if (uuid == self._currentConnectedUuid) {
                            self.writeRawArray([3,0])
                        }
                    })
                }
                break
            case 0x27:
                if tuple.data.count==4 {
                    updateInfo0x27(uuid, data: tuple.data)
                    print("power info = \(deviceInfos[uuid]?.power)")
                    if let i = deviceInfos[uuid] {
                        delegate?.robotDidUpdateDevice(uuid, info: i)
                    }
                }
                powerTimers[uuid]?.invalidate()
                powerTimers[uuid] = Timer.scheduledTimer(withTimeInterval: interval_power, repeats: false, block: {_ in
                    if (uuid == self._currentConnectedUuid) {
                        self.writeRawArray([0x27,0])
                    }
                })
                if !moreCammands {
                    aliveTimers[uuid] = Timer.scheduledTimer(withTimeInterval: interval_alive, repeats: false, block: {_ in
                        if (uuid == self._currentConnectedUuid) {
                            self.writeRawArray([3,0])
                        }
                    })
                }
                break
            case 0x3b:
                switch tuple.data[0] {
                case 0:
                    if !moreCammands {
                        aliveTimers[uuid] = Timer.scheduledTimer(withTimeInterval: interval_alive, repeats: false, block: {_ in
                            if (uuid == self._currentConnectedUuid) {
                                self.writeRawArray([3,0])
                            }
                        })
                    }
                    break
                case 0xee:
                    if deviceInfos[uuid] != nil {
                        deviceInfos[uuid]?.error.servo.insert(.blocked)
                        delegate?.robotDidUpdateDevice(uuid, info: deviceInfos[uuid]!)
                        if let i = deviceInfos[uuid] {
                            delegate?.robotDidUpdateDevice(uuid, info: i)
                        }
                    }
                    break
                default:
                    break
                }
                break
            default:
                if !moreCammands {
                    aliveTimers[uuid] = Timer.scheduledTimer(withTimeInterval: interval_alive, repeats: false, block: {_ in
                        if (uuid == self._currentConnectedUuid) {
                            self.writeRawArray([3,0])
                        }
                    })
                }
                delegate?.robotDidReceive(uuid, response: response, error: nil)
                break
            }
        }
    }
    
    func updateInfo0x8(_ uuid:UUID, data:Data){
        guard let v = String(data: data.subdata(in: 0..<10), encoding: .utf8) else{
            fatalError("cmd = 8 point =version")
        }
        
        let p = Float(data[10])/10
        var info = DeviceInfo(uuid, error:DeviceError(false))
        info.version = v
        info.servo = ServoInfo()
        info.power = PowerInfo()
        info.power?.voltage = p
        info.error.power = p <= level_power_low
        //舵机重复编号
        if data[15] != 0 || data[16] != 0 || data[17] != 0 || data[18] != 0 {
            info.error.servo.insert(.id)
        }else{
            //舵机连续编号
            var idx = 0
            var count = 0
            for i in 0..<4 {
                let byte = Int(data[14-i])
                for j in 0..<8 {
                    idx += 1
                    if (byte & 1<<j) != 0 {
                        count += 1
                        if idx != count {
                            count = 0
                            break
                        }
                    }
                }
            }
            
            if count == 0 {
                info.error.servo.insert(.number)
            }else{
                info.servo?.count = UInt(count)
            }
        }
        
        //舵机版本不同
        if data[23] != 0 || data[24] != 0 || data[25] != 0 || data[26] != 0 {
            info.error.servo.insert(.version)
        }else{
            //舵机版本号
            info.servo?.version = 8// UInt(data[19])<<24 | UInt(data[20])<<16 | UInt(data[21])<<8 | UInt(data[22])
        }
        deviceInfos[uuid] = info
    }
    
    func updateInfo0x5(_ uuid:UUID, data:Data) {
        var e = ServoErrorOption()
        var start = 0
        for i in start..<start+4 {
            if data[i] != 0 {
                e.insert(.blocked)
                break
            }
        }
        start += 4
        for i in start..<start+4 {
            if data[i] != 0 {
                e.insert(.current)
                break
            }
        }
        start += 4
        for i in start..<start+4 {
            if data[i] != 0 {
                e.insert(.temperature)
                break
            }
        }
        start += 4
        for i in start..<start+8 {
            if data[i] != 0 {
                e.insert(.voltage)
                break
            }
        }
        start += 8
        for i in start..<start+8 {
            if data[i] != 0 {
                e.insert(.other)
                break
            }
        }
        guard !e.isEmpty else {
            fatalError("error updateInfo0x5 empty")
        }
        deviceInfos[uuid]?.error.servo.insert(e)
    }
    
    func updateInfo0x27(_ uuid:UUID, data:Data) {
        guard data.count>=4 else {
            fatalError("updateInfo0x27 length")
        }
        if deviceInfos[uuid]?.power != nil {
            deviceInfos[uuid]?.power?.charging = data[0] > 0
            deviceInfos[uuid]?.power?.complete = data[1] > 0
            deviceInfos[uuid]?.power?.voltage = Float(data[2])/10
            deviceInfos[uuid]?.power?.percent = Float(data[3])/100
            if data[0] > 0 {
                deviceInfos[uuid]?.error.power = false
            }else{
                deviceInfos[uuid]?.error.power = Float(data[2])/10 <= level_power_low
            }
        }
    }
}

extension Robot
{
    public var lastConnectedName:String?{get{return nil}}
}

extension Robot
{
    class func package(data:Data)->Data{
        var tmp = Data([0xfb, 0xbf, UInt8(data.count+4)])
        tmp.append(data)
        var sum:UInt16=0
        for i in 2...tmp[2]-2 {
            sum += UInt16(tmp[Int(i)])
        }
        tmp.append(UInt8(sum & 0xff))
        tmp.append(0xed)
        return tmp
        
    }
    
    class func package(array:[UInt8])->[UInt8]{
        var tmp = [0xfb, 0xbf, UInt8(array.count+4)]
        tmp += array
        var sum:UInt16=0
        for i in 2...tmp[2]-2 {
            sum += UInt16(tmp[Int(i)])
        }
        tmp.append(UInt8(sum & 0xff))
        tmp.append(0xed)
        return tmp
    }
    
    class func unpackage(_ data:Data)->(cmd:Int, data:Data){
        return (cmd:Int(data[identifierIndex]), data:data.subdata(in: 4..<data.count-2))
    }
    
    class func writeDataFormatCheck(_ data:Data) -> Bool {
        return data.count>6 && data[0] == 0xfb && data[1] == 0xbf && data.last == 0xed
    }
    
    class func readDataFormatCheck(_ data:Data) -> Bool {
        return data.count>6 && data[0] == 0xfb && data[1] == 0xbf && data.last == 0xed
    }
    
    class func nameFilter(_ name:String)->Bool{
        return name.lowercased().contains("jimu")
    }
    
    class func devidePackage(_ data:Data)->[Data]?{
        var i:Int = 0
        var arr = [Data]()
        while i+2<data.count {
            if data[i] == 0xfb && data[i+1] == 0xbf && data.count-i >= Int(data[i+2])+1 && data[i+Int(data[i+2])] == 0xed {
                arr.append(data.subdata(in: i..<1+i+Int(data[i+2])))
                i += 1+i+Int(data[i+2])
            }else{
                break
            }
        }
        return arr.count>0 ? arr : nil
    }
}

extension Data
{
    public var string:String{
        get
        {
            var str = ""
            for ch in self {
                str.append(String(format: "%02X", ch))
            }
            return str
        }
    }
}

public struct ServoErrorOption:OptionSet{
    public static var number:ServoErrorOption {get{return ServoErrorOption(rawValue: 1)}}
    public static var id:ServoErrorOption  {get{return ServoErrorOption(rawValue: 1<<1)}}
    public static var version:ServoErrorOption {get{return ServoErrorOption(rawValue: 1<<2)}}
    public static var blocked:ServoErrorOption {get{return ServoErrorOption(rawValue: 1<<3)}}
    public static var temperature:ServoErrorOption {get{return ServoErrorOption(rawValue: 1<<4)}}
    public static var voltage:ServoErrorOption {get{return ServoErrorOption(rawValue: 1<<5)}}
    public static var current:ServoErrorOption {get{return ServoErrorOption(rawValue: 1<<6)}}
    public static var other:ServoErrorOption   {get{return ServoErrorOption(rawValue: 1<<7)}}
    public var rawValue: UInt
    public init(rawValue: UInt){
        self.rawValue = rawValue
    }
}

public struct DeviceError {
    public var masterboard:Bool
    public var power:Bool?
    public var servo = ServoErrorOption()
    public init(_ masterboard:Bool){
        self.masterboard = masterboard
    }
    public var hasError:Bool{return masterboard || power ?? false || !servo.isEmpty}
}

public struct PowerInfo {
    public var voltage:Float?
    public var percent:Float?
    public var charging:Bool?
    public var complete:Bool?
}

public struct ServoInfo {
    public var count:UInt?
    public var version:UInt?
}

public struct DeviceInfo {
    public let uuid:UUID
    public var version:String?
    public var power:PowerInfo?
    public var servo:ServoInfo?
    public var error:DeviceError
    public init(_ uuid:UUID, error:DeviceError){
        self.uuid = uuid
        self.error = error
    }
}
