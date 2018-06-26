//
//  Performer.swift
//  XMLParser
//
//  Created by WG on 2017/8/24.
//  Copyright © 2017年 WG. All rights reserved.
//
import Foundation
import UIKit

public protocol ABPerformerDelegate:class {
    func highlight(_ id:String, type:String)
    func unhighlight(_ id:String, type:String)
    func run(_ cmd:String, value:Any)
    func stop()
}

public final class ABPerformer: NSObject {
    public weak var delegate:ABPerformerDelegate?
    enum Direction:Int {
        case forward = 1, backward, left, right
        init?(_ str:String){
            switch str {
            case "forward":
                self.init(rawValue: 1)
            case "backward":
                self.init(rawValue: 2)
            case "left":
                self.init(rawValue: 3)
            case "right":
                self.init(rawValue: 4)
            default:
                self.init(rawValue: 0)
            }
        }
    }
    private weak var vm:ABVirtulMachine?
    private var variables = [String:[Int:Int]]()
    private var timer:Timer?
    private let timeInterval = 0.2
    private var current:XMLNode?
    private var replied = false
    private var beginTime = 0.0
    //may be delayed
    public func `continue`(){
        let t = CFAbsoluteTimeGetCurrent() - beginTime
        if t < timeInterval{
            timer = Timer.scheduledTimer(withTimeInterval: timeInterval - t, repeats: false){
                [unowned self] _ in
                self.continueSoon()
            }
        }else{
            continueSoon()
        }
    }
    public func update(_ value:Int, type:String, id:Int){
        var dict = variables[type] ?? [Int:Int]()
        dict[id] = value
        variables[type] = dict
    }
    init(_ vm:ABVirtulMachine) {
        super.init()
        self.vm = vm
    }
    
    deinit {
        timer?.invalidate()
    }
}

