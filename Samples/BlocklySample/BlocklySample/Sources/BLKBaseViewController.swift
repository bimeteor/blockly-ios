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
import CoreMotion

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
    let btn1 = UIButton.init(type: .system)
    let btn2 = UIButton.init(type: .system)
    let btn3 = UIButton.init(type: .system)
    
    var running = false
    var paused = false
    var vm:ABVirtulMachine?
    lazy var motionManager:CMMotionManager = CMMotionManager()
    
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
        let titles = ["back", "action", "code"]
        let actions = [#selector(popout), #selector(ation), #selector(showCode)]
        [btn1, btn2, btn3].enumerated().forEach{
            view.addSubview($1)
            $1.frame = .init(x: Int(view.bounds.width) - 80, y: 20 + 40 * $0, width: 70, height: 30)
            $1.setTitle(titles[$0], for: .normal)
            $1.addTarget(self, action: actions[$0], for: .touchUpInside)
        }
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    func start() {
        if case let str?? = try? workspace?.toXML(){
            print(str)
            vm?.performer.delegate = nil
            vm?.stop()
            unhighlightAllBlocks()
            running = true
            paused = false
            vm = ABVirtulMachine.init(str)
            vm?.performer.delegate = self
            vm?.start()
            monitorTilt()
        }
    }
    
    func _stop() {
        motionManager.stopAccelerometerUpdates()
        running = false
        vm?.stop()
    }
    
    @objc func popout(){
        navigationController?.popViewController(animated: true)
    }
    
    @objc func ation(){
        start()
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
        let str = UserDefaults.standard.string(forKey: "blockly_xml_\(type(of: self))") ?? ""
        if let xml = try? AEXMLDocument(xml: str) {
            do{
                try workspace?.loadBlocks(fromXML: xml["xml"], factory: blockFactory)
            }catch{
                if let x = try? AEXMLDocument(xml: def){
                    try? workspace?.loadBlocks(fromXML: x["xml"], factory: blockFactory)
                }
            }
        }else if let x = try? AEXMLDocument(xml: def){
            try? workspace?.loadBlocks(fromXML: x["xml"], factory: blockFactory)
        }
    }
    //ABPerformerDelegate
    func highlight(_ id: String, type: String) {
        highlightBlock(blockUUID: id)
        print("highlight \(id) \(type)")
    }
    
    func unhighlight(_ id: String, type: String) {
        unhighlightBlock(blockUUID: id)
        print("unhighlight \(id) \(type)")
    }
    
    func run(_ cmd: String, value: Any) {
        
    }
    
    func stop() {
        unhighlightAllBlocks(); print("stop")
        running = false
    }
    //PresentViewControllerDelegate
    func onConfirm(_ ctr: UIViewController, obj:Any) {

    }
    
    func onCancel(_ ctr: UIViewController) {
        ctr.dismiss(animated: true)
        codeCtr = nil
    }
    
    func onOther(_ ctr: UIViewController, obj: Any) {
        if ctr is SimulatorViewController {
            vm?.performer.continue()
        }
    }
}

protocol PresentViewControllerDelegate: class{
    func onConfirm(_ ctr: UIViewController, obj:Any)
    func onCancel(_ ctr: UIViewController)
    func onOther(_ ctr:UIViewController, obj:Any)
}

extension BLKBaseViewController{
    func monitorTilt() {
        motionManager.accelerometerUpdateInterval = 1.0/20
        motionManager.startAccelerometerUpdates(to: OperationQueue.main) {
            if $1 == nil, let acc = $0{
                let x = acc.acceleration.x/acc.acceleration.z
                let y = acc.acceleration.y/acc.acceleration.z
                let cutX = 0.35
                let cutY = 0.3
                var res = ""
                if abs(x) >= cutX || abs(y) >= cutY{
                    let dir = UIApplication.shared.statusBarOrientation
                    if abs(x)/cutX > abs(y)/cutY{
                        if x >= cutX{
                            switch dir{
                            case .portrait:res = "right"
                            case .portraitUpsideDown:res = "left"
                            case .landscapeLeft:res = "forward"
                            case .landscapeRight:res = "backward"
                            default: res = ""
                            }
                        }else{
                            switch dir{
                            case .portrait:res = "left"
                            case .portraitUpsideDown:res = "right"
                            case .landscapeLeft:res = "backward"
                            case .landscapeRight:res = "forward"
                            default: res = ""
                            }
                        }
                    }else{//y
                        if y >= cutY{
                            switch dir{
                            case .portrait:res = "forward"
                            case .portraitUpsideDown:res = "backward"
                            case .landscapeLeft:res = "left"
                            case .landscapeRight:res = "right"
                            default: res = ""
                            }
                        }else{
                            switch dir{
                            case .portrait:res = "backward"
                            case .portraitUpsideDown:res = "forward"
                            case .landscapeLeft:res = "right"
                            case .landscapeRight:res = "left"
                            default: res = ""
                            }
                        }
                    }
                }
                self.vm?.performer.update(ABPerformer.Direction.init(res)?.rawValue ?? 0, type: "phone_tilt", id: 1)
            }
        }
    }
}
