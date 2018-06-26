//
//  Translator.swift
//  XMLParser
//
//  Created by WG on 2017/8/21.
//  Copyright © 2017年 WG. All rights reserved.
//

import Foundation

private let tab = "   "

public final class ABTranslator: ABParser {
    public private(set) var codes = ""
    public init?(_ xml:String, rules:[String:String]){
        self.rules = rules
        super.init(xml)
        var str = ""
        if funtions.count>0{
            str.append("//function declarations\n")
            funtions.forEach{str.append(code($0))}
            str.append("\n")
        }
        str.append("//trunk\n" + code(trunk))
        branches.enumerated().forEach{str.append("\n//branch \($0+1)\n" + code($1))}
        codes = str
    }
    public static func parse(str:String)->[String:String]{
        var map = [String:String]()
        str.components(separatedBy: ",\n").forEach{
            let arr = $0.components(separatedBy: "::\n")
            if arr.count > 1{
                map[arr[0].trimMargin()] = arr[1].trimMargin()
            }
        }
        return map
    }
    private let rules:[String:String]
}

extension String{
    public func trimStart()->String{
        if let idx = index(where: {$0 != " " && $0 != "\n"}) {
            return String(self[idx...])
        }else{
            return ""
        }
    }
    public func trimEnd()->String{
        if let idx = reversed().index(where: {$0 != " " && $0 != "\n"})?.base {
            return String(self[..<idx])
        }else{
            return ""
        }
    }
    public func trimMargin()->String{
        if let idx1 = index(where: {$0 != " " && $0 != "\n"}), let idx2 = reversed().index(where: {$0 != " " && $0 != "\n"})?.base {
            return String(self[idx1..<idx2])
        }else{
            return ""
        }
    }
}

extension ABTranslator{
    private func space(_ string:String)->String{
        if let start = string.reversed().index(of: "\n")?.base, let end = string[start...].index(where: {$0 != " " && $0 != "\n"}){
            return String(string[start..<end])
        }
        return ""
    }
    private func code(_ node:XMLNode)->String{
        guard let type = node.attributes["type"], let rule = rules[type] else {return ""}
        var str = rule
        var values = 0   //number of paras, to determine whether '()' is needed
        var other = 0   //number of other symbols, to determine whether '()' is needed
        var offset = str.startIndex
        while true{ //repeat: find \(name[id=value]) and replace it
            if let range = str.range(of: "\\\\\\([a-zA-Z0-9\\[=\\]$]*\\)", options: .regularExpression, range: offset..<str.endIndex){
                var path = String(str[str.index(range.lowerBound, offsetBy: 2)..<str.index(before: range.upperBound)])
                if path.hasPrefix("value"){
                    values += 1
                }else{
                    other += 1
                }
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
                    if $0.name == "field" {    //it's a field, an embeded expr
                        repl = $0.value
                    }else if path.contains("statement") || type.hasPrefix("start"){//sub statement
                        var c = code($0)
                        if !c.isEmpty{
                            if let idx = str[str.startIndex..<range.lowerBound].reversed().index(where: {$0 == "\n"})?.base{
                                c = c.replacingOccurrences(of: "\n", with: "\n" + str[idx..<range.lowerBound])
                            }
                            repl = c
                        }
                    }else{//embeded expr
                        repl = code($0)
                    }
                }
                let res = repl.isEmpty ? def : repl //replace
                str.replaceSubrange(range, with: res)
                offset = str.index(range.lowerBound, offsetBy: res.count)
            }else{
                break
            }
        }
        if !type.hasPrefix("start") {   //next
            node["|block.next.block"].map{str += "\n" + code($0)}
        }
        if node.parent?.name == "value" && values >= 2 && other >= 1{//placed in '()' if a expr has 2 or more paras
            str = "(" + str + ")"
        }
        return str
    }
}
