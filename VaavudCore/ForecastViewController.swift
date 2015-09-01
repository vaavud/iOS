//
//  ForecastViewController.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 27/08/15.
//  Copyright (c) 2015 Andreas Okholm. All rights reserved.
//

import UIKit

let forecastScaleMax = 20
let forecastScaleSpacing = 5

let forecastTemperatureHeight: CGFloat = 15
let forecastHourHeight: CGFloat = 15
let forecastVerticalPadding: CGFloat = 5
let forecastHorizontalPadding: CGFloat = 10
let forecastLegendPadding: CGFloat = 10
let forecastBorder: CGFloat = 20

let forecastFontSizeSmall: CGFloat = 12
let forecastFontSizeLarge: CGFloat = 15

extension Array {
    func divide(n: Int) -> [[T]] {
        var out = [[T]]()
        let days = count/n + (count % n > 0 ? 1 : 0)
        for i in 0..<days { out.append(Array(self[i*n..<min((i + 1)*n, count)])) }
        
        return out
    }
    
    func divide(n: Int, first: Int) -> [[T]] {
        precondition(first < n, "First must be smaller than n")
        
        var out = [[T]]()
        let offset = min(first, count)
        if offset > 0 {
            out.append(Array(self[0..<offset]))
        }
        
        let countLeft = count - offset
        
        let daysLeft = countLeft/n + (countLeft % n > 0 ? 1 : 0)
        
        for i in 0..<daysLeft {
            out.append(Array(self[offset + i*n..<min(offset + (i + 1)*n, count)]))
        }
        
        return out
    }
}

func stackHorizontally(left: CGFloat = 0, margin: CGFloat = 0, views: [UIView]) -> CGFloat {
    var x = left
    
    for view in views {
        view.frame.origin.x = x
        x += view.frame.width + margin
    }
    
    return x - margin
}

func stackVertically(top: CGFloat = 0, margin: CGFloat = 0, views: [UIView]) -> CGFloat {
    var y = top
    
    for view in views {
        view.frame.origin.y = y
        y += view.frame.height + margin
    }
    
    return y - margin
}

protocol AssetState {
    var prefix: String { get }
    var rawValue: String { get }
}

func asset(state: AssetState) -> UIImage {
    return UIImage(named: state.prefix + state.rawValue)!
}

enum WeatherState: String, AssetState {
    case Cloudy = "Cloud"
    case Sunny = "SunCloud"
    
    var prefix: String { return "Forecast" }
}

struct ForecastDataPoint {
    let temp: CGFloat
    let state: WeatherState
    let windDirection: CGFloat
    let windSpeed: CGFloat
    let hour: Int
}

class ForecastViewController: UIViewController, UIScrollViewDelegate {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var sidebar: GradientView!
    @IBOutlet weak var sidebarWidth: NSLayoutConstraint!
    
    var legendView: ForecastLegendView!
    var forecastView: ForecastView!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if forecastView == nil {
            func randomDataPoint(hour: Int) -> ForecastDataPoint {
                let temp = CGFloat(arc4random() % 20) + 10
                let state: WeatherState = [.Cloudy, .Sunny,][Int(arc4random() % 2)]
                let windDirection = CGFloat(arc4random() % 360)
                let windSpeed = 0.1 + CGFloat(arc4random() % 12)
                
                return ForecastDataPoint(temp: temp, state: state, windDirection: windDirection, windSpeed: windSpeed, hour: hour)
            }
            
            forecastView = ForecastView(frame: scrollView.bounds, data: (0..<53).map { randomDataPoint(1 + ($0 % 24)) })
            
            legendView = ForecastLegendView(frame: sidebar.bounds, maxSpeed: 20, barFrame: forecastView.barFrame, hourY: forecastView.hourY)
            
            sidebar.addSubview(legendView)

            scrollView.contentSize = forecastView.bounds.size
            scrollView.contentInset.left = sidebarWidth.constant
            scrollView.contentOffset.x = -scrollView.contentInset.left
            scrollView.addSubview(forecastView)
        }
    }
    
    var animating = false
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let offset = scrollView.contentInset.left + scrollView.contentOffset.x
        forecastView.dayViews.map { dv in
            dv.dayLegend.frame.origin.x = min(max(0, offset - dv.frame.origin.x), dv.frame.width - dv.dayLegend.frame.width + 5)
        }
        
        if offset > 20 && !animating {
            forecastView.animate()
            animating = true
        }
    }
}

