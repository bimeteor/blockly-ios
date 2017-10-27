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

class BLKBaseViewController: WorkbenchViewController, ABPerformerDelegate, PresentViewControllerDelegate{
    
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
        btn1.addTarget(self, action: #selector(popout), for: .touchUpInside)
        
        view.addSubview(btn2)
        btn2.setImage(UIImage.init(named: "arrow"), for: .normal)
        btn2.frame = CGRect(x:view.bounds.width-50, y:55, width:50, height:50)
        btn2.addTarget(self, action: #selector(run), for: .touchUpInside)
        
        view.addSubview(btn3)
        btn3.setImage(UIImage.init(named: "arrow"), for: .normal)
        btn3.frame = CGRect(x:view.bounds.width-50, y:110, width:50, height:50)
        btn3.addTarget(self, action: #selector(showCode), for: .touchUpInside)
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    @objc func popout(){
        navigationController?.popViewController(animated: true)
    }
    
    @objc func run(){
        if case let str?? = try? workspace?.toXML(){
            print(str)
            vm?.performer.delegate = nil
            vm?.stop()
            vm = ABVirtulMachine.init(str)
            vm?.performer.delegate = self
            vm?.start()
        }
    }
    
    @objc func showCode(){
        if case let str?? = try? workspace?.toXML(){
            saveBlocks()
            let ctr = CodeViewControler(str)
            codeCtr = ctr
            ctr.modalPresentationStyle = .overCurrentContext
            ctr.modalTransitionStyle = .crossDissolve
            present(ctr, animated: true, completion: nil)
            ctr.delegate = self
        }
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
    <block type="start" id="255CBAB0-4DD5-4FFC-B8B1-B473F9707C2B" deletable="false" x="81" y="21" />
</xml>
"""
        var str = UserDefaults.standard.string(forKey: "blockly_xml_\(type(of: self))") ?? ""
        if !str.contains("deletable") { // 修复由于存储问题造成"start"块可以删除的缺陷
            str = def
        }
        if let xml = (try? AEXMLDocument(xml: str)) ?? (try? AEXMLDocument(xml: def)){
            try? workspace?.loadBlocks(fromXML: xml["xml"], factory: blockFactory)
        }
    }
    //ABPerformerDelegate
    func highlight(_ id: String) {
        
    }
    
    func unhighlight(_ id: String) {
        
    }
    
    func begin(_ cmd: String, value: Any) {
        
    }
    
    func end() {
        
    }
    //PresentViewControllerDelegate
    func onConfirm(_ ctr: UIViewController, obj:Any) {
        //        if let u = obj as? UUID {
        //            ble = bleManager[u]
        //        }
        //        ctr.dismiss(animated: true)
        //        connectCtr = nil
        //        codeCtr = nil
    }
    
    func onCancel(_ ctr: UIViewController) {
        ctr.dismiss(animated: true)
        //        connectCtr = nil
        codeCtr = nil
    }
    
    func onRead(_ ctr: UIViewController, obj: Any) {
        if ctr is SimulatorViewController {
            vm?.endCurrent()
        }
    }
}

protocol PresentViewControllerDelegate: class{
    func onConfirm(_ ctr: UIViewController, obj:Any)
    func onCancel(_ ctr: UIViewController)
    func onRead(_ ctr:UIViewController, obj:Any)
}
