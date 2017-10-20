//
//  ABColor.swift
//  XMLParser
//
//  Created by WG on 2017/9/7.
//  Copyright © 2017年 WG. All rights reserved.
//

import Foundation

public let keywordsSwift = ["func", "for", "while", "in", "if", "else", "true", "false", "var"]

public final class ABColorLexer: NSObject {
    var colors = [(NSRange, Kind)]()
    enum Kind:String {
        case comment, `operator`, number, keyword, function, identifier
        var regex:String {
            switch self {
            case .comment: return "^//.*"
            case .number: return "^0x([1-9a-fA-F][1-9a-fA-F]*|[0-9a-fA-F])|^([1-9][0-9]+|[0-9])(.[0-9]+)?"
            case .identifier: return "^[a-zA-Z][_a-zA-Z0-9]*"
            case .operator: return "^[-+*/.,:<>=()\\[\\]{}&|]"
            default: return ""
            }
        }
    }
    init(_ codes:String, keywords:[String]) {
        super.init()
        var offset = codes.startIndex
        while offset < codes.endIndex {
            if let r = codes.range(of: Kind.comment.regex, options: .regularExpression, range: offset..<codes.endIndex){
                colors.append((NSRange.init(location: r.lowerBound.encodedOffset, length:r.upperBound.encodedOffset-r.lowerBound.encodedOffset), .comment))
                offset = r.upperBound
            }else if let r = codes.range(of: Kind.identifier.regex, options: .regularExpression, range: offset..<codes.endIndex){
                if keywords.contains(String(codes[r])){
                    colors.append((NSRange.init(location: r.lowerBound.encodedOffset, length:r.upperBound.encodedOffset-r.lowerBound.encodedOffset), .keyword))
                }else if r.upperBound < codes.endIndex, codes[r.upperBound] == "("{
                    colors.append((NSRange.init(location: r.lowerBound.encodedOffset, length:r.upperBound.encodedOffset-r.lowerBound.encodedOffset), .function))
                }else{
                    colors.append((NSRange.init(location: r.lowerBound.encodedOffset, length:r.upperBound.encodedOffset-r.lowerBound.encodedOffset), .identifier))
                }
                offset = r.upperBound
            }else if let r = codes.range(of: Kind.operator.regex, options: .regularExpression, range: offset..<codes.endIndex){
                colors.append((NSRange.init(location: r.lowerBound.encodedOffset, length:r.upperBound.encodedOffset-r.lowerBound.encodedOffset), .operator))
                offset = r.upperBound
            }else if let r = codes.range(of: Kind.number.regex, options: .regularExpression, range: offset..<codes.endIndex){
                colors.append((NSRange.init(location: r.lowerBound.encodedOffset, length:r.upperBound.encodedOffset-r.lowerBound.encodedOffset), .number))
                offset = r.upperBound
            }else{
                offset = codes.index(after: offset)
            }
        }
    }
}
