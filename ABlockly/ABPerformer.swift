//
//  Performer.swift
//  XMLParser
//
//  Created by WG on 2017/8/24.
//  Copyright © 2017年 WG. All rights reserved.
//
import Foundation

public protocol ABPerformerDelegate:class {
    func highlight(_ id:String)
    func unhighlight(_ id:String)
    func begin(_ array:[String])
    func end()
}

public final class ABPerformer: NSObject {
    public weak var delegate:ABPerformerDelegate?
    
    private weak var vm:ABVirtulMachine?
    private var timer:Timer?
    private var timeInterval = 0.2
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
        case "control_wait_until":
            timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true){
                [unowned self] t in
                if true{
                    t.invalidate()
                    self.endSoon()
                }
            }
        case "control_repeat_times", "control_repeat_until", "control_repeat_always", "control_if", "control_if_else", "restart":
            endCurrent()
        case "motion_move":
            delegate?.begin([])
        default:
            endCurrent()
        }
    }
    //expr
    func evaluate(_ node:XMLNode)->Int{
        if node.children.isEmpty {
            return Int(node.value) ?? 0
        }
        guard let type = node.attributes["type"] else{return 0}
        switch type{
        case "logic_compare":
            guard let a = node["|block.value[name=A].block"], let b = node["|block.value[name=B].block"], let op = node["|block.field"] else {return 0}
            switch op.value{
            case "=":return Int(evaluate(a) == evaluate(b))
            case ">":return Int(evaluate(a) > evaluate(b))
            case ">=":return Int(evaluate(a) >= evaluate(b))
            case "<":return Int(evaluate(a) < evaluate(b))
            case "<=":return Int(evaluate(a) <= evaluate(b))
            default:return 0
            }
        case "math_arithmetic":
            guard let a = node["|block.value[name=A].block"], let b = node["|block.value[name=B].block"], let op = node["|block.field"] else {return 0}
            switch op.value{
            case "+":return evaluate(a) + evaluate(b)
            case "-":return evaluate(a) - evaluate(b)
            case "*":return evaluate(a) * evaluate(b)
            case "/":
                let d = evaluate(b)
                return d == 0 ? 39999999 : evaluate(a) / d
            default:return 0
            }
        case "logic_operation":
            guard let a = node["|block.value[name=A].block"], let b = node["|block.value[name=B].block"], let op = node["|block.field"] else {return 0}
            switch op.value{
            case "AND":return Int(evaluate(a) == 1 && evaluate(b) == 1)
            case "OR":return Int(evaluate(a) == 1 || evaluate(b) == 1)
            default:return 0
            }
        case "math_number":
            guard let field = node.children.first, let val = Int(field.value) else{return 0}
            return val
        default:
            return 0
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
