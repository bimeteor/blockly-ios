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

import Foundation

extension Block {
  /**
   Builder for creating instances of `Block`.
   */
  @objc(BKYBlockBuilder)
  public class Builder: NSObject {
    // MARK: - Static Properties
    private static let CONFLICTING_CONNECTIONS_ERROR =
    "Block cannot have both an output and a either a previous or next statement."

    // MARK: - Properties

    // These values are publicly immutable in `Block`
    public var identifier: String = ""
    public var category: Int = 0
    public var colour: UIColor = UIColor.clearColor()
    public private(set) var outputConnectionEnabled: Bool = false
    public private(set) var outputConnectionTypeChecks: [String]?
    public private(set) var nextConnectionEnabled: Bool = false
    public private(set) var nextConnectionTypeChecks: [String]?
    public private(set) var previousConnectionEnabled: Bool = false
    public private(set) var previousConnectionTypeChecks: [String]?
    public var inputBuilders: [Input.Builder] = []
    public var inputsInline: Bool = false

    // These values are publicly mutable in `Block`
    public var tooltip: String = ""
    public var comment: String = ""
    public var helpURL: String = ""
    public var hasContextMenu: Bool = true
    public var deletable: Bool = true
    public var movable: Bool = true
    public var editable: Bool = true
    public var collapsed: Bool = false
    public var disabled: Bool = false
    public var rendered: Bool = false

    // MARK: - Initializers

    public init(identifier: String) {
      super.init()
      self.identifier = identifier

      setColourFromHue(0)
    }

    /**
    Initialize a builder from an existing block. All values that are not specific to
    a single instance of a block will be copied in to the builder. Any associated layouts are not
    copied into the builder.
    */
    public init(block: Block) {
      identifier = block.identifier
      category = block.category
      colour = block.colour
      inputsInline = block.inputsInline

      tooltip = block.tooltip
      comment = block.comment
      helpURL = block.helpURL
      hasContextMenu = block.hasContextMenu
      collapsed = block.collapsed

      outputConnectionEnabled = block.outputConnection != nil ? true : false
      outputConnectionTypeChecks = block.outputConnection?.typeChecks
      nextConnectionEnabled = block.nextConnection != nil ? true : false
      nextConnectionTypeChecks = block.nextConnection?.typeChecks
      previousConnectionEnabled = block.previousConnection != nil ? true : false
      previousConnectionTypeChecks = block.previousConnection?.typeChecks

      inputBuilders.appendContentsOf(block.inputs.map({ Input.Builder(input: $0) }))
    }

    // MARK: - Public

    /**
    Creates a new block given the current state of the builder.

    - Parameter uuid: [Optional] The uuid to assign the block. If nil, a new uuid is automatically
    assigned to the block.
    - Throws:
    `BlocklyError`: Occurs if the block is missing any required pieces.
    - Returns: A new block
    */
    public func build(uuid uuid: String? = nil) throws -> Block {
      if identifier.isEmpty {
        throw BlocklyError(.InvalidBlockDefinition, "Block identifier may not be empty")
      }
      var outputConnection: Connection?
      var nextConnection: Connection?
      var previousConnection: Connection?
      if outputConnectionEnabled {
        outputConnection = Connection(type: .OutputValue)
        outputConnection!.typeChecks = outputConnectionTypeChecks
      }
      if nextConnectionEnabled {
        nextConnection = Connection(type: .NextStatement)
        nextConnection!.typeChecks = nextConnectionTypeChecks
      }
      if previousConnectionEnabled {
        previousConnection = Connection(type: .PreviousStatement)
        previousConnection!.typeChecks = previousConnectionTypeChecks
      }
      let inputs = inputBuilders.map({ $0.build() })

      let block = Block(uuid: uuid, identifier: identifier, category: category,
        colour: colour, inputs: inputs, inputsInline: inputsInline,
        outputConnection: outputConnection, previousConnection: previousConnection,
        nextConnection: nextConnection)

      block.tooltip = tooltip
      block.comment = comment
      block.helpURL = helpURL
      block.hasContextMenu = hasContextMenu
      block.deletable = deletable
      block.movable = movable
      block.editable = editable
      block.collapsed = collapsed
      block.disabled = disabled
      block.rendered = rendered

      return block
    }

    public func setOutputConnectionEnabled(enabled: Bool, typeChecks: [String]? = nil) throws {
      if enabled && (nextConnectionEnabled || previousConnectionEnabled) {
        throw BlocklyError(.InvalidBlockDefinition, Builder.CONFLICTING_CONNECTIONS_ERROR)
      }
      self.outputConnectionEnabled = enabled
      self.outputConnectionTypeChecks = typeChecks
    }

    public func setNextConnectionEnabled(enabled: Bool, typeChecks: [String]? = nil) throws {
      if enabled && outputConnectionEnabled {
        throw BlocklyError(.InvalidBlockDefinition, Builder.CONFLICTING_CONNECTIONS_ERROR)
      }
      self.nextConnectionEnabled = enabled
      self.nextConnectionTypeChecks = typeChecks
    }

    public func setPreviousConnectionEnabled(enabled: Bool, typeChecks: [String]? = nil) throws {
      if enabled && outputConnectionEnabled {
        throw BlocklyError(.InvalidBlockDefinition, Builder.CONFLICTING_CONNECTIONS_ERROR)
      }
      self.previousConnectionEnabled = enabled
      self.previousConnectionTypeChecks = typeChecks
    }

    /**
     Sets `self.colour` based on hue, saturation, brightness, and alpha values.

     - Parameter hue: The hue
     - Parameter saturation: (Optional) The saturation. Defaults to 0.45.
     - Parameter brightness: (Optional) The brightness. Defaults to 0.65.
     - Parameter alpha: (Optional) The alpha. Defaults to 1.0.
     */
    public func setColourFromHue(
      hue: CGFloat, saturation: CGFloat = 0.45, brightness: CGFloat = 0.65, alpha: CGFloat = 1.0)
    {
       self.colour = UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
    }
  }
}