class ForecastView: UIView {
    let barFrame: CGRect
    let hourY: CGFloat
    let dayViews: [ForecastDayView]
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(frame: CGRect, data: [ForecastDataPoint]) {
        let maxSpeed = data.reduce(0) { max($0, $1.windSpeed) }
        let dayViewFrame = CGRect(x: 0, y: 0, width: 0, height: frame.height)
        
        dayViews = data.divide(24, first: 0).map { ForecastDayView(frame: dayViewFrame, data: $0, date: NSDate()) }
        barFrame = dayViews[0].barFrame
        hourY = dayViews[0].hourY
        super.init(frame: frame)
        
        dayViews.map(addSubview)
        
        self.frame.size.width = stackHorizontally(left: 0, margin: 25, dayViews) + forecastBorder
    }
    
    func animate() {
        dayViews.map { $0.animate() }
    }
}

class ForecastLegendView: UIView {
    let barFrame: CGRect
    let hourY: CGFloat
    
    let unitLabel = UILabel()
    let scaleLabels: [UILabel]
    let hourLabel = UILabel()

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(frame: CGRect, maxSpeed: CGFloat, barFrame: CGRect, hourY: CGFloat) {
        self.barFrame = barFrame
        self.hourY = hourY
        
        let font = UIFont(name: "Roboto-Light", size: forecastFontSizeSmall)
        let fontColor = UIColor.lightGrayColor()
        
        unitLabel.text = "m/s"
        unitLabel.textAlignment = .Right
        unitLabel.font = font
        unitLabel.textColor = fontColor
        unitLabel.sizeToFit()
        unitLabel.frame.size.width = frame.width - forecastLegendPadding
        
        scaleLabels = (1...forecastScaleMax/forecastScaleSpacing).map { i in
            let value = i*forecastScaleSpacing
            let label = UILabel()
            label.text = String(value)
            label.textAlignment = .Right
            label.font = font
            label.textColor = fontColor
            label.sizeToFit()
            label.frame.size.width = frame.width - forecastLegendPadding
            label.center.y = barFrame.maxY - barFrame.height*CGFloat(value)/CGFloat(forecastScaleMax)
            
            return label
        }
        
        unitLabel.frame.origin.y = scaleLabels.last!.frame.minY - unitLabel.frame.height - 3
        
        hourLabel.text = "hour"
        hourLabel.textAlignment = .Right
        hourLabel.font = font
        hourLabel.textColor = fontColor
        hourLabel.sizeToFit()
        hourLabel.frame.size.width = frame.width - forecastLegendPadding
        hourLabel.center.y = hourY
        
        super.init(frame: frame)
        
        addSubview(unitLabel)
        scaleLabels.map(addSubview)
        addSubview(hourLabel)
    }
}

class ForecastDayView: UIView {
    let dayLegend = UILabel()
    let barFrame: CGRect
    let hourY: CGFloat
    
    private let hourViews: [ForecastHourView]
    private let lineView: ForecastLineView

    func animate() {
        lineView.animate()
        hourViews.map { $0.animate() }
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(frame: CGRect, data: [ForecastDataPoint], date: NSDate) {
        let adjustedBorder = forecastBorder - 10
        
        dayLegend.font = UIFont(name: "Roboto-Bold", size: forecastFontSizeSmall)
        dayLegend.textColor = UIColor.lightGrayColor()
        dayLegend.text = "December 21"
        dayLegend.sizeToFit()
        dayLegend.textAlignment = .Center
        dayLegend.frame.size.width += 10
        dayLegend.frame.origin.y = frame.height - dayLegend.frame.height - adjustedBorder
        
        let size = CGSize(width: 27, height: frame.height - dayLegend.frame.height - adjustedBorder - 5)
        hourViews = data.map { ForecastHourView(frame: CGRect(origin: CGPoint(), size: size), dataPoint: $0) }
        let width = stackHorizontally(margin: forecastHorizontalPadding, hourViews)
        barFrame = hourViews[0].barFrame
        hourY = hourViews[0].hourLabel.center.y
        
        let lineFrame = barFrame.width(width)
        lineView = ForecastLineView(frame: lineFrame)
        
        super.init(frame: frame)
        
        addSubview(lineView)
        addSubview(dayLegend)
        hourViews.map(addSubview)
        
        self.frame.size.width = width
    }
}

class ForecastLineView: ShapeView {
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
     
        shapeLayer.lineWidth = 1
        shapeLayer.lineCap = kCALineCapRound
        shapeLayer.strokeColor = UIColor.lightGrayColor().CGColor
        shapeLayer.fillColor = nil
        shapeLayer.lineDashPattern = [10, 7]
        shapeLayer.strokeEnd = 0
        
        let path = UIBezierPath()
        
        for i in 0...forecastScaleMax/forecastScaleSpacing {
            let y = frame.height*(1 - CGFloat(i*forecastScaleSpacing)/CGFloat(forecastScaleMax))
            path.moveToPoint(CGPoint(x: 0, y: y))
            path.addLineToPoint(CGPoint(x: frame.width, y: y))
        }

