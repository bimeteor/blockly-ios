/*
 * Copyright 2017 Google Inc. All Rights Reserved.
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
import QuartzCore

/**
 UI Control that is used for picking an angle from a clock-like dial.
 */
@objc(BKYAnglePicker)
public class AnglePicker: UIControl {
    
    /**
     Options for configuring the behavior of the angle picker.
     */
    public struct Options {
        /// The fill color of the angle.
        public var angleColor: UIColor = ColorPalette.green.tint600
        
        /// The fill color of the background circle.
        public var circleColor: UIColor = ColorPalette.grey.tint100
        
        /// The direction in which the angle increases.
        /// `true` for clockwise, or `false` for counterclockwise (the default).
        public var clockwise = true
        
        /// Offset the location of 0° (and all angles) by a constant.
        /// Usually either `0` (0° = right) or `90` (0° = up), for clockwise. Defaults to `0`.
        public var offset: Double = -90
        
        /// 步进值，单位是°
        public var step: Double = 1
        
        /// Maximum allowed angle before wrapping.
        /// Usually either 360 (for 0 to 359.9) or 180 (for -179.9 to 180).
        public var wrap: Double = 360
        
        /// 最大值是否为360度。如果不是，那么就是-118到118度
        public var is360 = true
        
        public init() {
        }
    }
    
    // MARK: - Properties
    
    /// The angle in degrees.
    public var angle = Double(0) {
        didSet {
            if angle == oldValue {
                return
            }
            
            renderAngle()
            
            // Notify of changes to the control.
            sendActions(for: .valueChanged)
        }
    }
    
    /// The configurable options of the angle picker.
    public let options: Options
    
