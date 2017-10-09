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
    func highlight(_ id:String)
    func unhighlight(_ id:String)
    func begin(_ cmd:String, values:[String])
    func end()
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
    public func endCurrent(){
        let t = CFAbsoluteTimeGetCurrent() - beginTime
        if t < timeInterval{
            timer = Timer.scheduledTimer(withTimeInterval: timeInterval - t, repeats: false){
                [unowned self] _ in
                self.endSoon()
            }
        }else{
            endSoon()
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
    func begin(_ node:XMLNode) {
        replied = false
        timer?.invalidate()
        beginTime = CFAbsoluteTimeGetCurrent()
        current = node
        guard let id = node.attributes["id"] else{
            endCurrent()
            return
        }
        delegate?.highlight(id)
        switch node.attributes["type"] ?? "" {
        case "": endCurrent()
        case "control_wait":
            let itv = node["|block.value[name=delay].block"]?.value ?? ""
            timer = Timer.scheduledTimer(withTimeInterval: max(Double(itv) ?? 0, timeInterval), repeats: false){[unowned self] _ in
                self.endSoon()
            }
        case "control_wait_until":Void()//TODO:frank
//            timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true){
//                [unowned self] t in
//                if true{
//                    t.invalidate()
//                    self.endSoon()
//                }
//            }
        case "control_repeat_times", "control_repeat_until", "control_repeat_always", "control_if", "control_if_else", "restart":
            endCurrent()
        case "turtle_move":
            guard let n = node["|block.value[name=VALUE].block"] else {endCurrent(); return}
            delegate?.begin("turtle_move", values: ["\(evaluate(n))"])
        case "turtle_turn":
            guard let n = node["|block.value[name=VALUE].block"] else {endCurrent(); return}
            delegate?.begin("turtle_turn", values: ["\(evaluate(n))"])
        case "turtle_color":
            guard let n = node["|block.value[name=COLOUR].block"] else {endCurrent(); return}
            delegate?.begin("turtle_color", values: ["\(evaluate(n))"])
        default:
            endCurrent()
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
        default:
            return ""
        }
    }
    func end() {
        if let id = current?.attributes["id"]{
            delegate?.unhighlight(id)
        }
        current = nil
        timer?.invalidate()
        delegate?.end()
    }
    func endSoon(){
        if let id = current?.attributes["id"]{
            delegate?.unhighlight(id)
        }
        current = nil
        timer?.invalidate()
        vm?.endCurrent()
    }
}
