//
//  Actor.swift
//  PlaygroundGame
//
//  Created by CXY on 2017/10/30.
//  Copyright © 2017年 UBTECH. All rights reserved.
//

import UIKit
import SceneKit

public let ActionDidCompletedNotificaitonName = "ActionDidCompletedNotificaitonName"

class Actor: NSObject {
    
    private var scene: SCNScene?
    var scnNode: SCNNode = SCNNode()
    
    private var step = 1
    
    private lazy var audioComponent = AudioComponent(actor: self)
    // MARK: Actor Properties
    
    var type: ActorType = .byte
    
    /// Manually calculate the rotation to ensure `w` component is correctly calculated.
    var rotation: SCNFloat {
        get {
            return scnNode.rotation.y * scnNode.rotation.w
        }
        set {
            scnNode.rotation = SCNVector4(0, 1, 0, newValue)
        }
    }
    
    var position: SCNVector3 {
        get {
            return scnNode.position
        }
        set {
            scnNode.position = newValue
        }
    }
    
    public var heading: Direction {
        return Direction(radians: rotation)
    }
    
    public var coordinate: Coordinate {
        return Coordinate(position)
    }
    
    public var height: Int {
        return Int(round(position.y / WorldConfiguration.levelHeight))
    }
    
    public var isStackable: Bool {
        return false
    }
    
    public var verticalOffset: SCNFloat {
        return 0
    }
    
    var nextCoordinateInCurrentDirection: Coordinate {
        return coordinateInCurrentDirection(displacement: 1)
    }
    
    func coordinateInCurrentDirection(displacement: Int) -> Coordinate {
        let heading = Direction(radians: rotation)
        let coordinate = Coordinate(position)
        
        return coordinate.advanced(by: displacement, inDirection: heading)
    }

    init(scene: SCNScene) {
        self.scene = scene
        
        let heroScene = SCNScene(named: "Characters.scnassets/Byte/NeutralPose.scn")
        if let actorNode = heroScene?.rootNode.childNode(withName: "CHARACTER_Cyclops", recursively: true) {
            actorNode.name = "Actor"
            actorNode.opacity = 1.0
            actorNode.scale = SCNVector3(x: 1, y: 1, z: 1)
            scene.rootNode.addChildNode(actorNode)
            scnNode = actorNode
        }

        super.init()
        rotation = SCNFloat(Double.pi)
        position = SCNVector3Make(-2, 0, 2)
    }
    
    public func reset() {
        rotation = SCNFloat(Double.pi)
        position = SCNVector3Make(-2, 0, 2)
    }
    
