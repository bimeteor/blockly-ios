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
        reload()
    }
    @IBAction func onSlide(_ sender: UISwitch) {
        theme = sender.isOn
        reload()
    }
    fileprivate func reload(){
        let items = [0: ("Python", "rules_python", ABColorLexer.keywordsPython), 1: ("Typescript", "rules_typescript", ABColorLexer.keywordsTypescript), 2: ("Swift", "rules_swift", ABColorLexer.keywordsSwift), 3: ("Kotlin", "rules_kotlin", ABColorLexer.keywordsKotlin)]
        if let item = items[lang], let path = Bundle.main.path(forResource: item.1, ofType: nil), let rule = try? String.init(contentsOfFile: path) {
            let codes = ABTranslator.init(xml, rules: ABTranslator.parse(str: rule))?.codes ?? ""
            print("codes:" + codes)
            let lex = ABColorLexer.init(codes, keywords: item.2)
            let str = NSMutableAttributedString.init(string: codes)
            str.addAttributes([.foregroundColor:UIColor.white, .font:UIFont.init(name: "Menlo", size: 16) ?? UIFont.monospacedDigitSystemFont(ofSize: 16, weight: .regular)], range: NSRange.init(location: 0, length: str.length))
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