extension ABPerformer{
    func run(_ node:XMLNode) {
        replied = false
        timer?.invalidate()
        beginTime = CFAbsoluteTimeGetCurrent()
        current = node
        guard let id = node.attributes["id"] else{
            `continue`()
            return
        }
        delegate?.highlight(id, type: node.attributes["type"] ?? "")
        switch node.attributes["type"] ?? "" {
        case "": `continue`()
        case "control_wait":
            let itv = node["|block.value[name=delay].block"]?.value ?? ""
            timer = Timer.scheduledTimer(withTimeInterval: max(Double(itv) ?? 0, timeInterval), repeats: false){[unowned self] _ in
                self.continueSoon()
            }
        case "control_repeat_ext", "control_repeat_forever", "control_repeat_until", "control_if", "control_if_else", "restart":
            `continue`()
        case "control_wait_until":
            guard let n = node["|block.value[name=IF0].block"] else {return}
            timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true){
                if self.evaluate(n) == "true"{
                    $0.invalidate()
                    self.continueSoon()
                }
            }
        case "turtle_move":
            guard let n = node["|block.value[name=VALUE].block"] else {`continue`(); return}
            delegate?.run("turtle_move", value: Int(evaluate(n)) ?? 0)
        case "turtle_turn":
            guard let n = node["|block.field[name=DIR]"] else {`continue`(); return}
            delegate?.run("turtle_turn", value: evaluate(n))
        case "turtle_color":
            guard let n = node["|block.value[name=COLOUR].block"] else {`continue`(); return}
            delegate?.run("turtle_color", value: Int(evaluate(n)) ?? 0)
        case "move_action":
            guard let n = node["|block.field[name=ACTION]"] else {`continue`(); return}
            delegate?.run("move_action", value: evaluate(n))
        case "variables_set":
            guard let n = node["|block.value[name=VALUE].block"], let num = Int(evaluate(n)), let f = node["|block.field[name=VAR]"] else {`continue`(); return}
            update(num, type: evaluate(f), id: 1)
            `continue`()
        case "math_change":
            guard let n = node["|block.value[name=DELTA].block"], let num = Int(evaluate(n)), let f = node["|block.field[name=VAR]"] else {`continue`(); return}
            update(num, type: evaluate(f), id: 1)
            `continue`()
        case "light_left_right"://TODO:frank
            delegate?.run("light_left_right", value: "")
        case "move_speed_duration":
            guard let dir = node["|block.field[name=DIR]"], let speed = node["|block.field[name=SPEED]"], let num = node["|block.field[name=number]"] else {`continue`(); return}
            delegate?.run("move_speed_duration", value: (evaluate(dir), evaluate(speed), Int(evaluate(num)) ?? 0))
        case "move_speed":
            guard let dir = node["|block.field[name=DIR]"], let speed = node["|block.field[name=SPEED]"] else {`continue`(); return}
            delegate?.run("move_speed", value: (evaluate(dir), evaluate(speed)))
        case "move_stop":
            delegate?.run("move_stop", value: 0)
        case "move_myaction_duration"://TODO:frank
            delegate?.run("move_myaction_duration", value: 0)
        case "move_machine_rotate_duration":
            guard let id = node["|block.field[name=ID]"], let speed = node["|block.field[name=SPEED]"], let num = node["|block.field[name=number]"] else {`continue`(); return}
            delegate?.run("move_machine_rotate_duration", value: (Int(evaluate(id)) ?? 0, evaluate(speed), Int(evaluate(num)) ?? 0))
        case "move_machine_rotate_speed":
            guard let id = node["|block.field[name=ID]"], let speed = node["|block.field[name=SPEED]"], let dir = node["|block.field[name=DIR]"] else {`continue`(); return}
            delegate?.run("move_machine_rotate_speed", value: (Int(evaluate(id)) ?? 0, evaluate(dir), evaluate(speed)))
        case "light_playvoice_pat":
            guard let tune = node["|block.field[name=TUNE]"], let time = node["|block.field[name=TIME]"] else {`continue`(); return}
            delegate?.run("light_playvoice_pat", value: (evaluate(tune), Double(evaluate(time)) ?? 1))
        case "light_play_sound":
            guard let n = node["|block.field[name=SOUND]"] else {`continue`(); return}
            delegate?.run("light_play_sound", value: evaluate(n))
        case "light_myvoice":
            guard let n = node["|block.field[name=ID]"] else {`continue`(); return}
            delegate?.run("light_play_sound", value: Int(evaluate(n)) ?? 0)
        case "light_stop":
            delegate?.run("move_stop", value: 0)
        case "light_color_duration":
            break
        default:
            `continue`()
        }
    }
    //expr return: "left", "234", "true"/"false"
    func evaluate(_ node:XMLNode)->String{
        if node.name == "field" {
            return node.value
        }
        guard let type = node.attributes["type"] else{return ""}
        switch type{
        case "logic_compare":
            guard let a = node["|block.value[name=A].block"], let b = node["|block.value[name=B].block"], let op = node["|block.field"] else {return "false"}
            switch evaluate(op){
            case "=":return String(evaluate(a) == evaluate(b))
            case "!=":return String(evaluate(a) != evaluate(b))
            case ">":return String(Int(evaluate(a)) ?? 0 > Int(evaluate(b)) ?? 1)
            case ">=":return String(Int(evaluate(a)) ?? 0 >= Int(evaluate(b)) ?? 1)
            case "<":return String(Int(evaluate(a)) ?? 1 < Int(evaluate(b)) ?? 0)
            case "<=":return String(Int(evaluate(a)) ?? 1 <= Int(evaluate(b)) ?? 0)
            default:return "false"
            }
        case "math_arithmetic":
            guard let a = node["|block.value[name=A].block"], let b = node["|block.value[name=B].block"], let op = node["|block.field"] else {return "0"}
            switch evaluate(op){
            case "+":return String((Int(evaluate(a)) ?? 0) + (Int(evaluate(b)) ?? 0))
            case "-":return String((Int(evaluate(a)) ?? 0) - (Int(evaluate(b)) ?? 0))
            case "*":return String((Int(evaluate(a)) ?? 0) * (Int(evaluate(b)) ?? 0))
            case "/":
                let d = Int(evaluate(b)) ?? 1
                return String(d == 0 ? 39999999 : (Int(evaluate(a)) ?? 0) / d)
            default:return "0"
            }
        case "logic_operation":
            guard let a = node["|block.value[name=A].block"], let b = node["|block.value[name=B].block"], let op = node["|block.field"] else {return "false"}
            switch evaluate(op){
            case "AND":return String(evaluate(a) == "true" && evaluate(b) == "true")
            case "OR":return String(evaluate(a) == "true" || evaluate(b) == "true")
            default:return "false"
            }
        case "math_number":
            guard let field = node.children.first else{return "0"}
            return evaluate(field)
        case "color_picker":
            return node.children.first?.value.replacingOccurrences(of: "#", with: "") ?? "0"
        case "color_random":
            return String(arc4random() & 0xffffff)
        case "start_tilt":
            guard let n = node["|block.field[name=DIR]"] else{return "false"}
            if let val = variables["phone_tilt"]?[1], val > 0{
                return String(val == Direction.init(evaluate(n))?.rawValue)
            }
            return "false"
        case "start_barrier":
            if let val = variables["\(AccInfo.AccType.fir)"]?[1], val > 0{
                return String(val <= 14)
            }
            return "false"
        case "start_barrier_space":
            if let val = variables["\(AccInfo.AccType.fir)"]?[1], val > 0{
                guard let op = node["|block.field[name=OP]"], let n = node["|block.field[name=number]"], let num = Int(evaluate(n)) else {return "false"}
                return String(evaluate(op) == "<" ? val < num : val > num)
            }
            return "false"
        case "math_modulo":
            guard let m = node["|block.value[name=DIVIDEND].block"], let n = node["|block.value[name=DIVISOR].block"] else {return "0"}
            let mm = Int(evaluate(m)) ?? 0
            var nn = Int(evaluate(n)) ?? 1
            nn = nn == 0 ? 1 : nn
            return "\(mm % nn)"
        case "math_random_limit":
            guard let m = node["|block.value[name=FROM].block"], let n = node["|block.value[name=TO].block"] else {return "0"}
            let mm = Int(evaluate(m)) ?? 0
            let nn = Int(evaluate(n)) ?? 0
            let max1 = max(mm, nn, Int(Int32.min))
            let min1 = min(mm, nn, Int(Int32.max))
            if max1 == min1{
                return "\(max1)"
            }
            return "\(Int(arc4random()) % (max1 - min1) + min1)"
        case "math_random":
            return "\(arc4random()%1000)"
        case "math_round":
            guard let m = node["|block.value[name=NUM].block"] else {return "0"}
            let mm = Double(evaluate(m)) ?? 0
            return "\(Int(mm + 0.5))"
        case "logic_negate":
            guard let m = node["|block.value[name=BOOL].block"] else {return "true"}
            return evaluate(m) == "true" ? "false" : "true"
        case "variables_get":
            guard let f = node["|block.field[name=VAR]"] else {return "0"}
            return "\(variables[evaluate(f)]?[1] ?? 0)"
        default:
            return ""
        }
    }
    func stop() {
        if let id = current?.attributes["id"]{
            delegate?.unhighlight(id, type: current?.attributes["type"] ?? "")
        }
        current = nil
        timer?.invalidate()
        delegate?.stop()
    }
    func continueSoon(){
        if let id = current?.attributes["id"]{
            delegate?.unhighlight(id, type: current?.attributes["type"] ?? "")
        }
        current = nil
        timer?.invalidate()
        vm?.continue()
    }
}
