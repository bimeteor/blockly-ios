//
//  Action.swift
//  PlaygroundGame
//
//  Created by CXY on 2017/10/30.
//  Copyright © 2017年 UBTECH. All rights reserved.
//

import Foundation
import SceneKit

struct Displacement<T> {
    let from: T
    let to: T
    
    //        var reversed: Displacement<T> {
    //            return Displacement(from: to, to: from)
    //        }
}

enum Action {
    // MARK: Types
    
    enum Movement: Int {
        case walk, jump, teleport
    }
    
    /// Displace from a position to a new position with the appropriate `Movement` type.
    case move(Displacement<SCNVector3>, type: Movement)
    
    /// Rotate between two angles specifying the direction with `clockwise`.
    /// The angle must be specified in radians.
    case turn(Displacement<SCNFloat>, clockwise: Bool)
    
    
    /// Run a specific `EventGroup`.
    /// Providing a variation index will use a specific index if possible, falling back to random.
    case run(EventGroup, variation: Int?)
    
    
}

extension Action {
    
    func event(from dis: Displacement<SCNVector3>, type: Action.Movement) -> EventGroup {
        let fromY = dis.from.y
        let toY = dis.to.y
        
        switch type {
        case .walk:
            if fromY.isClose(to: toY, epiValue: WorldConfiguration.heightTolerance) {
                return .walk
            }
            return fromY < toY ? .walkUpStairs : .walkDownStairs
            
        case .jump:
            if fromY.isClose(to: toY, epiValue: WorldConfiguration.heightTolerance) {
                return .jumpForward
            }
            return fromY > toY ? .jumpDown : .jumpUp
            
        case .teleport:
            return .teleport
        }
    }
    
    /// Provides a mapping of the command to an `EventGroup`.
    var event: EventGroup? {
        switch self {
        case let .move(dis, type):
            return event(from: dis, type: type)
            
        case .turn(_, let clockwise):
            return clockwise ? .turnRight : .turnLeft
            
        case let .run(anim, _):
            return anim
            
        }
        
    }
    
    
    
    /// Returns a random index for one of the possible variations.
    /// Note: `.run(_:variation:)` is special cased to allow specific events to be requested.
    var variationIndex: Int {
        if case let .run(_, index) = self, let variation = index {
            return variation
        }
        
        if let event = self.event {
            let possibleVariations = EventGroup.allIdentifiersByType[event]
            return possibleVariations?.randomIndex ?? 0
        }
        
        return 0
    }
}
