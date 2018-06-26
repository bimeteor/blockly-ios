//
//  Meebot.swift
//  BLE
//
//  Created by NewMan on 2017/2/7.
//  Copyright © 2017年 WG. All rights reserved.
//

import Foundation
import CoreBluetooth

let serviceStr = "49535343-FE7D-4AE5-8FA9-9FAFD205E455"
let readCharStr = "49535343-1E4D-4BD9-BA61-23C647249616"
let writeCharStr = "49535343-8841-43F4-A8D4-ECBE34729BB3"
//let serviceStr = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
//let readCharStr = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"
//let writeCharStr = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"

let cmdIndex = 3
let lenIndex = 2

public enum WritePriority:Int{
    case low = 1, normal, high, highest
}

public enum ConnectState:Int{
    case disconnected, connecting, connected, disconnecting
}

final class Bluetooth: NSObject {
    public weak var delegate:BluetoothDelegate?
    public let uuid:UUID
    public let name:String
    public private(set) var state:ConnectState = .disconnected
    public var handshaked:Bool {return handShakeStep == 100}
    fileprivate weak var manager:BluetoothManager?
    fileprivate var observer:NSKeyValueObservation!
    fileprivate let peripheral:CBPeripheral
    fileprivate var writeChar:CBCharacteristic?
    fileprivate let serviceUuid = CBUUID.init(string: serviceStr)
    fileprivate let readCharUuid = CBUUID.init(string: readCharStr)
    fileprivate let writeCharUuid = CBUUID.init(string: writeCharStr)
    fileprivate var contexts = [(UInt8, [UInt8], WritePriority)]()
    fileprivate var cmd:UInt8 = 0
    fileprivate var time:Double = 0
    fileprivate var buf = Data()
    
    //jimu
    fileprivate var handShakeStep = 0  //握手依次发1，8，5命令，如果8命令返回EE，则需要继续发8命令。收到回复则用命令号标记，握手成功，标志为100
    fileprivate var deviceInfo = DeviceInfo()//收到8命令会重新生成，一直缓存，不会删除
    fileprivate var accInfo = AccInfo()
    fileprivate var sensorSwitches = [AccInfo.AccType:Bool]()
    fileprivate var aliveTimer:Timer?
    fileprivate var powerTimer:Timer?//cmd 8 only
    fileprivate var delayTimer:Timer?
    fileprivate var sensorTimer:Timer?
    public func connect(){
        manager?.connect(uuid)
    }
    
    public func disconnect(){
        reset()
        manager?.disconnect(uuid)
    }
    
    public func verify(){
        peripheral.discoverServices(nil)
    }
    
    public func handshake(){
        guard let _ = writeChar, state == .connected else {//available to communicate
            delegate?.bluetoothDidHandshake(false)
            return
        }
        if handShakeStep == 100 {//handshake successfully
            delegate?.bluetoothDidHandshake(true)
        }else if handShakeStep == 0{//before handshaking
            write(1, array:[0])
        }
    }
    
    public func write(_ cmd:UInt8, array:[UInt8], priority:WritePriority = .normal){
        contexts.append((cmd, array, priority))
        tryWriting()
    }
    
    public func cancelAllWriting() {
        cmd = 0
        contexts.removeAll()
    }
    
    fileprivate func writeNow(_ cmd:UInt8, array:[UInt8]){
        if peripheral.state == .connected, let char = writeChar{
            peripheral.writeValue(Bluetooth.package(cmd, array: array), for: char, type: .withResponse)
        }
    }
    
    fileprivate func reset() {
        cmd = 0
        handShakeStep = 0
        buf.removeAll()
        sensorSwitches.removeAll()
        contexts.removeAll()
        aliveTimer?.invalidate()
        powerTimer?.invalidate()
        delayTimer?.invalidate()
        sensorTimer?.invalidate()
    }
    
    init(_ peripheral:CBPeripheral) {
        self.peripheral = peripheral
        uuid = peripheral.identifier
        name = peripheral.name ?? ""
        super.init()
        observer = peripheral.observe(\CBPeripheral.state){p, _ in
            self.state = ConnectState(rawValue: p.state.rawValue) ?? .disconnected
            if self.state == .disconnected{
                self.reset()
            }
        }
        state = ConnectState(rawValue: peripheral.state.rawValue) ?? .disconnected
        peripheral.delegate = self
    }
    