        shapeLayer.path = path.CGPath
    }
    
    func animate() {
        let anim = CABasicAnimation(keyPath: "strokeEnd")
        anim.duration = 1
        anim.fromValue = 0
        anim.toValue = 1
        
        shapeLayer.addAnimation(anim, forKey: "StrokeAnim")
        shapeLayer.strokeEnd = 1
    }
}

class ForecastHourView: UIView {
    private let fontColor = UIColor.lightGrayColor()

    private let temperatureLabel = UILabel()
    private let stateView = UIImageView()
    private let directionView = UIView()
    private let barView = ShapeView()
    private let hourLabel = UILabel()
    
    private let barMargin: CGFloat = 5
    
    var barFrame: CGRect { return barView.frame.insetY(barMargin) }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(frame: CGRect, dataPoint: ForecastDataPoint) {
        var views = [UIView]()
        
        let stateImage = asset(dataPoint.state)
        let width = stateImage.size.width
        
        temperatureLabel.frame.size = CGSize(width: width, height: forecastTemperatureHeight)
        temperatureLabel.font = UIFont(name: "Roboto", size: forecastFontSizeLarge)
        temperatureLabel.textColor = fontColor
        temperatureLabel.textAlignment = .Center
        temperatureLabel.text = String(Int(round(dataPoint.temp)))
        views.append(temperatureLabel)
        
        stateView.image = stateImage
        stateView.sizeToFit()
        views.append(stateView)

        directionView.frame.size = CGSize(width: width, height: width)
        views.append(directionView)

        barView.frame.size.width = width
        barView.shapeLayer.lineWidth = 10
        barView.shapeLayer.lineCap = kCALineCapRound
        barView.shapeLayer.strokeColor = UIColor.vaavudLightGreyColor().colorWithAlpha(0.4).CGColor
        barView.shapeLayer.fillColor = nil
        barView.shapeLayer.strokeEnd = 0
        views.append(barView)

        hourLabel.frame.size = CGSize(width: width, height: forecastHourHeight)
        hourLabel.font = UIFont(name: "Roboto-Light", size: forecastFontSizeLarge)
        hourLabel.textColor = fontColor
        hourLabel.textAlignment = .Center
        hourLabel.text = String(dataPoint.hour)
        views.append(hourLabel)

        let heightOfOthers = [temperatureLabel, stateView, directionView, hourLabel].reduce(0) { $0 + $1.frame.height }
        barView.frame.size.height = frame.height - heightOfOthers - 4*forecastVerticalPadding - forecastBorder
        
        let path = UIBezierPath()
        let start = barView.bounds.lowerMid - CGPoint(x: 0, y: barMargin)
        let end = barView.bounds.upperMid + CGPoint(x: 0, y: barMargin)
        path.moveToPoint(start)
        path.addLineToPoint(start + (dataPoint.windSpeed/20)*(end - start))
        barView.shapeLayer.path = path.CGPath

        stackVertically(top: forecastBorder, margin: forecastVerticalPadding, views) + forecastBorder
        
        super.init(frame: frame.width(width))

        views.map(addSubview)
    }
    
    func animate() {
        let anim = CABasicAnimation(keyPath: "strokeEnd")
        anim.duration = 0.30
        anim.fromValue = 0
        anim.toValue = 1
        
        barView.shapeLayer.addAnimation(anim, forKey: "StrokeAnim")
        barView.shapeLayer.strokeEnd = 1
    }
}

class ShapeView: UIView {
    var shapeLayer: CAShapeLayer { return layer as! CAShapeLayer }
    override class func layerClass() -> AnyClass { return CAShapeLayer.self }
}

class GradientView: UIView {
    var gradientLayer: CAGradientLayer { return layer as! CAGradientLayer }

    @IBInspectable var startColor: UIColor = UIColor.whiteColor() { didSet { update() } }
    @IBInspectable var endColor: UIColor = UIColor.whiteColor().colorWithAlphaComponent(0) { didSet { update() } }
    
    @IBInspectable var start: CGFloat = 0 { didSet { update() } }
    @IBInspectable var end: CGFloat = 1 { didSet { update() } }
    
    @IBInspectable var horizontal: Bool = true { didSet { update() } }
    
    override class func layerClass() -> AnyClass {
        return CAGradientLayer.self
    }
    
    func update() {
        gradientLayer.startPoint = horizontal ? CGPoint(x: start, y: 0) : CGPoint(x: 0, y: start)
        gradientLayer.endPoint = horizontal ? CGPoint(x: end, y: 0) : CGPoint(x: 0, y: end)
        gradientLayer.colors = [startColor.CGColor, endColor.CGColor]
    }
}




