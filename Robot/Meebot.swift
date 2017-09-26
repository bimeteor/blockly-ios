//
//  Meebot.swift
//  BLE
//
//  Created by NewMan on 2017/2/7.
//  Copyright © 2017年 WG. All rights reserved.
//

import Foundation

public class Meebot:Robot{
    private static let _shard = Meebot()
    public class var shared:Meebot { return _shard }
}
