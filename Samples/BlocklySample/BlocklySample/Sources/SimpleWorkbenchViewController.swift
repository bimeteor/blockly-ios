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
    let turtle = UIImageView.init(image: UIImage.init(named: "turtle"))
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
    
    redoButton.isHidden = true
    undoButton.isHidden = true
    trashCanView.isHidden = true
    view.addSubview(simulator)
    simulator.isUserInteractionEnabled = false
    simulator.isHidden = true
    simulator.frame = CGRect(x:50, y:0, width:view.bounds.width-50, height:view.bounds.height)
    let mask = UIView.init(frame: simulator.bounds)
    mask.backgroundColor = .black
    mask.alpha = 0.5
    simulator.addSubview(mask)
    simulator.addSubview(turtle)
    turtle.bounds = CGRect(x:0, y:0, width:40, height:40)
    
    let play = UIButton.init(type: .system)
    view.addSubview(play)
    play.setImage(UIImage.init(named: "turtle"), for: .normal)
    play.frame = CGRect(x:view.bounds.width-50, y:0, width:40, height:40)
    play.addTarget(self, action: #selector(act), for: .touchUpInside)
  }

    @objc func act() {
        
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
      let toolboxPath = "toolbox.xml"
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
}
