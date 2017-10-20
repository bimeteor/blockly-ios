//
//  CodeViewController.swift
//  BlocklySample
//
//  Created by WG on 2017/10/20.
//  Copyright © 2017年 Google Inc. All rights reserved.
//

import Foundation
import UIKit

class CodeViewControler: UIViewController {
    private let xml:String
    private var lang = 0
    private var theme = true
    init(_ xml:String) {
        self.xml = xml
        super.init(nibName: nil, bundle: nil)
    }
    @IBOutlet weak var text: UITextView!
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        reload()
    }
    
    @IBAction func onSegment(_ sender: UISegmentedControl) {
        lang = sender.selectedSegmentIndex
    }
    @IBAction func onSlide(_ sender: UISwitch) {
        theme = sender.isOn
    }
    fileprivate func reload(){
        let pathes = [0: "rules_python", 1: "rules_swift", 2: "rules_kotlin"]
        if let path = Bundle.main.path(forResource: pathes[lang] ?? "", ofType: nil), let rule = try? String.init(contentsOfFile: path) {
            let codes = ABTranslator.init(xml, rules: ABTranslator.parse(str: rule))?.codes ?? ""
            let keys = [0: ABColorLexer.keywordsPython, 1: ABColorLexer.keywordsSwift, 2: ABColorLexer.keywordsKotlin]
            let lex = ABColorLexer.init(codes, keywords: keys[lang] ?? ABColorLexer.keywordsPython)
            let str = NSMutableAttributedString.init(string: codes)
            str.addAttributes([.foregroundColor:UIColor.white], range: NSRange.init(location: 0, length: str.length))
            let colors = ["comment":0x41cc45, "number":0x786cff, "operator":0xffffff, "keyword":0xd31995, "function":0x39fff]
            lex.colors.forEach{
                if let val = colors[$0.1.rawValue]{
                    str.addAttributes([.foregroundColor:UIColor.init(val)], range: $0.0)
                }
            }
            text?.backgroundColor = .black
            text?.attributedText = str
        }
    }
}