    /// Layer for rendering the background circle.
    fileprivate lazy var _backgroundCircleLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.allowsEdgeAntialiasing = true
        layer.drawsAsynchronously = true
        layer.fillColor = nil
        layer.strokeColor = self.options.circleColor.cgColor
        layer.lineWidth = 40
        layer.lineCap = kCALineCapRound
        return layer
    }()
    
    /// Layer for rendering the angle.
    fileprivate lazy var _angleLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.allowsEdgeAntialiasing = true
        layer.fillColor = nil
        layer.strokeColor = self.options.angleColor.cgColor
        layer.lineWidth = 40
        return layer
    }()
    
    /// Layer for rendering the cursor.
    fileprivate lazy var _cursorLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.allowsEdgeAntialiasing = true
        layer.fillColor = UIColor.red.cgColor
        layer.strokeColor = UIColor.yellow.cgColor
        layer.lineWidth = 10
        layer.path = UIBezierPath(ovalIn:
            CGRect(x: 0, y: 0, width: 30, height: 30)).cgPath
        layer.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        return layer
    }()
    
    /// The radius of the angle picker.
    private var _radius: CGFloat {
        return min(bounds.width, bounds.height) / CGFloat(2) * 0.6
    }
    
    /// The angle label
    private var _angleLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .clear
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 30)
        return label
    }()
    
    
    
    // MARK: - Initializer
    
    public override init(frame: CGRect) {
        self.options = Options()
        super.init(frame: frame)
        commonInit()
    }
    
    public init(frame: CGRect, options: Options) {
        self.options = options
        super.init(frame: frame)
        commonInit()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        self.options = Options()
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        // Add render layers
        _backgroundCircleLayer.addSublayer(_angleLayer)
        _backgroundCircleLayer.addSublayer(_cursorLayer)
        layer.addSublayer(_backgroundCircleLayer)

        // Render each layer
        renderBackground()
        renderAngle()
        
        // Add angle label
        self.addSubview(_angleLabel)
        
        // Add tick labels
        _addTickLabels()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        if _backgroundCircleLayer.frame == self.bounds {
            return
        }
        
        _backgroundCircleLayer.frame = self.bounds
        
        renderBackground()
        renderAngle()
        
        _angleLabel.frame = self.bounds
        _layoutTickLabels()
    }
    
    // MARK: - Show Tick Labels
    
    private func _addTickLabels() {
        if self.options.is360 {
            _addTickLabels(at: [0, 90, 180, 270])
        } else {
            _addTickLabels(at: [0, (90+(180-118)), (90-(180-118))])
        }
    }
    
    private func _addTickLabels(at angles: [Int]) {
        func _tickLabel(for angle: Int) -> UILabel {
            let label = UILabel()
            label.backgroundColor = .clear
            label.textColor = .black
            label.text = "\(angle)°"
            label.font = UIFont.systemFont(ofSize: 11)
            return label
        }
        
        for angle in angles {
            let tagOffset = 10000
            let label = _tickLabel(for: angle)
            label.tag = angle + tagOffset
            self.addSubview(label)
        }
    }
    
    private func _layoutTickLabels() {
        let tagOffset = 10000
        for v in self.subviews {
            if v.tag >= tagOffset, v is UILabel {
                let label = v as! UILabel
                label.sizeToFit()
                
                var tickAngle = Double(label.tag - tagOffset)
                tickAngle = offsetAngle(for: tickAngle)
                let point = pointForAngle(tickAngle, radius: _radius+35,
                                          clockwise: options.clockwise)
                label.center = point
            }
        }
    }
    
    // MARK: - Render Operations
    
    fileprivate func renderBackground() {
        var startAngle: Double = 0
        var endAngle: Double = 360
        if !options.is360 {
            startAngle = -90+(180-118)
            endAngle = 270-(180-118)
        }
        
        let startPoint = pointForAngle(startAngle, radius: _radius, clockwise: false)
        let circlePath = UIBezierPath()
        circlePath.move(to: startPoint)
        circlePath.addArc(
            withCenter: center,
            radius:     _radius,
            startAngle: CGFloat(toRadians(startAngle)) * (false ? 1: -1),
            endAngle:   CGFloat(toRadians(endAngle)) * (false ? 1: -1),
            clockwise:  false)
        
        _backgroundCircleLayer.path = circlePath.cgPath
        _backgroundCircleLayer.setNeedsDisplay()
    }
    
    fileprivate func renderAngle() {
        // Create bezier path of angle
        let clockwise = options.clockwise
        let startAngle = offsetAngle(for: 0)
        let endAngle = offsetAngle(for: angle)
        
        let center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        let startingPoint = pointForAngle(startAngle, radius: _radius, clockwise: clockwise)
        let endedPoint = pointForAngle(endAngle, radius: _radius, clockwise: clockwise)
        
        let anglePath = UIBezierPath(rect: CGRect.zero)
        anglePath.move(to: startingPoint)
        anglePath.addArc(
            withCenter: center,
            radius:     _radius,
            startAngle: CGFloat(toRadians(startAngle)) * (clockwise ? 1: -1),
            endAngle:   CGFloat(toRadians(endAngle)) * (clockwise ? 1: -1),
            clockwise:  clockwise)
          
        // Set the path
        _angleLayer.path = anglePath.cgPath
        
        _angleLayer.setNeedsDisplay()
        setNeedsDisplay()
        
        // Update cursor position
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        _cursorLayer.position = endedPoint
        CATransaction.commit()
        
        // Update angle label
        _angleLabel.text = displayAngle(for: angle)
    }
    
    // MARK: - Angle Calculations
    
    fileprivate func toRadians(_ degrees: Double) -> Double {
        return degrees * .pi / 180.0
    }
    
    /**
     * 根据角度求点的坐标
     */
    fileprivate func pointForAngle(_ angle: Double, radius: CGFloat, clockwise: Bool) -> CGPoint {
        let center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        return CGPoint(
            x: cos(CGFloat(toRadians(angle)) * (clockwise ? 1: -1)) * radius + center.x,
            y: sin(CGFloat(toRadians(angle)) * (clockwise ? 1: -1)) * radius + center.y)
    }
    
    /**
     * reallyAngle: 真实坐标角度
     * return: 加入偏移量后的角度
     */
    fileprivate func offsetAngle(for reallyAngle: Double) -> Double {
        let offset = options.offset
        let startAngle = offset.truncatingRemainder(dividingBy: 360) // 浮点数取模
        let endAngle = (startAngle + reallyAngle).truncatingRemainder(dividingBy: 360)
        return endAngle
    }
    
    /**
     * reallyAngle: 真实坐标角度
     * return: 格式化后的文本（用于显示需要）
     */
    fileprivate func displayAngle(for reallyAngle: Double) -> String {
        if options.is360 {
            return "\(Int(reallyAngle))°"
        } else {
            return "\(Int(reallyAngle))°"
        }
    }
    
    /**
     Normalizes a given angle to be within 0 and 360 degrees.
     */
    fileprivate func normalizedAngle(_ angle: Double) -> Double {
        let normalized = angle.truncatingRemainder(dividingBy: 360)
        return normalized > 0 ? normalized : (normalized + 360)
    }
    
    /**
     Clamps the given angle so it's between the range defined by `self.options.wrap`.
     */
    fileprivate func clampedAngle(_ angle: Double) -> Double {
        var clamped = normalizedAngle(angle)
        
        if clamped < 0 {
            clamped += 360
        }
        if clamped >= options.wrap {
            clamped -= 360
        }
        if clamped == 0 {
            // Edge case where angle could be "-0.0".
            clamped = abs(clamped)
        }
        
        return clamped
    }
    
    /**
     Returns the angle of a given point, relative to the center of the view.
     */
    fileprivate func angleRelativeToCenter(of point: CGPoint) -> Double {
        let center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        let dx = point.x - center.x
        let dy = (point.y - center.y) * (options.clockwise ? 1: -1)
        var angle = Double(atan(dy/dx)) / .pi * 180.0
        
        if dx < 0 {
            // Adjust the angle if it's obtuse
            angle += 180
        }
        
        // Remove the original offset from the angle
        angle -= options.offset
        
        // Round to the nearest degree.
        angle = round(angle)
        
        return clampedAngle(angle)
    }
    
    /**
     Returns the closest hotspot angle to a given angle, within a step.
     
     - parameter angle: The angle to check.
     - parameter step: The step.
     - returns: The closest hotspot.
     */
    fileprivate func hotspotAngle(for angle: Double, step: Double) -> Double {
        // Calculate the normalized version of this angle, and the two hotspot angles surrounding this
        // angle.
        let normalized = normalizedAngle(angle)
        let lowerAngle = floor(normalized / step) * step
        let higherAngle = (floor(normalized / step) + 1) * step
        
        // Figure out which hotspot is closer and within the threshold.
        let lowerDifference = abs(normalized - lowerAngle)
        let higherDifference = abs(normalized - higherAngle)

        let hotspotAngle = lowerDifference < higherDifference ? lowerAngle : higherAngle
        return clampedAngle(hotspotAngle)
    }
    
    fileprivate func angleForTouch(at point: CGPoint) -> Double {
        let originAngle = angleRelativeToCenter(of: point)
        return hotspotAngle(for: originAngle, step: options.step)
    }
}

extension AnglePicker {
    
    // MARK: - Touch event
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
    }
    
    // MARK: - Touch Tracking
    
    public override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let relativeLocation = touch.location(in: self)
        
        // 只有触点落在光标的热区内才允许拖动
        let hotRadius: CGFloat = 60
        let hotPoint = _cursorLayer.position
        let hotRect = CGRect(x: hotPoint.x-hotRadius/2, y: hotPoint.y-hotRadius/2,
                             width: hotRadius, height: hotRadius)
        if !hotRect.contains(relativeLocation) {
            return false
        }
        
        self.angle = angleForTouch(at: relativeLocation)
        return true
    }
    
    public override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let relativeLocation = touch.location(in: self)
        self.angle = angleForTouch(at: relativeLocation)
        return true
    }
    
    public override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        if let relativeLocation = touch?.location(in: self) {
            self.angle = angleForTouch(at: relativeLocation)
        }
    }
}

