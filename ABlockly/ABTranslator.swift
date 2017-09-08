//
//  Translator.swift
//  XMLParser
//
//  Created by WG on 2017/8/21.
//  Copyright © 2017年 WG. All rights reserved.
//

import Foundation

public final class ABTranslator: ABParser {
    public private(set) var codes = ""
    public init?(_ xml:String, rules:[String:String]){
        self.rules = rules
        super.init(xml)
        var str = ""
        if funtions.count>0{
            str.append("//function declarations\n")
            funtions.forEach{str.append(code($0, depth: 0))}
        }
        
        if !str.isEmpty {str.append("\n")}
        
        if let first = trunk["|block.next.block"]{
            str.append("//trunk\n")
            str.append(code(first, depth: 0))
        }
        
        branches.enumerated().forEach{
            str.append("\n//branch \($0+1)\n")
            str.append(code($1, depth: 0))
        }
        codes = str
    }
    private let rules:[String:String]
}

extension ABTranslator{
    private func code(_ node:XMLNode, depth:Int)->String{
        guard let type = node.attributes["type"], let rule = rules[type] else {return ""}
        var str = depth > 0 ? rule.replacingOccurrences(of: "\n", with: "\n\(repeatElement("    ", count: depth).joined())") : rule
        var offset = str.startIndex
        while true{
            if let r = str.range(of: "\\\\\\([a-zA-Z0-9\\[\\=\\]$]*\\)", options: .regularExpression, range: offset..<str.endIndex){
                var path = String(str[str.index(r.lowerBound, offsetBy: 2)..<str.index(before: r.upperBound)])
                let split = path.split(separator: "$")
                var def = ""
                if split.count>1{
                    path = String(split[0])
                    def = String(split[1])
                }
                if !path.hasPrefix("block"){
                    path = "block." + path
                }
                if !path.hasSuffix("block") && !path.contains("field"){
                    path += ".block"
                }

                var repl = ""
                if let subnode = node[path]{
                    if subnode.children.count == 0 {
                        repl = subnode.value
                    }else if path.contains("statement"){
                        let c = code(subnode, depth: depth + 1)
                        if !c.isEmpty{
                            repl = "\n" + repeatElement("    ", count: depth + 1).joined() + c
                        }
                    }else{
                        repl = code(subnode, depth: depth)
                    }
                }
                let res = repl.isEmpty ? def : repl
                str.replaceSubrange(r, with: res)
                offset = str.index(r.lowerBound, offsetBy: res.count)
            }else{
                break
            }
        }
        if let next = node["|block.next.block"]{
            str.append("\n" + repeatElement("    ", count: depth).joined() + code(next, depth: depth))
        }
        return str
    }
}
