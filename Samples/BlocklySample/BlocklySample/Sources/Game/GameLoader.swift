//
//  GameLoader.swift
//  BlocklySample
//
//  Created by CXY on 2017/11/2.
//  Copyright © 2017年 Google Inc. All rights reserved.
//

import UIKit
import SceneKit
import AVFoundation

class GameLoader: NSObject {
    private static let instance = GameLoader()
    
    public class var shared: GameLoader {
        return instance
    }
    
    private override init() {
        super.init()
    }
    
    private lazy var audioPlayer: AVAudioPlayer? = {
        do {
            // SS1_PUZL_1b SS1_CONGR_1h
            guard let url = Bundle.main.url(forResource: "SS1_PUZL_1b", withExtension: ".m4a") else { return nil }
            let audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer.numberOfLoops = -1
            audioPlayer.prepareToPlay()
            return audioPlayer
        } catch (_) {
            return nil
        }
    }()
    
    class func loadGameWithScnView(_ scnView: SCNView) -> Actor? {
        // set the scene to the view
        let scene = SCNScene(named: "WorldResources.scnassets/_Scenes/3.2.scn")!
        // Give the `rootNode` a name for easy lookup.
        scene.rootNode.name = "rootNode"
        // Load the skybox.
        scene.background.contents = Asset.texture(named: "zon_bg_skyBox_a_DIFF")
        
        let rootNode = scene.rootNode
        // Set up the camera.
        let cameraNode = rootNode.childNode(withName: "camera", recursively: true)!
        let boundingNode = rootNode.childNode(withName: "Scenery", recursively: true)
        
        var (_, sceneWidth) = (boundingNode?.boundingSphere)!
        // Expand so we make sure to get the whole thing with a bit of overlap.
        sceneWidth *= 2
        
        let dominateDimension = Float(5)
        sceneWidth = max(dominateDimension * 2.5, sceneWidth)
        guard sceneWidth.isFinite && sceneWidth > 0 else { return nil}
        
        let cameraDistance = Double(cameraNode.position.z)
        let halfSceneWidth = Double(sceneWidth / 2.0)
        let distanceToEdge = sqrt(cameraDistance * cameraDistance + halfSceneWidth * halfSceneWidth)
        let cos = cameraDistance / distanceToEdge
        let sin = halfSceneWidth / distanceToEdge
        let halfAngle = atan2(sin, cos)
        cameraNode.camera?.yFov = 2.0 * halfAngle * 180.0 / .pi
        
        // Set up normal lights
        guard let lightNode = rootNode.childNode(withName: DirectionalLightName, recursively: true) else { return nil }
        
        var light: SCNLight?
        lightNode.enumerateHierarchy { node, stop in
            if let directional = node.light {
                light = directional
                stop.initialize(to: true)
            }
        }
        
        light?.orthographicScale = 10
        light?.shadowMapSize = CGSize(width:  2048, height:  2048)
        
        
        // Add actor
        let actor = Actor(scene: scene)
        scnView.scene = scene
        scnView.allowsCameraControl = true
    
        return actor
    }
    
    class func silent() {
        GameLoader.shared.audioPlayer?.stop()
    }
    
    class func bgmStart() {
        GameLoader.shared.audioPlayer?.play()
    }
}
