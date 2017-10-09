//
//  XMLParser.swift
//  XMLParser
//
//  Created by Laughing(itouch@188.com) on 2017/8/5.
//  Copyright © 2017年 WG. All rights reserved.
//

import Foundation

public final class XMLNode:NSObject {
    public var name = ""
    public var attributes = [String:String]()
    public var value = ""
    public var children = [XMLNode]()
    public weak var parent:XMLNode?
    //decode
    public static func node(_ string:String)->XMLNode?{
        guard let data = string.data(using: .utf8) else {return nil}
        return XMLParse.init(data).root
    }
    //encode
    public var string: String{return string(0)}
    //convenience
    public var root:XMLNode{
        var node = self
        while let p = node.parent {node = p}
        return node
    }
    //depth first traverse
    public func forEach(_ body: (XMLNode)throws -> Void){
        try? body(self)
        children.forEach{$0.forEach(body)}
    }
    //depth first search
    public subscript(path: String) -> XMLNode? {
        let top = path.hasPrefix("|")
        let subs = path[path.index(path.startIndex, offsetBy: top ? 1 : 0)...].split(separator: ".").map{String($0)}
        let comps = subs.map{str->MatchType in
            var t = MatchType(names: [String](), key:"", values:[String]())
            let strs = str.split(separator: "[").map{String($0)}
            t.names = strs[0].split(separator: "/").map{String($0)}
            if strs.count > 1, let last = strs.last{
                let subsubs = last.replacingOccurrences(of: "]", with: "").split(separator: "=").map{String($0)}
                t.key = subsubs[0]
                if subsubs.count > 1, let l = subsubs.last{
                    t.values = l.split(separator: "/").map{String($0)}
                }
            }
            return t
        }
        guard comps.count > 0 else {return nil}
        var depth = 0
        var hit = true
        var node = self
        while true {
            if hit{    //before matching or the former components matches well
                if node.match(comps[depth]){ //match the current node & component
                    if depth == comps.count - 1{    //the last component matches well
                        return node
                    }else{
                        if node.children.isEmpty{   //flag to match uncle
                            hit = false
                            depth = max(depth - 1, 0)
                        }else{
                            node = node.children[0] //continue to match 1st child
                            depth += 1
                        }
                    }
                }else{
                    hit = false    //flag to brother
                }
            }else{  //continue to the match brother after a fail
                if depth == 0{  //match children with 1st component
                    if top {return nil}
                    var res:XMLNode?
                    let _ = node.children.first{e -> Bool in res = e[path]; return res != nil}
                    return res
                }else{
                    guard node != self, let p = node.parent, let i = p.children.index(of: node) else{return nil}
                    if i == p.children.count - 1{   //the last brother fails
                        node = p    //back to the parent
                        depth -= 1
                    }else{  //continue to match the next brother
                        node = p.children[i+1]
                        hit = true
                    }
                }
            }
        }
    }
    //optional
    public override var description: String{return string}
    public static func ==(lhs: XMLNode, rhs: XMLNode) -> Bool{
        if lhs === rhs{
            return true
        }else{
            return lhs.name == rhs.name && lhs.value == rhs.value && lhs.attributes == rhs.attributes
        }
    }
}

extension Optional{
    @inline(__always) public func map(_ block1:(Wrapped)->Void, block2:()->Void){
        if case let t? = self {
            block1(t)
        }else{
            block2()
        }
    }
}

public func repeated<T>(_ times:Int, initial:T, block:(T)->T)->T{
    var res = initial
    for i in 0..<times {
        res = block(res)
    }
    return res
}

//MARK: internal

fileprivate class XMLParse:NSObject {
    private let parser:XMLParser
    fileprivate let trimCharacters = CharacterSet.whitespacesAndNewlines.union(.controlCharacters)
    fileprivate var root, parent, current:XMLNode?
    fileprivate var value = ""
    fileprivate init(_ data:Data) {
        parser = XMLParser.init(data: data)
        super.init()
        parser.delegate = self
        parser.parse()
    }
    deinit {
        parser.delegate = nil
    }
}

extension XMLNode{
    fileprivate typealias MatchType = (names:[String], key:String, values:[String])
    fileprivate func match(_ tuple:MatchType)->Bool{
        if tuple.names.contains(name) {
            if !tuple.key.isEmpty{
                if let val = attributes[tuple.key]{
                    if !tuple.values.isEmpty{
                        return tuple.values.contains(val)
                    }else{return true}
                }else{return false}
            }else{return true}
        }else {return false}
    }
    
    fileprivate func string(_ depth:Int)->String{
        var str = ""
        if depth > 0 {
            str.append("\n" + repeated(depth, initial:""){$0 + " "})
        }
        str.append("<\(name)")
        attributes.forEach{str.append(" \($0)=\"\($1)\"")}
        str.append(">")
        if children.isEmpty {   //node without children:<name>value</name>
            str.append("\(value)</\(name)>")
        }else{  //node with a child at least:<name>\n...\n</name>
            children.forEach{str.append($0.string(depth + 1))}
            str.append("\n" + repeated(depth, initial:""){$0 + " "} + "</\(name)>")
        }
        return str
    }
}

extension XMLParse:XMLParserDelegate{
    public func parserDidStartDocument(_ parser: XMLParser) {
        root = nil
    }
    public func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        root = nil
    }
    public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        let node = XMLNode()
        node.name = elementName
        node.attributes = attributeDict
        current.map({$0.children.append(node); node.parent = $0}){root = node}//first node excluded or first node as root
        current = node
        value.removeAll()
    }
    public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        current?.value = value
        current = current?.parent
    }
    public func parser(_ parser: XMLParser, foundCharacters string: String) {
        value.append(string.trimmingCharacters(in: trimCharacters))
    }
}
