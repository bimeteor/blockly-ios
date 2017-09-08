//
//  SimpleWorkbenchViewController+Addition.swift
//  BlocklySample
//
//  Created by WG on 2017/9/8.
//  Copyright © 2017年 Google Inc. All rights reserved.
//

import Foundation
import UIKit

extension SimpleWorkbenchViewController{
    func run() {
        if let path = Bundle.main.path(forResource: "src", ofType: "xml"), let str = try? String.init(contentsOfFile: path){
            vm = ABVirtulMachine(str)
            vm?.performer.delegate = self
            vm?.start()
        }
    }
    func translate() {
        if let path = Bundle.main.path(forResource: "src", ofType: "xml"), let str = try? String.init(contentsOfFile: path){
            if let url = Bundle.main.url(forResource: "rules_swift", withExtension: "json"), let data = try? Data.init(contentsOf: url), let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String:String], let js = json {
                print(ABTranslator.init(str, rules: js)?.codes ?? "")
            }
        }
    }
    func color() {
        let lex = ABColorLexer.init(codes, keywords: keywordsSwift)
        let lbl = UILabel.init(frame: CGRect(x:20, y:20, width:400, height:400))
        view.addSubview(lbl)
        lbl.numberOfLines = 0
        lbl.backgroundColor = .black
        lbl.font = UIFont.init(name: "Menlo", size: 18)
        //        lbl.font = UIFont.init(name: "Courier New", size: 19)
        let str = NSMutableAttributedString.init(string: codes)
        str.addAttributes([.foregroundColor:UIColor.white], range: NSRange.init(location: 0, length: str.length))
        let colors = ["comment":0x41cc45, "number":0x786cff, "operator":0xffffff, "keyword":0xd31995, "function":0x39fff]
        lex.colors.forEach{
            if let val = colors[$0.1.rawValue]{
                str.addAttributes([.foregroundColor:UIColor.init(val)], range: $0.0)
            }
        }
        lbl.attributedText = str
    }
}

extension UIColor{
    @inline(__always)
    public convenience init(_ rgb:Int) {
        self.init(red: CGFloat((rgb & 0xff0000)>>16)/255.0, green: CGFloat((rgb & 0xff00)>>8)/255.0, blue: CGFloat(rgb & 0xff)/255.0, alpha: 1)
    }
}

let codes = """
for _ in 0..<10
{
move(dir:.forward, len:50)
turn(dir:.right, angle:90)
color(0xff0000)
}
//branch
if 5 == 5
{
move(dir:.forward, len:12+18)
}else
{
turn(dir:.right, angle:90)
}
"""
extension SimpleWorkbenchViewController:ABPerformerDelegate{
    func highlight(_ id:String){print("\(#line) \(id)")}
    func unhighlight(_ id:String){print("\(#line) \(id)")}
    func begin(_ array:[String]){print("\(#line) \(array)")}
    func end(){print("\(#line)")}
}
