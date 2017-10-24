//
//  SpeedPicker.swift
//  Blockly
//
//  Created by ubt on 2017/9/21.
//  Copyright © 2017年 Google Inc. All rights reserved.
//

import UIKit

class SpeedPicker: UIControl {
    
    /**
     Options for configuring the behavior of the speed picker.
     */
    public struct Options {
        /// The fill color of the selected arc.
        public var speedColor: UIColor = ColorPalette.green.tint600
        
        /// The fill color of the background arc.
        public var backgroundColor: UIColor = ColorPalette.grey.tint100
        
        public init() {
            
        }
    }
    
    
    // MARK: - Properties
    
    /// The speed enum.
    
    public enum SpeedType: Int {
        // 枚举的编号就是每个速度弧段所在的位置（逆时针方向）
        case normal = 1
        
        case slow = 2
        case slower = 3
        
        case fast = 0
        case faster = 5
        
        
        func title() -> String {
            switch self {
            case .normal:
                return "中速"
                
            case .slow:
                return "慢速"
                
            case .slower:
                return "非常慢"
                
            case .fast:
                return "快速"
                
            case .faster:
                return "非常快"
            }
        }
        
        // 获取每个速度所对应的角度范围
        func arcRange() -> (from: Double, to: Double) {
            let count : Double = 6 // 将圆6等分
            let space: Double = 5
            let perArc = 360 / count - space*2
            let index = Double(self.rawValue)
            let from = ((2*index + 1) * space) + (index * perArc)
            
            if self == .slower {
                return (from: from, to: from + perArc/2.0)
            } else if self == .faster {
                return (from: from + perArc/2.0, to: from + perArc)
            } else {
                return (from: from, to: from + perArc)
            }
        }
    }
    
    public var speed = SpeedType.normal {
        didSet {
            if speed == oldValue {
                return
            }
            
            _renderSpeed()
            _speedLabel.text = speed.title()
            
            // Notify of changes to the control.
            sendActions(for: .valueChanged)
        }
    }
    
    /// The configurable options of the speed picker.
    public let options: Options
    
