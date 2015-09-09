//
//  ForecastViewController.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 27/08/15.
//  Copyright (c) 2015 Andreas Okholm. All rights reserved.
//

import UIKit

let forecastMaxSteps = 4
let forecastScaleSpacing = 5
let forecastScaleSpacingBft = 3

let forecastTemperatureHeight: CGFloat = 15
let forecastHourHeight: CGFloat = 15
let forecastVerticalPadding: CGFloat = 5
let forecastHorizontalPadding: CGFloat = 10
let forecastLegendPadding: CGFloat = 10
let forecastBorder: CGFloat = 20

let forecastFontSizeSmall: CGFloat = 12
let forecastFontSizeLarge: CGFloat = 15

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
    
//    clear-day, clear-night, rain, snow, sleet, wind, fog, cloudy, partly-cloudy-day, or partly-cloudy-night
    
    init(icon: String) {
        self = [.Cloudy, .Sunny][Int(arc4random() % 2)]
    }
    
    var prefix: String { return "Forecast" }
}

struct ForecastDataPoint {
    let temp: CGFloat
    let state: WeatherState
    let windDirection: CGFloat
    let windSpeed: CGFloat
    let date: NSDate
}

class ForecastLoader {
    static let shared = ForecastLoader()
    
    private let apiKey = "cb4bab2c67a85ffb3ffcd90abfaaba7f"
    private var baseURL: NSURL { return NSURL(string: "https://api.forecast.io/forecast/\(apiKey)/")! }
    private init() { }
    
    func makeRequest(location: CLLocationCoordinate2D, callback: [ForecastDataPoint] -> ()) {
        let forecastUrl = NSURL(string: "\(location.latitude),\(location.longitude)", relativeToURL:baseURL)!
        let sharedSession = NSURLSession.sharedSession()
        
        let downloadTask: NSURLSessionDownloadTask = sharedSession.downloadTaskWithURL(forecastUrl) {
            (location: NSURL!, response: NSURLResponse!, error: NSError!) in

            if error != nil { return }
            
            if let dataObject = NSData(contentsOfURL: location),
                let dict = NSJSONSerialization.JSONObjectWithData(dataObject, options: nil, error: nil) as? NSDictionary,
                let hourly = dict["hourly"] as? [String : AnyObject],
                let data = self.parseHourly(hourly) {
                    dispatch_async(dispatch_get_main_queue()) {
                        callback(data)
                    }
            }
        }
        
        downloadTask.resume()
    }
    
    func parseHourly(dict: [String : AnyObject]) -> [ForecastDataPoint]? {
        if let data = dict["data"] as? [[String : AnyObject]] {
            let dataPoints = data.map { (dataHour: [String : AnyObject]) -> ForecastDataPoint in
                let temp = (CGFloat(dataHour["temperature"] as! Double) + 459.67)*5/9
                let state = WeatherState(icon: dataHour["icon"] as! String)
                let windDirection = CGFloat(dataHour["windBearing"] as! Int)
                let windSpeed = CGFloat(dataHour["windSpeed"] as! Double)*0.44704
                let date = NSDate(timeIntervalSince1970: NSTimeInterval(dataHour["time"] as! Int))
                
                return ForecastDataPoint(temp: temp, state: state, windDirection: windDirection, windSpeed: windSpeed, date: date)
            }

            return dataPoints
        }
        
        return nil
    }
}

class ForecastViewController: UIViewController, UIScrollViewDelegate {
    var location = CLLocationCoordinate2D()
    var data: [ForecastDataPoint]?
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var sidebar: GradientView!
    @IBOutlet weak var sidebarWidth: NSLayoutConstraint!
    
    private var legendView: ForecastLegendView!
    private var forecastView: ForecastView!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "unitsChanged:", name: KEY_UNIT_CHANGED, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        println("viewDidLoad")