    deinit {
        observer.invalidate()
        peripheral.delegate = nil
    }
}

public enum VerifyError:Int{
    case unsupported = 1, systemError
}

public enum WriteError:Int{
    case unconnected = 1, unverified, unsupported, systemError
}

public enum ReadError:Int{
    case badResponse = 1, restarted, systemError
}

public protocol BluetoothDelegate: class{
    func bluetoothDidVerify(_ error:VerifyError?)
    func bluetoothDidWrite(_ cmd:UInt8, error:WriteError?)
    func bluetoothDidRead(_ data:(UInt8, [UInt8])?, error:ReadError?)
    
    func bluetoothDidHandshake(_ result:Bool)   //1，8，5命令回复正常
    func bluetoothDidUpdateDevice(_ info:DeviceInfo)
    func bluetoothDidUpdateAcc(_ info:AccInfo, type:AccInfo.AccType)
}

extension Bluetooth{
    fileprivate func tryWriting() {
        if cmd == 0, let tuple = contexts.first{
            if peripheral.state == .connected{
                if let char = writeChar{
                    aliveTimer?.invalidate()
                    contexts.removeFirst()
                    cmd = tuple.0
                    time = CFAbsoluteTimeGetCurrent()
                    peripheral.writeValue(Bluetooth.package(tuple.0, array: tuple.1), for: char, type: .withResponse)
                    print("trywriting:\(tuple)")
                }else{
                    onWrite(.unverified)
                }
            }else{
                onWrite(.unconnected)
            }
        }
    }
}

extension Bluetooth
{
    class func package(_ cmd:UInt8, array:[UInt8])->Data{
        var tmp = [0xfb, 0xbf, UInt8(array.count+5), cmd] + array
        var sum:UInt16=0
        for i in 2...tmp[2]-2 {
            sum += UInt16(tmp[Int(i)])
        }
        tmp.append(UInt8(sum & 0xff))
        tmp.append(0xed)
        return Data(tmp)
    }
    
    class func unpackage(_ array:[UInt8])->(cmd:Int, array:[UInt8]){
        return (cmd:Int(array[cmdIndex]), array:Array(array[4..<array.count-2]))
    }
    
    class func readDataFormatCheck(_ array:[UInt8]) -> Bool {
        return array.count>6 && array[0] == 0xfb && array[1] == 0xbf && array.last == 0xed
    }
    
    class func nameFilter(_ name:String)->Bool{
        return name.lowercased().contains("jimu")
    }
    
    class func devidePackage(_ data:Data)->(Int, [(UInt8, [UInt8])]){
        var i:Int = 0
        var arr = [(UInt8, [UInt8])]()
        while i+lenIndex<data.count {
            guard data[i] == 0xfb && data[i+1] == 0xbf else {return (-1, arr)}
            if data.count-i < Int(data[i+lenIndex])+1{
                break
            }else{
                guard data[i+Int(data[i+lenIndex])] == 0xed else {return (-1, arr)}
                arr.append((data[i+cmdIndex], Array(data[i+cmdIndex+1..<i+Int(data[i+lenIndex])-1])))
                i += 1+i+Int(data[i+lenIndex])
            }
        }
        return (i, arr)
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

public struct ServoErrorOption:OptionSet{
    public static var id:ServoErrorOption  {get{return ServoErrorOption(rawValue: 1)}}
    public static var version:ServoErrorOption {get{return ServoErrorOption(rawValue: 1<<1)}}
    public static var blocked:ServoErrorOption {get{return ServoErrorOption(rawValue: 1<<2)}}
    public static var temperature:ServoErrorOption {get{return ServoErrorOption(rawValue: 1<<3)}}
    public static var voltage:ServoErrorOption {get{return ServoErrorOption(rawValue: 1<<4)}}
    public static var current:ServoErrorOption {get{return ServoErrorOption(rawValue: 1<<5)}}
    public static var other:ServoErrorOption   {get{return ServoErrorOption(rawValue: 1<<6)}}
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

public struct AccInfo{
    public enum AccType:Int{
        case fir = 1, led = 4, color = 9
    }
    public var values = [AccInfo.AccType:[Int:Any]]()
    public var errors = [AccInfo.AccType:Set<Int>]()
}

public struct AccColor{
    public var color:UInt
    public var ch0:UInt16
    public var ch1:UInt16
    public var ch2:UInt16
    public var ch3:UInt16
}

public struct DeviceInfo {
    public var version:String?
    public var power:PowerInfo?
    public var servo:ServoInfo?
    public var accIds = [AccInfo.AccType:[Int]]()
    public var error = DeviceError(false)
}

let cmds_internal:[UInt8] = [1, 8, 5, 3, 0x27, 0x3b, 0x71, 0x7e]

extension Bluetooth{
    //duration:毫秒
    public func setAngles(_ angles:[UInt8?], duration:UInt) {
        var arr = [UInt8]()
        var flags:[UInt8] = [0,0,0,0]
        angles.enumerated().forEach{
            if let ee = $0.element {
                arr.append(ee)
                flags[3 - $0.offset/8] |= UInt8(1<<($0.offset%8))
            }
        }
        let time = duration/20
        let array = flags + arr + [UInt8(time & 0xff), UInt8((time & 0xff00)>>16), UInt8(time & 0xff)]
        write(9, array:array)
    }
    
