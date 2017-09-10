//
//  VirtulMachine.swift
//  XMLParser
//
//  Created by WG on 2017/8/9.
//  Copyright © 2017年 WG. All rights reserved.
//

import Foundation

public final class ABVirtulMachine: ABParser {
    public var performer:ABPerformer!
    private var paused = false
    private var running = false
    private var variables = [String:Int]()
    private var trunkCurrent:XMLNode?
    private var branckCurrent:XMLNode?
    private var trunkStack = [StackContext]()  //if, if-else, for, func
    private var branchStack = [StackContext]()
    private let stackTypes = ["controls_if", "controls_if_else", "controls_repeat_ext", "procedures_callnoreturn", "procedures_defnoreturn"]
    public func start(){
        reset()
        running = true
        check()
    }
    public func stop(){
        if running{
            reset()
            performer.end()
        }
    }
    public func pause(){
        if running && !paused{
            paused = true
        }
    }
    public func resume(){
        if running && paused{
            paused = false
            check()
        }
    }
    override init?(_ xml: String) {
        super.init(xml)
        performer = ABPerformer(self)
    }
}

extension ABVirtulMachine{
    enum StackOperate {
        case push, update, pop
    }
    class StackContext: NSObject {
        let node:XMLNode
        var status = StackOperate.push
        var int0 = 0
        init(_ node:XMLNode) {
            self.node = node
            super.init()
        }
        var type:String{return node.attributes["type"] ?? ""}
    }
    func endCurrent(){
        if running && !paused{
            check()
        }
    }
    private func check(){
        if let n = next(){
            performer.begin(n)
        }else{
            stop()
        }
    }
    private func reset(){
        trunkStack.removeAll()
        branchStack.removeAll()
        trunkCurrent = nil
        branckCurrent = nil
        paused = false
        running = true
    }

    private func next()->XMLNode?{
        let branch = (branchStack.first?.node ?? branckCurrent)?.root
        for b in branches{  //start another branch
            var stack = [StackContext]()
            if b != branch, let n = next(b, stack:&stack){
                branchStack.replaceSubrange(0..<branchStack.count, with: stack)
                branckCurrent = n
                return n
            }
        }
        if let b = branch, let c = branckCurrent{ //if branch exist
            if let n = next(c, stack:&branchStack){ //continue if the end isn't reached
                branckCurrent = n
                return n
            }
            branchStack.removeAll()
            branckCurrent = nil
            if let n = next(b, stack:&branchStack){    //relaunch when the end is reached if possible
                branckCurrent = n
                return n
            }
        }

        if let n = next(trunkCurrent ?? trunk, stack:&trunkStack){  //back to trunk
            trunkCurrent = n
            return n
        }
        reset()
        return nil   //first time on trunk
    }
    //inside or outside
    private func next(_ node:XMLNode, stack:inout[StackContext]) -> XMLNode? {
        guard let type = node.attributes["type"] else { return nil }
        var next = node
        if stackTypes.contains(type) || type == "procedures_defnoreturn"{
            guard let context = stack.last else {return nil}
            next = context.node
            if type == "controls_if" || type == "controls_if_else"{
                if context.status == .push{
                    if let value = node["|block.value[name=IF0].block"], let stmt = node[performer.evaluate(value) == 1 ? "|block.statement[name=DO0].block" : "|block.statement[name=ELSE].block"]{
                        stack.last?.status = .update
                        tryPush(stmt, stack: &stack)
                        return stmt
                    }
                }
            }else if type == "controls_repeat_ext"{
                if context.status == .push || context.status == .update{//TODO:frank <field name="number">10</field>
                    if let limit = node["|block.field[name=number]"], performer.evaluate(limit) > context.int0, let stmt = node["|block.statement[name=DO].block"]{
                        stack.last?.status = .update
                        stack.last?.int0 += 1
                        tryPush(stmt, stack: &stack)
                        return stmt
                    }
                }
            }else if type == "control_repeat_until"{
                
            }else if type == "control_repeat_always"{
                
            }else if type == "procedures_callnoreturn"{
                if context.status == .push{
                    if let name = node["field[name=NAME]"], let def = funtions.first(where: {$0["field[name=NAME]"]?.value == name.value}){
                        return def
                    }
                }
            }else if type == "procedures_defnoreturn"{
                if let stmt = node["|block.statement[name=STACK].block"]{
                    stack.last?.status = .update
                    tryPush(stmt, stack: &stack)
                    return stmt
                }
            }else if type == "start_tilt"{
                if performer.evaluate(node) == 1{
                    return traverse(node, stack:&stack)
                }
            }
            stack.removeLast()
        }else if type == "restart"{
            let root = (stack.first?.node ?? node).root
            stack.removeAll()
            guard let n = root["|block.next.block"] else {return nil}
            tryPush(n, stack: &stack)
            return n
        }
        return traverse(next, stack: &stack)
    }
    //brother or parent
    private func traverse(_ node:XMLNode, stack:inout[StackContext])->XMLNode?{
        if let n = node["|block.next.block"]{   //find its own next
            tryPush(n, stack: &stack)
            return n
        }
        if let context = stack.last {
            switch context.node.attributes["type"] ?? ""{
            case "":
                return nil
            case "controls_repeat_ext":
                return context.node
            default:
                context.status = .pop
                return next(context.node, stack:&stack)
            }
        }
        return nil
    }
    private func tryPush(_ node:XMLNode, stack:inout[StackContext]){
        guard let type = node.attributes["type"] else{return}
        if stackTypes.contains(type){
            stack.append(StackContext(node))
        }
    }
}

extension Int{
    public init(_ value:Bool) {
        self.init(value ? 1 : 0)
    }
}