        setup(location)
    }
    

    func unitsChanged(note: NSNotification) {
        println("reload")
        if let data = data {
            setup(data)
        }
        else {
            ForecastLoader.shared.makeRequest(location, callback: setup)
        }
    }
    
    func setup(location: CLLocationCoordinate2D) {
        println("setup(location)")

        self.location = location
        mapView.centerCoordinate = location
        mapView.region = MKCoordinateRegion(center: location, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        
        ForecastLoader.shared.makeRequest(location, callback: setup)
    }
    
    func setup(data: [ForecastDataPoint]) {
        println("setup(data) \(data.count)")

        self.data = data
        forecastView?.removeFromSuperview()
        legendView?.removeFromSuperview()
        
        let maxSpeed = data.reduce(0) { max($0, $1.windSpeed) }
        
        let unit = VaavudFormatter.shared.windSpeedUnit
        let unitMax = unit.fromBase(maxSpeed)
        
        let spacing: Int
        
        if unit == .Bft {
            spacing = forecastScaleSpacingBft
        }
        else {
            let calculateSteps = { (space: Int) in Int(ceil(unitMax/CGFloat(space))) }
            var space = forecastScaleSpacing
            while calculateSteps(space) > forecastMaxSteps { space *= 2 }
            spacing = space
        }
        
        let scaleStepCount = Int(ceil(unitMax/CGFloat(spacing)))
        let scaleMax = CGFloat(scaleStepCount*spacing)
        let steps = Array(0...scaleStepCount).map { $0*spacing }
        
        scrollView.bounds.origin = CGPoint()
        forecastView = ForecastView(frame: scrollView.bounds, data: data, steps: steps)
        
        legendView = ForecastLegendView(frame: sidebar.bounds, steps: steps, barFrame: forecastView.barFrame, hourY: forecastView.hourY)
        
        sidebar.addSubview(legendView)
        
        scrollView.scrollEnabled = true
        scrollView.contentSize = forecastView.bounds.size
        scrollView.contentInset.left = sidebarWidth.constant
        scrollView.contentOffset.x = -scrollView.contentInset.left
        scrollView.addSubview(forecastView)
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let offset = scrollView.contentInset.left + scrollView.contentOffset.x
        let adjustment = scrollView.frame.width - scrollView.contentInset.left
        
        for dv in forecastView.dayViews {
            dv.dayLegend.frame.origin.x = min(max(0, offset - dv.frame.origin.x), dv.frame.width - dv.dayLegend.frame.width + 5)
            
            let x = max(0, scrollView.contentOffset.x + scrollView.frame.width - dv.frame.origin.x)
            let n = Int(ceil(x/(dv.barFrame.width + forecastHorizontalPadding)))

            if n > 0 {
                dv.revealLines()
                dv.revealGraph()
            }
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

    init(frame: CGRect, data: [ForecastDataPoint], steps: [Int]) {
        let dvFrame = CGRect(x: 0, y: 0, width: 0, height: frame.height)
        
        dayViews = divide(data) { VaavudFormatter.shared.hourValue($0.date) == 0 }.map { ForecastDayView(frame: dvFrame, data: $0, steps: steps) }
        
        barFrame = dayViews[0].barFrame
        hourY = dayViews[0].hourY
        
        dayViews.map { $0.reveal(0, animated: false) }
        
        super.init(frame: frame)
        
        dayViews.map(addSubview)
        self.frame.size.width = stackHorizontally(left: 0, margin: 25, dayViews) + forecastBorder
    }
}

func doublingsNeeded(from base: CGFloat, to num: CGFloat) -> CGFloat {
    return num > base ? ceil(log2(num/base)) : 0
}

class ForecastLegendView: UIView {
    let barFrame: CGRect
    let hourY: CGFloat
    
    let temperatureUnitLabel = UILabel()
    let unitLabel = UILabel()
    let scaleLabels: [UILabel]
    let hourLabel = UILabel()

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(frame: CGRect, steps: [Int], barFrame: CGRect, hourY: CGFloat) {
        self.barFrame = barFrame
        self.hourY = hourY
        
        let font = UIFont(name: "Roboto-Light", size: forecastFontSizeSmall)
        let fontColor = UIColor.lightGrayColor()
        
        let temperatureUnit = VaavudFormatter.shared.temperatureUnit
        temperatureUnitLabel.text = temperatureUnit.localizedString
        temperatureUnitLabel.textAlignment = .Right
        temperatureUnitLabel.font = font
        temperatureUnitLabel.textColor = fontColor
        temperatureUnitLabel.sizeToFit()
        temperatureUnitLabel.frame.size.width = frame.width - forecastLegendPadding
        temperatureUnitLabel.frame.origin.y = forecastBorder
        
        let unit = VaavudFormatter.shared.windSpeedUnit
        unitLabel.text = unit.localizedString
        unitLabel.textAlignment = .Right
        unitLabel.font = font
        unitLabel.textColor = fontColor
        unitLabel.sizeToFit()
        unitLabel.frame.size.width = frame.width - forecastLegendPadding
        
        scaleLabels = steps.map { value in
            let label = UILabel()
            label.text = String(value)
            label.textAlignment = .Right
            label.font = font
            label.textColor = fontColor
            label.sizeToFit()
            label.frame.size.width = frame.width - forecastLegendPadding
            label.center.y = barFrame.maxY - barFrame.height*CGFloat(value)/CGFloat(steps.last!)
            
            return label
        }
        
        unitLabel.frame.origin.y = scaleLabels.last!.frame.minY - unitLabel.frame.height - 3
        
        hourLabel.text = NSLocalizedString("HOUR", comment: "hour as in watch time") // LOKALT
        hourLabel.textAlignment = .Right
        hourLabel.font = font
        hourLabel.textColor = fontColor
        hourLabel.sizeToFit()
        hourLabel.frame.size.width = frame.width - forecastLegendPadding
        hourLabel.center.y = hourY
        
        super.init(frame: frame)
        
        addSubview(temperatureUnitLabel)
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
    private let graphView: ShapeView
    
    private let ys: [CGFloat]
    private var showing: Int?

    func revealLines() {
        lineView.reveal()
    }
    
    func revealGraph() {
        reveal(hourViews.count)
    }

    func reveal(hours: Int, animated: Bool = true) {
        if hours <= showing {
            return
        }
        
        let newPath = curveUntil(hours, ys, barFrame).CGPath
        
        if animated {
            let anim = CABasicAnimation(keyPath: "path")
            anim.duration = 0.6
            anim.toValue = newPath
            anim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
            anim.removedOnCompletion = false
            anim.fillMode = kCAFillModeForwards
        
            graphView.shapeLayer.addAnimation(anim, forKey: "Show hours")
        }
        else {
            graphView.shapeLayer.path = newPath
        }
        
        showing = hours
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(frame: CGRect, data: [ForecastDataPoint], steps: [Int]) {
        let adjustedBorder = forecastBorder - 10
        
        dayLegend.font = UIFont(name: "Roboto-Bold", size: forecastFontSizeSmall)
        dayLegend.textColor = UIColor.lightGrayColor()
        dayLegend.text = VaavudFormatter.shared.shortDate(data[0].date)
        dayLegend.sizeToFit()
        dayLegend.textAlignment = .Center
        dayLegend.frame.size.width += 10
        dayLegend.frame.origin.y = frame.height - dayLegend.frame.height - adjustedBorder
        
        let size = CGSize(width: 27, height: frame.height - dayLegend.frame.height - adjustedBorder - 5)
        hourViews = data.map { ForecastHourView(frame: CGRect(origin: CGPoint(), size: size), dataPoint: $0, steps: steps) }
        let width = stackHorizontally(margin: forecastHorizontalPadding, hourViews)
        barFrame = hourViews[0].barFrame
        hourY = hourViews[0].hourLabel.center.y
        
        let lineFrame = barFrame.width(width)
        lineView = ForecastLineView(frame: lineFrame, steps: steps)

        let height = barFrame.height
        let unit = VaavudFormatter.shared.windSpeedUnit
        ys = data.map { height*(1 - unit.fromBase($0.windSpeed)/CGFloat(steps.last!)) }

        graphView = ShapeView(frame: lineFrame)
        graphView.shapeLayer.strokeColor = UIColor.vaavudRedColor().CGColor
        graphView.shapeLayer.fillColor = nil
        graphView.shapeLayer.lineWidth = 3
        graphView.shapeLayer.lineCap = kCALineCapRound
        graphView.shapeLayer.lineJoin = kCALineJoinRound
        
        super.init(frame: frame)
        
        addSubview(lineView)
        addSubview(dayLegend)
        hourViews.map(addSubview)
        addSubview(graphView)
        
        self.frame.size.width = width
    }
}

func curveUntil(n: Int, ys: [CGFloat], barFrame: CGRect) -> UIBezierPath {
    let path = UIBezierPath()
    for (i, y) in enumerate(ys) {
        let x = barFrame.width/2 + CGFloat(i)*(barFrame.width + forecastHorizontalPadding)
        let p  = CGPoint(x: x, y: i < n ? y : barFrame.height)
        
        if ys.count == 1 { path.moveToPoint(p + CGPoint(x: -3, y: 0)); path.addLineToPoint(p + CGPoint(x: 3, y: 0)) }
        else if i == 0 { path.moveToPoint(p) }
        else { path.addLineToPoint(p) }
    }

    return path
}

class ForecastLineView: ShapeView {
    var revealed = false
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(frame: CGRect, steps: [Int]) {
        super.init(frame: frame)
     
        shapeLayer.lineWidth = 1
        shapeLayer.lineCap = kCALineCapRound
        shapeLayer.strokeColor = UIColor.lightGrayColor().CGColor
        shapeLayer.fillColor = nil
        shapeLayer.lineDashPattern = [10, 7]
        shapeLayer.strokeEnd = 0
        
        let path = UIBezierPath()
        
        for i in steps {
            let y = frame.height*(1 - CGFloat(i)/CGFloat(steps.last!))
            path.moveToPoint(CGPoint(x: 0, y: y))
            path.addLineToPoint(CGPoint(x: frame.width, y: y))
        }

        shapeLayer.path = path.CGPath
    }
    
    func reveal() {
        if revealed { return }
        
        revealed = true
        
        let anim = CABasicAnimation(keyPath: "strokeEnd")
        anim.duration = 0.5
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
    private let directionView = UIImageView()
    private let barView = ShapeView()
    private let hourLabel = UILabel()
    
    private let barMargin: CGFloat = 10
    
    var barFrame: CGRect { return barView.frame.insetY(barMargin) }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(frame: CGRect, dataPoint: ForecastDataPoint, steps: [Int]) {
        var views = [UIView]()
        
        let stateImage = asset(dataPoint.state)
        let width = stateImage.size.width
        
        let temperatureUnit = VaavudFormatter.shared.temperatureUnit
        temperatureLabel.font = UIFont(name: "Roboto", size: forecastFontSizeLarge)
        temperatureLabel.textColor = fontColor
        temperatureLabel.textAlignment = .Center
        temperatureLabel.adjustsFontSizeToFitWidth = true
        temperatureLabel.numberOfLines = 1
        temperatureLabel.minimumScaleFactor = 0.5
        temperatureLabel.baselineAdjustment = .AlignCenters
        temperatureLabel.text = String(Int(round(temperatureUnit.fromBase(dataPoint.temp)))) + "°"
        temperatureLabel.frame.size.height = forecastTemperatureHeight
        views.append(temperatureLabel)
        
        stateView.image = stateImage
        stateView.sizeToFit()
        views.append(stateView)
        
        directionView.frame.size = CGSize(width: width, height: width)
        directionView.image = UIImage(named: "ForecastWindArrow")
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
        hourLabel.text = String(VaavudFormatter.shared.hourValue(dataPoint.date))
        views.append(hourLabel)

        let heightOfOthers = [temperatureLabel, stateView, directionView, hourLabel].reduce(0) { $0 + $1.frame.height }
        barView.frame.size.height = frame.height - heightOfOthers - 4*forecastVerticalPadding - forecastBorder
        
        let unitValue = VaavudFormatter.shared.windSpeedUnit.fromBase(dataPoint.windSpeed)
        
        let path = UIBezierPath()
        let start = barView.bounds.lowerMid - CGPoint(x: 0, y: barMargin)
        let end = barView.bounds.upperMid + CGPoint(x: 0, y: barMargin)
        path.moveToPoint(start)
        path.addLineToPoint(start + (unitValue/CGFloat(steps.last!))*(end - start))
        barView.shapeLayer.path = path.CGPath

        stackVertically(top: forecastBorder, margin: forecastVerticalPadding, views) + forecastBorder
        
        directionView.transform = Affine.rotation(dataPoint.windDirection.radians)

        super.init(frame: frame.width(width))

        views.map(addSubview)
    }
    
    override func didMoveToWindow() {
        temperatureLabel.frame.size.width = frame.width + forecastHorizontalPadding - 2
        temperatureLabel.frame.origin.x = (frame.width - temperatureLabel.frame.size.width)/2
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



