//
//  CodeViewController.swift
//  BlocklySample
//
//  Created by WG on 2017/10/20.
//  Copyright © 2017年 Google Inc. All rights reserved.
//

import Foundation
import UIKit

extension CodeViewControler{
    fileprivate static let languages = [0: ("Python", "rules_python", ABColorLexer.keywordsPython), 1: ("Typescript", "rules_typescript", ABColorLexer.keywordsTypescript), 2: ("Swift", "rules_swift", ABColorLexer.keywordsSwift), 3: ("Kotlin", "rules_kotlin", ABColorLexer.keywordsKotlin)]
    fileprivate static let themes = [(UIColor.white, UIColor.black, ["comment":0x208813, "number":0x100aff, "operator":0x0, "keyword":0xb40061, "function":0x4c009f]), (UIColor.black, UIColor.white, ["comment":0x41cc45, "number":0x786cff, "operator":0xffffff, "keyword":0xd31995, "function":0x39fff])]
}

class CodeViewControler: UIViewController {
    private let xml:String
    private var langIdx = 0
    private var themeIdx = 0
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
        langIdx = sender.selectedSegmentIndex
        reload()
    }
    @IBAction func onSlide(_ sender: UISwitch) {
        themeIdx = sender.isOn ? 1 : 0
        reload()
    }
    fileprivate func reload(){
        if let item = CodeViewControler.languages[langIdx], let path = Bundle.main.path(forResource: item.1, ofType: nil), let rule = try? String.init(contentsOfFile: path) {
            let codes = ABTranslator.init(xml, rules: ABTranslator.parse(str: rule))?.codes ?? ""
            print("codes:" + codes)
            let lex = ABColorLexer.init(codes, keywords: item.2)
            let str = NSMutableAttributedString.init(string: codes)
            let theme = CodeViewControler.themes[themeIdx]
            str.addAttributes([.foregroundColor:theme.1, .font:UIFont.init(name: "Menlo", size: 16) ?? UIFont.monospacedDigitSystemFont(ofSize: 16, weight: .regular)], range: NSRange.init(location: 0, length: str.length))
            
            lex.colors.forEach{
                if let val = theme.2[$0.1.rawValue]{
                    str.addAttributes([.foregroundColor:UIColor.init(val)], range: $0.0)
                }
            }
            text?.attributedText = str
            text?.backgroundColor = theme.0
        }
    }
}
