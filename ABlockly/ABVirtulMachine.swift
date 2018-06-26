//
//  VirtulMachine.swift
//  XMLParser
//
//  Created by WG on 2017/8/9.
//  Copyright © 2017年 WG. All rights reserved.
//

import Foundation

fileprivate let stackTypes = ["control_if", "control_if_else", "control_repeat_forever", "control_repeat_ext", "control_repeat_until", "procedures_callnoreturn", "procedures_defnoreturn"]

fileprivate let loopTypes = ["control_repeat_forever", "control_repeat_ext", "control_repeat_until"]

public final class ABVirtulMachine: ABParser {
    public private(set) var performer:ABPerformer!
    private var paused = false
    private var running = false
    private var variables = [String:Int]()
    private var trunkCurrent:XMLNode?
    private var branckCurrent:XMLNode?
    private var trunkStack = [StackContext]()  //if, if-else, for, func
    private var branchStack = [StackContext]()
    public func start(){
        reset()
        running = true
        check()
    }
    public func stop(){
        if running{
            reset()
            performer.stop()
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
    class StackContext {
        let node:XMLNode
        var int0 = 0
        init(_ node:XMLNode) {
            self.node = node
        }
    }
    func `continue`(){
        if running && !paused{
            check()
        }
    }
    private func check(){
        next().map({performer.run($0)}){stop()}
    }
    private func reset(){
        trunkStack.removeAll()
        branchStack.removeAll()
        trunkCurrent = nil
        branckCurrent = nil
        paused = false
        running = false
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
        return nil   //first time on trunk
    }
    /*
     Loops enter several times, and others enter only once
     1. start types: judge and traverse
     2. struct types: return stmt if it exists, otherwise traverse
     3. others: traverse
     */
    private func next(_ node:XMLNode, stack:inout[StackContext]) -> XMLNode? {
        guard let type = node.attributes["type"] else { return nil }
        if stackTypes.contains(type) || type == "procedures_defnoreturn"{
            guard let context = stack.last else {return nil}
            if type == "control_if" || type == "control_if_else"{
                if let value = node["|block.value[name=IF0].block"], let stmt = node[performer.evaluate(value) == "true" ? "|block.statement[name=DO0].block" : "|block.statement[name=ELSE].block"]{
                    tryPush(stmt, stack: &stack)
                    return stmt
                }
            }else if type == "control_repeat_ext"{
                guard let limit = node["|block.value[name=TIMES].block"] else {return nil}
                if Int(performer.evaluate(limit)) ?? 0 > context.int0{
                    stack.last?.int0 += 1
                    return node["|block.statement[name=DO].block"].map{tryPush($0, stack: &stack); return $0} ?? node
                }
            }else if type == "control_repeat_until"{
                if let expr = node["|block.value[name=IF0].block"]{
                    if performer.evaluate(expr) == "false"{
                        return node["|block.statement[name=DO].block"].map{tryPush($0, stack: &stack); return $0} ?? node
                    }
                }else{
                    return node["|block.statement[name=DO].block"].map{tryPush($0, stack: &stack); return $0} ?? node
                }
            }else if type == "control_repeat_forever"{
                return node["|block.statement[name=DO].block"].map{tryPush($0, stack: &stack); return $0 } ?? node
            }else if type == "procedures_callnoreturn"{
                if let name = node["field[name=NAME]"], let def = funtions.first(where: {$0["field[name=NAME]"]?.value == name.value}){
                    return def
                }
            }else if type == "procedures_defnoreturn"{
                if let stmt = node["|block.statement[name=DO].block"]{
                    tryPush(stmt, stack: &stack)
                    return stmt
                }
            }
            stack.removeLast()
            return traverse(context.node, stack: &stack)
        }else if type != "start" && type.hasPrefix("start"){
            return performer.evaluate(node) == "true" ? traverse(node, stack:&stack) : nil
        }else if type == "restart"{
            let root = (stack.first?.node ?? node).root
            stack.removeAll()
            return traverse(root, stack:&stack)
        }
        return traverse(node, stack:&stack)
    }
    /*
     1. return next if it exists, otherwise traverse from its parent
     2. loop types are excluded, and need reentry to judge from times limit
     */
    private func traverse(_ node:XMLNode, stack:inout[StackContext])->XMLNode?{
        if let n = node["|block.next.block"]{
            tryPush(n, stack: &stack)
            return n
        }
        return stack.last.map{context->XMLNode? in
            if loopTypes.contains(context.node.attributes["type"] ?? ""){
                return context.node
            }else{
                stack.removeLast()
                return self.traverse(context.node, stack:&stack)
            }
        } ?? nil
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