    public func rotate(_ ids:[Int], dir:Int, speed:Int){
        var arr = [UInt8(ids.count)] + ids.map{UInt8($0)}
        arr += [UInt8(dir), UInt8((speed & 0xff00)>>8), UInt8(speed & 0xff)]
        write(7, array: arr)
    }
    
    public func startAcc(){
        if let ids = deviceInfo.accIds[.fir], !ids.isEmpty{
            sensorSwitches[.fir] = true
            writeNow(0x71, array: [UInt8(AccInfo.AccType.fir.rawValue), ids.reduce(UInt8(0)){$0 | (1 << ($1 - 1))}, 0])
            sensorTimer?.invalidate()
        }
        if let ids = deviceInfo.accIds[.color], !ids.isEmpty{
            sensorSwitches[.color] = true
            writeNow(0x71, array: [UInt8(AccInfo.AccType.color.rawValue), ids.reduce(UInt8(0)){$0 | (1 << ($1 - 1))}, 0])
            sensorTimer?.invalidate()
        }
        if let ids = deviceInfo.accIds[.led], !ids.isEmpty {
            writeNow(0x71, array: [UInt8(AccInfo.AccType.led.rawValue), ids.reduce(UInt8(0)){$0 | (1 << ($1 - 1))}, 0])
        }
    }
    
    public func stopAcc(){
        sensorSwitches[.fir] = false
        if let ids = deviceInfo.accIds[.fir], !ids.isEmpty{
            writeNow(0x71, array: [UInt8(AccInfo.AccType.fir.rawValue), ids.reduce(UInt8(0)){$0 | (1 << ($1 - 1))}, 1])
            sensorTimer?.invalidate()
        }
        if let ids = deviceInfo.accIds[.led], !ids.isEmpty {
            writeNow(0x71, array: [UInt8(AccInfo.AccType.led.rawValue), ids.reduce(UInt8(0)){$0 | (1 << ($1 - 1))}, 1])
        }
    }
    
    func onWrite(_ error:WriteError?) {
        if let e = error{
            delegate?.bluetoothDidWrite(cmd, error:e)
            disconnect()
        }
    }
    
    func onRead(_ data:(UInt8, [UInt8])?, error:ReadError?){
        aliveTimer?.invalidate()
        if handShakeStep == 100 {//handshake successfully, may be communicating with the device
            if let e = error{//report all errors include internal talks
                if e == .restarted{
                    delegate?.bluetoothDidRead(data, error: error)
                    handShakeStep = 0
                    handshake()
                }else{
                    delegate?.bluetoothDidRead(data, error: error)
                    disconnect()
                }
            }else{
                guard let t = data else{//data must exist
                    delegate?.bluetoothDidRead(nil, error: .systemError)
                    disconnect()
                    return
                }
                if (cmds_internal.contains(t.0)){//internal talks
                    var heartbeat = false
                    onReadInternal(t.0, array: t.1, heartbeat: &heartbeat)
                    if heartbeat{
                        aliveTimer = Timer.scheduledTimer(withTimeInterval: interval_alive, repeats: false, block: {_ in
                            self.write(3, array: [0])
                        })
                    }
                }else{//report user talks and activate the heartbeat timer
                    aliveTimer = Timer.scheduledTimer(withTimeInterval: interval_alive, repeats: false, block: {_ in
                        self.write(3, array: [0])
                    })
                    delegate?.bluetoothDidRead(t, error: nil)
                }
            }
        }else{//handshaking or not
            if let _ = error{//report a fail
                delegate?.bluetoothDidHandshake(false)
                disconnect()
            }else{
                guard let t = data else{//data must exist
                    delegate?.bluetoothDidHandshake(false)
                    disconnect()
                    return
                }
                if (cmds_internal.contains(t.0)){//only internal talks are in need
                    var heartbeat = false
                    onReadInternal(t.0, array: t.1, heartbeat: &heartbeat)
                    if heartbeat{
                        aliveTimer = Timer.scheduledTimer(withTimeInterval: interval_alive, repeats: false, block: {_ in
                            self.write(3, array: [0])
                        })
                    }
                }
            }
        }
    }
    
