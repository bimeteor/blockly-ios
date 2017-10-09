//
//  Translator.swift
//  XMLParser
//
//  Created by WG on 2017/8/21.
//  Copyright © 2017年 WG. All rights reserved.
//

import Foundation

private let tab = "  "

public final class ABTranslator: ABParser {
    public private(set) var codes = ""
    public init?(_ xml:String, rules:[String:String]){
        self.rules = rules
        super.init(xml)
        var str = ""
        if funtions.count>0{
            str.append("//function declarations\n")
            funtions.forEach{str.append(code($0, depth: 0))}
            str.append("\n")
        }
        str.append("//trunk\n" + code(trunk, depth: 0))
        branches.enumerated().forEach{str.append("\n//branch \($0+1)\n" + code($1, depth: 0))}
        codes = str
    }
    private let rules:[String:String]
}

extension ABTranslator{
    private func code(_ node:XMLNode, depth:Int)->String{
        guard let type = node.attributes["type"], let rule = rules[type] else {return ""}
        var str = depth > 0 ? rule.replacingOccurrences(of: "\n", with: "\n" + repeated(depth, initial:""){$0 + tab}) : rule
        var offset = str.startIndex
        while true{ //repeat: find \(name[id=value]) and replace it
            if let range = str.range(of: "\\\\\\([a-zA-Z0-9\\[=\\]$]*\\)", options: .regularExpression, range: offset..<str.endIndex){
                var path = String(str[str.index(range.lowerBound, offsetBy: 2)..<str.index(before: range.upperBound)])
                let split = path.split(separator: "$")  //default value
                var def = ""
                if split.count>1{
                    path = String(split[0])
                    def = String(split[1])
                }
                if !path.hasPrefix("block"){    //add prefix block
                    path = "block." + path
                }
                if !path.hasSuffix("block") && !path.contains("field"){ //add suffix block
                    path += ".block"
                }

                var repl = ""
                node[path].map{
                    if $0.children.count == 0 {    //it's a field
                        repl = $0.value
                    }else if path.contains("statement") || type.hasPrefix("start"){
                        let c = code($0, depth: depth + 1)
                        if !c.isEmpty{
                            repl = "\n" + repeated(depth + 1, initial:""){$0 + tab} + c
                        }
                    }else{
                        repl = code($0, depth: depth)
                    }
                }
                let res = repl.isEmpty ? def : repl //replace
                str.replaceSubrange(range, with: res)
                offset = str.index(range.lowerBound, offsetBy: res.count)
            }else{
                break
            }
        }
        if !type.hasPrefix("start") {
            node["|block.next.block"].map{str.append("\n" + repeated(depth, initial:""){$0 + tab} + code($0, depth: depth))}
        }
        return str
    }
}
