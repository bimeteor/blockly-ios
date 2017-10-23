/*
 * Copyright 2015 Google Inc. All Rights Reserved.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import UIKit
import Blockly
import CoreMotion
import AEXML

class SimpleWorkbenchViewController: WorkbenchViewController {
    // MARK: - Initializers
    
    init() {
        super.init(style: .defaultStyle)
    }
    
    required init?(coder aDecoder: NSCoder) {
        assertionFailure("Called unsupported initializer")
        super.init(coder: aDecoder)
    }
    
    let simulator = UIView()
    let turtle = UIImageView.init(image: UIImage.init(named: "turtle")?.withRenderingMode(.alwaysTemplate))
    
    let bleManager = BluetoothManager.init()
    var bles:Bluetooth?
    var connectCtr:ConnectViewControler?
    var codeCtr:CodeViewControler?
    
    let connectBtn = UIButton.init(type: .custom)
    let codeBtn = UIButton.init(type: .custom)
    
    var running = false
    var paused = false
    var vm:ABVirtulMachine?
    var motionManager:CMMotionManager?
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
        
        let btn = UIButton.init(type: .custom)
        view.addSubview(btn)
        btn.setImage(UIImage.init(named: "arrow"), for: .normal)
        btn.frame = CGRect(x:view.bounds.width-50, y:0, width:50, height:50)
        btn.addTarget(self, action: #selector(act), for: .touchUpInside)
        
        view.addSubview(connectBtn)
        connectBtn.setImage(UIImage.init(named: "arrow"), for: .normal)
        connectBtn.frame = CGRect(x:view.bounds.width-50, y:55, width:50, height:50)
        connectBtn.addTarget(self, action: #selector(popupConnect), for: .touchUpInside)
        
        view.addSubview(codeBtn)
        codeBtn.setImage(UIImage.init(named: "arrow"), for: .normal)
        codeBtn.frame = CGRect(x:view.bounds.width-50, y:110, width:50, height:50)
        codeBtn.addTarget(self, action: #selector(popupCode), for: .touchUpInside)
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    // MARK: - Private
    
    private func loadBlockFactory() {
        // Load blocks into the block factory
        blockFactory.load(fromDefaultFiles: .allDefault)
        do{
            try blockFactory.load(fromJSONPaths: ["turtle_blocks.json"])
        }catch let e{
            print(e)
        }
    }
    
    private func loadToolbox() {
        // Create a toolbox
        do {
            let toolboxPath = "turtle.xml"
            if let bundlePath = Bundle.main.path(forResource: toolboxPath, ofType: nil) {
                let xmlString = try String(contentsOfFile: bundlePath, encoding: String.Encoding.utf8)
                let toolbox = try Toolbox.makeToolbox(xmlString: xmlString, factory: blockFactory)
                try loadToolbox(toolbox)
            } else {
                print("Could not load toolbox XML from '\(toolboxPath)'")
            }
        } catch let error {
            print("An error occurred loading the toolbox: \(error)")
        }
    }
    func saveBlocks(){
        if case let str?? = try? workspace?.toXML(){
            UserDefaults.standard.set(str, forKey: "blockly_tmp_xml")
            UserDefaults.standard.synchronize()
            print("xml:" + str)
        }
    }
    private func loadBlocks(){
        let def = """
<?xml version="1.0" encoding="utf-8" standalone="no"?>
<xml xmlns="http://www.w3.org/1999/xhtml">
    <block x="81" type="start" id="255CBAB0-4DD5-4FFC-B8B1-B473F9707C2B" y="21" />
</xml>
"""
        let str = UserDefaults.standard.string(forKey: "blockly_tmp_xml") ?? ""
        if let xml = (try? AEXMLDocument(xml: str)) ?? (try? AEXMLDocument(xml: def)){
            try? workspace?.loadBlocks(fromXML: xml["xml"], factory: blockFactory)
        }
    }
}