    /// Layer for rendering the background.
    fileprivate lazy var _backgroundLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.allowsEdgeAntialiasing = true
        layer.drawsAsynchronously = true
        layer.fillColor = nil
        layer.strokeColor = self.options.backgroundColor.cgColor
        layer.lineWidth = 20
        return layer
    }()
    
    /// Layer for rendering the speed.
    fileprivate lazy var _speedLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.allowsEdgeAntialiasing = true
        layer.fillColor = nil
        layer.strokeColor = self.options.speedColor.cgColor
        layer.lineWidth = 20
        return layer
    }()
    
    /// Layer for rendering the pointer.
    fileprivate lazy var _pointerLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.anchorPoint = CGPoint(x: 0.5, y: 0.9)
        return layer
    }()
    
    /// The radius of the speed picker.
    fileprivate var _radius: CGFloat {
        // 减50是为了腾出地方放置说明文本（在圆弧的外部）
        return min(bounds.width, bounds.height) / CGFloat(2) - 50
    }
    
    /// The speed label
    private var _speedLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .clear
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 25)
        return label
    }()
    
    
    
    // MARK: - Initializer
    
    public override init(frame: CGRect) {
        self.options = Options()
        super.init(frame: frame)
        _commonInit()
    }
    
    public init(frame: CGRect, options: Options) {
        self.options = options
        super.init(frame: frame)
        _commonInit()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        self.options = Options()
        super.init(coder: aDecoder)
        _commonInit()
    }
    
    private func _commonInit() {
        let pointerImage = ImageLoader.loadImage(named: "pointer", forClass: type(of: self))
        _pointerLayer.contents = pointerImage?.cgImage
        
        // Add render layers
        _backgroundLayer.addSublayer(_speedLayer)
        _backgroundLayer.addSublayer(_pointerLayer)
        layer.addSublayer(_backgroundLayer)
        
        // Render each layer
        _renderBackground()
        _renderSpeed()
        
        // Add speed label
        _speedLabel.text = self.speed.title()
        self.addSubview(_speedLabel)
        
        // Add tick labels
        _addTickLabels()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
    
        if _backgroundLayer.frame == self.bounds {
            return
        }
        
        _backgroundLayer.frame = self.bounds
        
        // Layout pointer
        let pointerHeigth = _radius+20
        _pointerLayer.frame = CGRect(x: 0, y: 0, width: 30, height: pointerHeigth)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        _pointerLayer.position = self.center
        CATransaction.commit()
        
        _renderBackground()
        _renderSpeed()
        
        let bottom: CGFloat = 20
        _speedLabel.frame = CGRect(x: 0, y: self.frame.height-bottom-40,
                                   width: self.frame.width, height: 40)
        _layoutTickLabels()
    }
    
    // MARK: - Show Tick Labels
    
    private func _addTickLabels() {
        func _tickLabel(for angle: Int) -> UILabel {
            let label = UILabel()
            label.backgroundColor = .clear
            label.textColor = .black
            label.font = UIFont.systemFont(ofSize: 12)
            return label
        }
        
        let allSpeeds: [SpeedType] = [.normal, .slow, .slower, .fast, .faster]
        let allArcs = allSpeeds.map{ $0.arcRange() }
        
        // 计算标题所在的角度
        var tickAngles = [Int]()

        for (idx, arc) in allArcs.enumerated() {
            let tickSpeed = allSpeeds[idx]
            if tickSpeed == .normal || tickSpeed == .slow || tickSpeed == .fast {
                let angle = arc.from + (arc.to - arc.from)/2 // 弧的中点
                tickAngles.append(Int(angle))
                
            } else if tickSpeed == .slower {
                let angle = arc.to // 弧的终点
                tickAngles.append(Int(angle))
                
            } else if tickSpeed == .faster {
                let angle = arc.from // 弧的起点
                tickAngles.append(Int(angle))
            }
        }
        
        // 添加到视图上
        for (idx, angle) in tickAngles.enumerated() {
            let tagOffset = 10000
            let label = _tickLabel(for: angle)
            label.tag = angle + tagOffset
            label.text = allSpeeds[idx].title()
            self.addSubview(label)
        }
    }
    
    private func _layoutTickLabels() {
        let tagOffset = 10000
        for v in self.subviews {
            if v.tag >= tagOffset, v is UILabel {
                let label = v as! UILabel
                label.sizeToFit()
                
                let tickAngle = Double(label.tag - tagOffset)
                let center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
                let point = _circlePoint(for: tickAngle, center: center, radius: _radius+35)
                label.center = point
            }
        }
    }
    
    // MARK: - Render Operations
    
    private func _addArc(with range: (from: Double, to: Double), in path: UIBezierPath) {
        let clockwise = false // 逆时针
        let center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        let startPoint = _circlePoint(for: range.from, center: center, radius: _radius)
        path.move(to: startPoint)
        path.addArc(
            withCenter: center,
            radius:     _radius,
            startAngle: CGFloat(_toRadians(range.from)) * (clockwise ? 1: -1),
            endAngle:   CGFloat(_toRadians(range.to)) * (clockwise ? 1: -1),
            clockwise:  clockwise)
    }
    
    private func _renderBackground() {
        // Create bezier path of background
        let arcPath = UIBezierPath()
        
        let allSpeeds: [SpeedType] = [.normal, .slow, .slower, .fast, .faster]
        let allArcs = allSpeeds.map{ $0.arcRange() }
        for arc in allArcs {
            _addArc(with: arc, in: arcPath)
        }
        
        _backgroundLayer.path = arcPath.cgPath
        
        _backgroundLayer.setNeedsDisplay()
        setNeedsDisplay()
    }
    
    private func _renderSpeed() {
        // Create bezier path of speed
        let arcPath = UIBezierPath()
        
        _addArc(with: self.speed.arcRange(), in: arcPath)
        
        _speedLayer.path = arcPath.cgPath
        
        _speedLayer.setNeedsDisplay()
        setNeedsDisplay()
    }
    
    // MARK: - Angle Calculations
    
    fileprivate func _toRadians(_ degrees: Double) -> Double {
        return degrees * .pi / 180.0
    }
    
    /**
     * 根据圆的角度求对应点的坐标
     */
    fileprivate func _circlePoint(for angle: Double, center: CGPoint, radius: CGFloat) -> CGPoint {
        let clockwise = false // 逆时针
        return CGPoint(
            x: cos(CGFloat(_toRadians(angle)) * (clockwise ? 1: -1)) * radius + center.x,
            y: sin(CGFloat(_toRadians(angle)) * (clockwise ? 1: -1)) * radius + center.y)
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
        if clamped >= 360 {
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
        let clockwise = false // 逆时针
        let center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        let dx = point.x - center.x
        let dy = (point.y - center.y) * (clockwise ? 1 : -1)
        var angle = Double(atan(dy/dx)) / .pi * 180.0
        
        if dx < 0 {
            // Adjust the angle if it's obtuse
            angle += 180
        }
        
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
    
    // 求出触点对应的角度
    fileprivate func angleForTouch(at point: CGPoint) -> Double {
        let step: Double = 1 // 拖动时的步进值。该值越小则拖动的时候越顺滑
        let originAngle = angleRelativeToCenter(of: point)
        return hotspotAngle(for: originAngle, step: step)
    }
    
    // 求出触点对应的速度。由于速度间存在分隔，所以有可能返回nil
    fileprivate func _speedForTouch(at point: CGPoint) -> SpeedType? {
        var speed: SpeedType?
        
        let angle = angleForTouch(at: point)
        let allSpeeds: [SpeedType] = [.normal, .slow, .slower, .fast, .faster]
        let allArcs = allSpeeds.map{ $0.arcRange() }
        for (idx, arc) in allArcs.enumerated() {
            if angle >= arc.from && angle <= arc.to {
                speed = allSpeeds[idx]
            }
        }
        
        return speed
    }
}

extension SpeedPicker {
    
    private func _pointerRotate(to angle: Double, animated: Bool) {
        let adjustAngle = angle - 90 // 指针本身处于竖直的状态
        let clockwise = false
        let radians = CGFloat(_toRadians(adjustAngle) * (clockwise ? 1: -1))
        
        if animated {
            _pointerLayer.transform = CATransform3DMakeRotation(radians, 0, 0, 1)
        } else {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            _pointerLayer.transform = CATransform3DMakeRotation(radians, 0, 0, 1)
            CATransaction.commit()
        }
    }
    
    private func _pointerRotate(to point: CGPoint, animated: Bool) {
        let angle = angleForTouch(at: point)
        _pointerRotate(to: angle, animated: animated)
    }
    
    // MARK: - Touch event
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
    }
    
    // MARK: - Touch Tracking
    
    public override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let relativeLocation = touch.location(in: self)
        
        // 只有从热区才能开始拖动指针
        let speedArc = self.speed.arcRange()
        let arcCenterAngle = speedArc.from + (speedArc.to - speedArc.from)/2.0
        let arcCenterPoint = _circlePoint(for: arcCenterAngle, center: _backgroundLayer.position, radius: _radius)
        
        let hotRadius: CGFloat = 60
        let hotRect = CGRect(x: arcCenterPoint.x-hotRadius/2, y: arcCenterPoint.y-hotRadius/2,
                             width: hotRadius, height: hotRadius)
        if !hotRect.contains(relativeLocation) {
            return false
        }
        
        _pointerRotate(to: relativeLocation, animated: false)
        
        if let newSpeed = _speedForTouch(at: relativeLocation) {
            self.speed = newSpeed
        }
        
        return true
    }
    
    public override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let relativeLocation = touch.location(in: self)
        _pointerRotate(to: relativeLocation, animated: false)
        
        if let newSpeed = _speedForTouch(at: relativeLocation) {
            self.speed = newSpeed
        }
        
        return true
    }
    
    public override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        if let relativeLocation = touch?.location(in: self) {
            if let newSpeed = _speedForTouch(at: relativeLocation) {
                self.speed = newSpeed
            }
        }
        
        let speedArc = self.speed.arcRange()
        let centerAngle = speedArc.from + (speedArc.to - speedArc.from)/2.0
        _pointerRotate(to: centerAngle, animated: true)
    }
    
    override func cancelTracking(with event: UIEvent?) {
        let speedArc = self.speed.arcRange()
        let centerAngle = speedArc.from + (speedArc.to - speedArc.from)/2.0
        _pointerRotate(to: centerAngle, animated: true)
    }
}
