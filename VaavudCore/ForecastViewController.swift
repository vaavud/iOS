//
//  ForecastViewController.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 27/08/15.
//  Copyright (c) 2015 Andreas Okholm. All rights reserved.
//

import UIKit

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
                let windSpeed = CGFloat(arc4random() % 12)
                
                return ForecastDataPoint(temp: temp, state: state, windDirection: windDirection, windSpeed: windSpeed, hour: hour)
            }
            
            forecastView = ForecastView(frame: scrollView.bounds, data: (0..<53).map { randomDataPoint(1 + ($0 % 24)) })
            
            legendView = ForecastLegendView(frame: sidebar.bounds.insetY(10).insetX(5), maxSpeed: 20, barY: forecastView.barY)
            
            sidebar.addSubview(legendView)

            scrollView.contentSize = forecastView.bounds.size
            scrollView.addSubview(forecastView)
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let dv = forecastView.dayViews[1]
        let offset = scrollView.contentOffset.x - dv.frame.origin.x
        
        if offset < 0 && offset < dv.dayLegend.frame.width {
            dv.dayLegend.frame.origin.x = scrollView.contentOffset.x - dv.frame.origin.x
        }
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

class ForecastView: UIView {
    let barY: (CGFloat, CGFloat)
    let dayViews: [ForecastDayView]
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(frame: CGRect, data: [ForecastDataPoint]) {
        let maxSpeed = data.reduce(0) { max($0, $1.windSpeed) }
        let davViewFrame = CGRect(x: 0, y: 10, width: 0, height: frame.height - 20)
        
        dayViews = data.divide(24, first: 0).map { ForecastDayView(frame: davViewFrame, data: $0, date: NSDate()) }
        barY = dayViews[0].barY

        super.init(frame: frame)
        
        dayViews.map(addSubview)
        
        self.frame.size.width = stackHorizontally(left: 5, margin: 15, dayViews) + 10
    }
}

class ForecastLegendView: UIView {
    // uilabels
    let barY: (CGFloat, CGFloat)

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(frame: CGRect, maxSpeed: CGFloat, barY: (CGFloat, CGFloat)) {
        self.barY = barY
        super.init(frame: frame)
        
        let v = UIView(frame: CGRect(x: 5, y: barY.0, width: frame.width - 10, height: barY.1 - barY.0))
        v.backgroundColor = UIColor.greenColor()
        addSubview(v)
        
        backgroundColor = UIColor.purpleColor().colorWithAlpha(0.3)
        layer.borderColor = UIColor.blackColor().CGColor
        layer.borderWidth = 1
    }
}

class ForecastDayView: UIView {
    let dayLegend = UILabel()
    let barY: (CGFloat, CGFloat)
    
    private let hourViews: [ForecastHourView]
    private let lineView: ForecastLineView

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(frame: CGRect, data: [ForecastDataPoint], date: NSDate) {
        dayLegend.text = "December 21"
        dayLegend.sizeToFit()
        dayLegend.frame.origin.y = frame.height - dayLegend.frame.height
        dayLegend.backgroundColor = UIColor.blueColor().colorWithAlpha(0.3)

        let size = CGSize(width: 27, height: frame.height - dayLegend.frame.height - 5)
        hourViews = data.map { ForecastHourView(frame: CGRect(origin: CGPoint(), size: size), dataPoint: $0) }
        let width = stackHorizontally(margin: 5, hourViews)
        barY = hourViews[0].barY

        let lineFrame = CGRect(x: 0, y: barY.0, width: width, height: barY.1 - barY.0)
        lineView = ForecastLineView(frame: lineFrame)
        lineView.backgroundColor = UIColor.blueColor().colorWithAlpha(0.3)
        
        super.init(frame: frame)
        
        layer.borderColor = UIColor.blackColor().CGColor
        layer.borderWidth = 1

        addSubview(lineView)
        addSubview(dayLegend)
        hourViews.map(addSubview)
        
        self.frame.size.width = width
    }
    
    // lines = custom
}

class ForecastLineView: ShapeView {
    var maxValue = 20
    var spacing = 5
    
    func update() {
        
    }
}

class ForecastHourView: UIView {
    private let temperatureLabel = UILabel()
    private let stateImage = UIImageView()
    private let directionView = UIView()
    private let barView = ShapeView()
    private let hourLabel = UILabel()
    
    private let barMargin: CGFloat = 10
    
    var barY: (start: CGFloat, end: CGFloat) { return (barView.frame.maxY - barMargin, barView.frame.minY + barMargin) }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(frame: CGRect, dataPoint: ForecastDataPoint) {
        super.init(frame: frame)
        
        var views = [UIView]()
        
        temperatureLabel.text = String(Int(round(dataPoint.temp)))
        temperatureLabel.textAlignment = .Center
        temperatureLabel.sizeToFit()
        temperatureLabel.frame.size.width = frame.width
        temperatureLabel.backgroundColor = UIColor.redColor().colorWithAlpha(0.2)
        views.append(temperatureLabel)
        
        stateImage.backgroundColor = UIColor.blueColor().colorWithAlpha(0.2)
        stateImage.image = asset(dataPoint.state)
        stateImage.sizeToFit()
        views.append(stateImage)

        directionView.frame.size.width = frame.width
        directionView.frame.size.height = frame.width
        directionView.backgroundColor = UIColor.purpleColor().colorWithAlpha(0.2)
        views.append(directionView)

        barView.frame.size.width = frame.width
        barView.shapeLayer.lineWidth = 10
        barView.shapeLayer.lineCap = kCALineCapRound
        barView.shapeLayer.strokeColor = UIColor.orangeColor().colorWithAlpha(0.5).CGColor
        barView.shapeLayer.fillColor = nil
        barView.shapeLayer.strokeEnd = dataPoint.windSpeed/20
        views.append(barView)
        barView.backgroundColor = UIColor.brownColor().colorWithAlpha(0.5)

        barView.layer.borderColor = UIColor.blackColor().CGColor
        barView.layer.borderWidth = 1
        
        hourLabel.text = String(dataPoint.hour)
        hourLabel.sizeToFit()
        hourLabel.frame.size.width = frame.width
        hourLabel.textAlignment = .Center
        hourLabel.backgroundColor = UIColor.greenColor().colorWithAlpha(0.2)
        views.append(hourLabel)

        barView.frame.size.height = frame.height - [temperatureLabel, stateImage, directionView, hourLabel].reduce(0) { $0 + $1.frame.height }
        let path = UIBezierPath()
        path.moveToPoint(barView.bounds.lowerMid - CGPoint(x: 0, y: barMargin))
        path.addLineToPoint(barView.bounds.upperMid + CGPoint(x: 0, y: barMargin))
        barView.shapeLayer.path = path.CGPath

        views.map(addSubview)
        stackVertically(top: 0, margin: 0, views)
        
        backgroundColor = UIColor.darkGrayColor().colorWithAlpha(0.3)
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