    //握手依次发1，8，5命令，如果8命令返回EE，则需要1s后重发8命令
    func onReadInternal(_ cmd:UInt8, array:[UInt8], heartbeat:inout Bool) {
        //连接成功且没有换连
        switch cmd {
        case 1:
            handShakeStep = 1
            write(8, array: [0])
        case 8:
            handShakeStep = 8
            switch array[0] {
            case 1:
                deviceInfo = DeviceInfo()
                deviceInfo.error.masterboard = true//master board error
                delegate?.bluetoothDidUpdateDevice(deviceInfo)
            case 0xEE://1s后重发一次
                delayTimer = Timer.scheduledTimer(withTimeInterval: interval_alive, repeats: false, block: {_ in
                    self.write(8, array: [0])
                })
            case 0:break//ignored
            default://if no error exists continue to send cmd 5 otherwise report info only
                guard array.count >= 27 else {
                    fatalError("cmd = 8 sub =0 length error")
                    break
                }
                updateInfo0x8(array)
                print(deviceInfo)
                delegate?.bluetoothDidUpdateDevice(deviceInfo)
                if deviceInfo.error.hasError {
                    break
                }
                write(5, array: [0])
            }
        case 5://may be reported automatically
            var first = false
            if handShakeStep == 8 {
                handShakeStep = 5
                first = true
            }
            switch array[0] {
            case 1://report low power
                deviceInfo.error.power = true
                delegate?.bluetoothDidUpdateDevice(deviceInfo)
            case 2:
                guard array.count >= 29 else {
                    fatalError("cmd = 5 sub =2 length error")
                    break
                }
                updateInfo0x5(array)
                if deviceInfo.error.hasError {
                    if deviceInfo.error.servo.contains(.blocked) {
                        if let v = deviceInfo.version {
                            if let r = v.range(of: "_p")  {
                                if !r.isEmpty {//可修复
                                    if v[r.upperBound...].compare("1.36") != .orderedAscending {
                                        write(0x3b, array: [0])
                                        let _ = deviceInfo.error.servo.remove(.blocked)
                                    }
                                }
                            }
                        }
                    }
                }
                delegate?.bluetoothDidUpdateDevice(deviceInfo)
            case 0://握手成功
                if first {
                    handShakeStep = 100
                    print("handshake successfully!")
                    write(0x27, array: [0])//query power info right away
                    delegate?.bluetoothDidHandshake(true)
                }
                heartbeat = true
            default:break
            }
        case 3:heartbeat = true//heartbeat
        case 0x27://power info
            if array.count==4 {
                updateInfo0x27(array)
                print("power info = \(deviceInfo.power)")
                delegate?.bluetoothDidUpdateDevice(deviceInfo)
                powerTimer?.invalidate()
                powerTimer = Timer.scheduledTimer(withTimeInterval: interval_power, repeats: false, block: {_ in
                    self.write(0x27, array: [0])
                })
                heartbeat = true
            }
        case 0x3b://auto-repairment
            switch array[0] {
            case 0:heartbeat = true//done
            case 0xee://report fail
                deviceInfo.error.servo.insert(.blocked)
                delegate?.bluetoothDidUpdateDevice(deviceInfo)
            default:break
            }
        case 0x71:updateInfo0x71(array)
        case 0x7e://temp
            guard array.count >= 7 else {break}
            guard let type = AccInfo.AccType(rawValue: Int(array[3])) else {break}
            if sensorSwitches[type] == true{
                if array[0] >= 1, array[1] >= 1, array[2] >= 1{
                    if type == .fir{
                        if array[4] != 0{
                            (0..<8).forEach{
                                if (1 << $0 & array[4]) != 0{
                                    if accInfo.errors[type] == nil{
                                        accInfo.errors[type] = Set()
                                    }
                                    accInfo.errors[type]?.insert($0 + 1)
                                }
                            }
                            sensorTimer?.invalidate()
                            delegate?.bluetoothDidUpdateAcc(accInfo, type: type)
                            break
                        }
                        if accInfo.values[type] == nil{
                            accInfo.values[type] = [Int:Any]()
                        }
                        accInfo.values[type]?[1] = infraredLevel((Int(array[6]) << 8) | Int(array[7]))
                        delegate?.bluetoothDidUpdateAcc(accInfo, type: type)
                    }else if type == .color{
                        if array[4] != 0{
                            (0..<8).forEach{
                                if (1 << $0 & array[4]) != 0{
                                    if accInfo.errors[type] == nil{
                                        accInfo.errors[type] = Set()
                                    }
                                    accInfo.errors[type]?.insert($0 + 1)
                                }
                            }
                            sensorTimer?.invalidate()
                            delegate?.bluetoothDidUpdateAcc(accInfo, type: type)
                            break
                        }
                        if accInfo.values[type] == nil{
                            accInfo.values[type] = [Int:Any]()
                        }
                        let col = UInt(array[6]) << 16 | UInt(array[7]) << 8 | UInt(array[8])
                        let val = AccColor(color: col, ch0: UInt16(array[9]) << 8 | UInt16(array[10]), ch1: UInt16(array[11]) << 8 | UInt16(array[12]), ch2: UInt16(array[13]) << 8 | UInt16(array[14]), ch3: UInt16(array[15]) << 8 | UInt16(array[16]))
                        accInfo.values[type]?[1] = val
                        delegate?.bluetoothDidUpdateAcc(accInfo, type: type)
                    }
                }
            }
        default:break
        }
    }
    
