//
//  BLKBaseViewController.swift
//  BlocklySample
//
//  Created by WG on 2017/10/26.
//  Copyright © 2017年 Google Inc. All rights reserved.
//

import Foundation
import Blockly
import AEXML

class BLKBaseViewController: WorkbenchViewController {
    
    init() {
        super.init(style: .defaultStyle)
    }
    
    required init?(coder aDecoder: NSCoder) {
        assertionFailure("Called unsupported initializer")
        super.init(coder: aDecoder)
    }
    var libPath:String?
    var toolPath:String?
    var codeCtr:CodeViewControler?
    let btn1 = UIButton.init(type: .custom)
    let btn2 = UIButton.init(type: .custom)
    let btn3 = UIButton.init(type: .custom)
    
    var running = false
    var paused = false
    var vm:ABVirtulMachine?
    override func viewDidLoad() {
        super.viewDidLoad()
        // Don't allow the navigation controller bar cover this view controller
        self.edgesForExtendedLayout = UIRectEdge()
        self.navigationItem.title = "Workbench with Default Blocks"
        // Load data
        loadBlockFactory()
        loadToolbox()
        loadBlocks()
        redoButton.isHidden = true
        undoButton.isHidden = true
        
        view.addSubview(btn1)
        btn1.setImage(UIImage.init(named: "arrow"), for: .normal)
        btn1.frame = CGRect(x:view.bounds.width-50, y:0, width:50, height:50)
        btn1.addTarget(self, action: #selector(pop), for: .touchUpInside)
        
        view.addSubview(btn2)
        btn2.setImage(UIImage.init(named: "arrow"), for: .normal)
        btn2.frame = CGRect(x:view.bounds.width-50, y:55, width:50, height:50)
//        btn2.addTarget(self, action: #selector(popupConnect), for: .touchUpInside)
        
        view.addSubview(btn3)
        btn3.setImage(UIImage.init(named: "arrow"), for: .normal)
        btn3.frame = CGRect(x:view.bounds.width-50, y:110, width:50, height:50)
//        btn3.addTarget(self, action: #selector(popupCode), for: .touchUpInside)
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    @objc func pop(){
        navigationController?.popViewController(animated: true)
    }
    
    func loadBlockFactory() {
        blockFactory.load(fromDefaultFiles: .allDefault)
        guard let path = libPath else {
            print("lib file unexists!")
            return
        }
        do {
            try blockFactory.load(fromJSONPath: path)
        } catch{
            print("The lib file's in illegal format!")
        }
    }
    
    func loadToolbox() {
        guard let path = toolPath else{
            print("toolbar file unexists!")
            return
        }
        do {
            let xmlString = try String(contentsOfFile: path, encoding: String.Encoding.utf8)
            let toolbox = try Toolbox.makeToolbox(xmlString: xmlString, factory: blockFactory)
            try loadToolbox(toolbox)
        } catch let error {
            print("An error occurred loading the toolbox: \(error)")
        }
    }
    func saveBlocks(){
        if case let str?? = try? workspace?.toXML(){
            UserDefaults.standard.set(str, forKey: "blockly_xml_\(type(of: self))")
            UserDefaults.standard.synchronize()
            print("xml:" + str)
        }
    }
    func loadBlocks(){
        let def = """
<?xml version="1.0" encoding="utf-8" standalone="no"?>
<xml xmlns="http://www.w3.org/1999/xhtml">
    <block x="81" type="start" id="255CBAB0-4DD5-4FFC-B8B1-B473F9707C2B" deletable="false" y="21" />
</xml>
"""
        let str = UserDefaults.standard.string(forKey: "blockly_xml_\(type(of: self))") ?? ""
        if let xml = (try? AEXMLDocument(xml: str)) ?? (try? AEXMLDocument(xml: def)){
            try? workspace?.loadBlocks(fromXML: xml["xml"], factory: blockFactory)
        }
    }
}
