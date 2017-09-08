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

extension SimpleWorkbenchViewController{
    func loadSimulator() {
        view.addSubview(simulator)
        simulator.isUserInteractionEnabled = false
        simulator.isHidden = true
        simulator.frame = CGRect(x:50, y:0, width:view.bounds.width-50, height:view.bounds.height)
        let mask = UIView.init(frame: simulator.bounds)
        mask.backgroundColor = .black
        mask.alpha = 0.5
        simulator.addSubview(mask)
        simulator.addSubview(turtle)
        turtle.bounds = CGRect(x:0, y:0, width:30, height:42)
        turtle.center = CGPoint.init(x: simulator.bounds.width/2, y: simulator.bounds.height/2)
    }
    @objc func act() {
        timer?.invalidate()
        if running{
            simulator.isHidden = true
            running = false
        }else{
            simulator.isHidden = false
            running = true
            if case let str?? = try? workspace?.toXML(){
                vm?.performer.delegate = nil
                vm?.stop()
                vm = ABVirtulMachine.init(str)
                vm?.performer.delegate = self
                vm?.start()
            }
            turtle.transform = CGAffineTransform.identity
            turtle.center = CGPoint.init(x: simulator.bounds.width/2, y: simulator.bounds.height/2)
//            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) {_ in
//                switch arc4random()%3{
//                case 0:self.move(40)
//                case 1:self.turn(50)
//                case 2:self.color(Int(arc4random()%0xffffff))
//                default:Void()
//                }
//            }
        }
    }
    func move(_ step:Int) {
        UIView.animate(withDuration: 0.3, animations: {
            let size = CGSize.init(width: 0, height: -step).applying(self.turtle.transform)
            self.turtle.center = CGPoint.init(x: self.turtle.center.x+size.width, y: self.turtle.center.y+size.height)
        }) {_ in
            self.vm?.performer.endCurrent()
        }
    }
    func turn(_ angle:Int) {
        UIView.animate(withDuration: 0.3, animations: {
            self.turtle.transform = self.turtle.transform.rotated(by: CGFloat(angle)*180/CGFloat.pi)
        }) {_ in
            self.vm?.performer.endCurrent()
        }
    }
    func color(_ rgb:Int) {
        UIView.animate(withDuration: 0.3, animations: {
            self.turtle.tintColor = UIColor.init(rgb)
        }) {_ in
            self.vm?.performer.endCurrent()
        }
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
    func highlight(_ id:String){highlightBlock(blockUUID: id); print("\(#line) \(id)")}
    func unhighlight(_ id:String){unhighlightBlock(blockUUID: id); print("\(#line) \(id)")}
    func begin(_ cmd:String, values:[String]){
        print("\(#line) \(cmd) \(values)")
        switch cmd {
        case "turtle_move":
            move(Int(values.first ?? "") ?? 0)
        case "turtle_turn":
            turn(Int(values.first ?? "") ?? 0)
        case "turtle_color":
            color(Int(values.first ?? "") ?? 0)
        default:
            vm?.performer.endCurrent()
        }
    }
    func end(){unhighlightAllBlocks(); print("end \(#line)")}
}