    func updateInfo0x8(_ array:[UInt8]){
        guard let v = String(data: Data(array[0..<10]), encoding: .utf8) else{
            fatalError("cmd = 8 point =version")
        }
        
        let p = Float(array[10])/10
        var info = DeviceInfo()
        info.version = v
        info.servo = ServoInfo()
        info.power = PowerInfo()
        info.power?.voltage = p
        info.error.power = p <= level_power_low
        //舵机重复编号
        if array[15] != 0 || array[16] != 0 || array[17] != 0 || array[18] != 0 {
            info.error.servo.insert(.id)
        }else{
            //舵机连续编号
            var idx = 0
            var count = 0
            for i in 0..<4 {
                let byte = Int(array[14-i])
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
            info.servo?.count = UInt(count)
        }
        
        //舵机版本不同
        if array[23] != 0 || array[24] != 0 || array[25] != 0 || array[26] != 0 {
            info.error.servo.insert(.version)
        }else{
            //舵机版本号
            var v:UInt = 0
            for i in 0..<4{
                v |= UInt(array[19 + i])<<(24 - i * 8)
            }
            info.servo?.version = v
        }
        var idx = 28
        if array.count >= idx && array[idx] != 0 {
            var ids = [Int]()
            (0..<8).forEach{
                if (1 << $0 & array[idx]) != 0{
                    ids.append($0 + 1)
                }
            }
            info.accIds[.fir] = ids
        }
        idx = 28 + 3 * 7
        if array.count >= idx && array[idx] != 0{
            var ids = [Int]()
            (0..<8).forEach{
                if (1 << $0 & array[idx]) != 0{
                    ids.append($0 + 1)
                }
            }
            info.accIds[.led] = ids
        }
        idx = 28 + 12 * 7
        if array.count >= idx && array[idx] != 0{
            var ids = [Int]()
            (0..<8).forEach{
                if (1 << $0 & array[idx]) != 0{
                    ids.append($0 + 1)
                }
            }
            info.accIds[.color] = ids
        }
        deviceInfo = info
    }
    
    func updateInfo0x5(_ array:[UInt8]) {
        var e = ServoErrorOption()
        var start = 0
        for i in start..<start+4 {
            if array[i] != 0 {
                e.insert(.blocked)
                break
            }
        }
        start += 4
        for i in start..<start+4 {
            if array[i] != 0 {
                e.insert(.current)
                break
            }
        }
        start += 4
        for i in start..<start+4 {
            if array[i] != 0 {
                e.insert(.temperature)
                break
            }
        }
        start += 4
        for i in start..<start+8 {
            if array[i] != 0 {
                e.insert(.voltage)
                break
            }
        }
        start += 8
        for i in start..<start+8 {
            if array[i] != 0 {
                e.insert(.other)
                break
            }
        }
        guard !e.isEmpty else {
            fatalError("error updateInfo0x5 empty")
        }
        deviceInfo.error.servo.insert(e)
    }
    
    func updateInfo0x27(_ array:[UInt8]) {
        guard array.count>=4 else {
            fatalError("updateInfo0x27 length")
        }
        deviceInfo.power?.charging = array[0] > 0
        deviceInfo.power?.complete = array[1] > 0
        deviceInfo.power?.voltage = Float(array[2])/10
        deviceInfo.power?.percent = Float(array[3])/100
        if array[0] > 0 {
            deviceInfo.error.power = false
        }else{
            deviceInfo.error.power = Float(array[2])/10 <= level_power_low
        }
    }
    
    func updateInfo0x71(_ array:[UInt8]) {
        guard array.count >= 3, let type = AccInfo.AccType(rawValue: Int(array[0])) else {return}
        switch (type){
        case .fir, .color:
            if array[2] == 1{
                (0..<8).forEach{
                    if (1 << $0 & array[1]) != 0{
                        if accInfo.errors[type] == nil{
                            accInfo.errors[type] = Set()
                        }
                        accInfo.errors[type]?.insert($0 + 1)
                    }
                }
                sensorTimer?.invalidate()
                delegate?.bluetoothDidUpdateAcc(accInfo, type: type)
            }else if array[2] == 0{
                sensorTimer?.invalidate()
                if let _ = writeChar, sensorSwitches[type] == true, let ids = deviceInfo.accIds[type], !ids.isEmpty{
                    let count = UInt8(ids.count)
                    let t = array[0]
                    let flag = ids.reduce(UInt8(0)){$0 | (1 << (UInt8($1) - 1))}
                    sensorTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true){
                        if self.sensorSwitches[type] == true{
                            self.writeNow(0x7e, array: [count, t, flag])
                        }else{
                            $0.invalidate()
                        }
                    }
                }
            }
//        case .led:break
        default:break
        }
    }
}

extension Bluetooth:CBPeripheralDelegate
{
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error == nil{
            if let e = peripheral.services?.first(where: {$0.uuid == serviceUuid}){
                peripheral.discoverCharacteristics([readCharUuid, writeCharUuid], for: e)
            }else{
                delegate?.bluetoothDidVerify(.unsupported)
            }
        }else{
            delegate?.bluetoothDidVerify(.systemError)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        var read:CBCharacteristic? = nil, write:CBCharacteristic? = nil
        service.characteristics?.forEach({
            if $0.uuid == readCharUuid {
                read = $0
            }else if $0.uuid == writeCharUuid{
                write = $0
            }
        })
        if let r = read, let w = write{
            peripheral.setNotifyValue(true, for: r)
            writeChar = w
            tryWriting()
            delegate?.bluetoothDidVerify(nil)
        }else{
            delegate?.bluetoothDidVerify(.unsupported)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let data = characteristic.value {
            print("didWriteValueFor \(data), error: \(error)" )
        }
        onWrite(error == nil ? nil : .systemError)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if error == nil{
            guard let data = characteristic.value else{return}
            if data == Data(bytes:[0]){//00
                onRead(nil, error: .restarted)
            }else{
                buf += data
                let tuple = Bluetooth.devidePackage(buf)
                if tuple.0 < 0{
                    onRead(nil, error: .badResponse)
                }else{
                    tuple.1.forEach{
                        onRead($0, error: nil)
                        if $0.0 == cmd{
                            cmd = 0
                            tryWriting()
                        }
                    }
                    buf = Data(buf[tuple.0...])
                }
            }
        }else{
            onRead(nil, error: .systemError)
        }
    }
}

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
    return Int(min(level, 20))
}