    private func performAction(_ action: Action) {
        // Not all commands apply to the actor, return immediately if there is no action.
        guard let event = action.event else {
            fatalError("The actor has been asked to perform \(action), but there is no valid event associated with this action.")
        }

        // MARK: ActorComponent
        let animation: CAAnimation?
        
        // Look for a faster variation of the requested action to play at speeds above `WorldConfiguration.Actor.walkRunSpeed`.
        let speed = WorldConfiguration.Actor.idleSpeed
        let animationCache: AssetCache = AssetCache.cache(forType: .byte)
        
        let index = 0

        animation = animationCache.animation(for: event, index: index)
        animation?.speed = speed
        
        guard let readyAnimation = animation?.copy() as? CAAnimation else { return }
        readyAnimation.setDefaultAnimationValues(isStationary: event.isStationary)
        
        readyAnimation.stopCompletionBlock = { [weak self] isFinished in
            guard isFinished else { return }
            
            var nextCoordinate = self?.position
            var nextRoation = self?.rotation
            switch action {
            case .move(_, type: _):
                nextCoordinate = self?.nextCoordinateInCurrentDirection.position
                break
            case let .turn(dump, clockwise: _):
                nextRoation = dump.to
                break
            default:
                break
            }
            
            guard let pos = nextCoordinate else { return }
            guard let rot = nextRoation else { return }
            
            if let animationKeys = self?.scnNode.animationKeys {
                for key in animationKeys {
                    self?.scnNode.removeAnimation(forKey: key)
                }
            }

            self?.position = pos
            self?.rotation = rot
            if let count = self?.step {
                if count > 1 {
                    self?.move(distance: count-1)
                    return 
                }
            }
            
            switch action {
            case let .move(_, type: type):
                switch type {
                case .walk:
                    if let count = self?.step {
                        if count == 1 {
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: ActionDidCompletedNotificaitonName), object: nil)
                        }
                    }
                    break
                case .jump:
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: ActionDidCompletedNotificaitonName), object: nil)
                    break
                case .teleport: break
                    
                }
                break
            case .turn(_, clockwise: _):
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: ActionDidCompletedNotificaitonName), object: nil)
                break
            default:
                break
            }
            
        }
        
        // Remove any lingering animations that may still be attached to the node.
        for key in scnNode.animationKeys {
            scnNode.removeAnimation(forKey: key)
        }
        scnNode.addAnimation(readyAnimation, forKey: event.rawValue)
        
        
        // Audio
        let idx = action.variationIndex
        self.audioComponent.perform(event: event, variation: idx, speed: WorldConfiguration.Actor.idleSpeed)
        
    }
    
    
    // MARK: Movement Commands
    
    /**
     Moves the character forward by a certain number of tiles, as determined by the `distance` parameter value.
     
     Example usage:
     ````
     move(distance: 3)
     // Moves forward three tiles.
     ````
     
     - parameters:
     - distance: Takes an Int value specifying the number of times to call `moveForward()`.
     - localizationKey: Actor.move(distance:)
     */
    public func move(distance: Int) {
        step = distance
//        for _ in 1 ... distance {
            moveForward()
//        }
    }
    
    /**
     Moves the character forward one tile.
     - localizationKey: Actor.moveForward()
     */
    public func moveForward() {
        
        let nextCoordinate = nextCoordinateInCurrentDirection
        
        // Check for stairs.
        // -WorldConfiguration.levelHeight 下楼梯
        let yDisplacement = 0.0
        let point = nextCoordinate.position
        
        let destination = SCNVector3Make(point.x, Float(yDisplacement)+point.y, point.z)
        let displacement = Displacement(from: position, to: destination)
        
        let action: Action = .move(displacement, type: .walk)
        performAction(action)
    }
    
    // `_jump()` included only for organizational purposes
    // (`jump()` is overridden by Expert).
    func jump() {
        
        let nextCoordinate = coordinateInCurrentDirection(displacement: 0)
 
        let point = nextCoordinate.position
        let destination = SCNVector3Make(point.x, position.y, point.z)
        let displacement = Displacement(from: position, to: destination)
        let action: Action = .move(displacement, type: .jump)
        
        performAction(action)
    }
    
    /**
     Turns the character left.
     - localizationKey: Actor.turnLeft()
     */
    public func turnLeft() {
        turnBy(90)
    }
    
    /**
     Turns the character right.
     - localizationKey: Actor.turnRight()
     */
    public func turnRight() {
        turnBy(-90)
    }
    
    // MARK: Movement Helpers
    
    /// Creates a new command if a portal exists at the specified coordinate.
//    private func addCommandForPortal(at coordinate: Coordinate) {
//        let portal = world?.existingItem(ofType: Portal.self, at: coordinate)
//        if let destinationPortal = portal?.linkedPortal, portal!.isActive {
//            let displacement = Displacement(from: position, to: destinationPortal.position)
//            
//            add(action: .move(displacement, type: .teleport))
//        }
//    }
//    
    /**
     Rotates the actor by `degrees` around the y-axis.
     
     - turnLeft() = 90
     - turnRight() = -90/ 270
     */
    private func turnBy(_ degrees: Int) {
        // Convert degrees to radians.
        let nextDirection = (rotation + degrees.toRadians).truncatingRemainder(dividingBy: 2 * π)
        
        let currentDir = Direction(radians: rotation)
        let nextDir = Direction(radians: nextDirection)

        let clockwise = currentDir.angle(to: nextDir) < 0
        let displacement = Displacement(from: rotation, to: nextDirection)
        let action:Action = .turn(displacement, clockwise: clockwise)
        performAction(action)
//        return nextDirection
    }
    

}
