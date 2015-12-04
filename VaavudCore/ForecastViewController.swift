//
//  ForecastViewController.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 27/08/15.
//  Copyright (c) 2015 Andreas Okholm. All rights reserved.
//

import UIKit
import Mixpanel

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

class ForecastAnnotation: NSObject, MKAnnotation {
    let date = NSDate()
    let coordinate: CLLocationCoordinate2D
    var data: [ForecastDataPoint]?
    var geocode: String?
    
    var hasData: Bool { return data != nil }

    init(location: CLLocationCoordinate2D) {
        coordinate = location
    }
    
    func setup(data: [ForecastDataPoint]) {
        self.data = data
    }
    
    var title: String? {
        let ahead = Property.getAsInteger(KEY_MAP_FORECAST_HOURS, defaultValue: 2).integerValue

        let hourDelta: CGFloat = 0.07
        
        if let data = data where data.count > ahead {
            let future = data[ahead].windSpeed
            let current = data[0].windSpeed
            
            if future > current*(1 + CGFloat(ahead)*hourDelta) {
                return NSLocalizedString("FORECAST_WIND_RISING", comment: "") // lokalisera
            }
            else if future < current*(1 - CGFloat(ahead)*hourDelta) {
                return NSLocalizedString("FORECAST_WIND_FALLING", comment: "") // lokalisera
            }
            else {
                return NSLocalizedString("FORECAST_WIND_STABLE", comment: "") // lokalisera
            }
        }
        
        return NSLocalizedString("LOADING", comment: "") // lokalisera
    }

    var subtitle: String? {
        if data == nil {
            return ""
        }
        
        let ahead = Property.getAsInteger(KEY_MAP_FORECAST_HOURS, defaultValue: 2).integerValue
        
        let localHour = NSLocalizedString("MAP_NEXT_HOUR", comment: "") // lokalisera
        let localHours = NSLocalizedString("MAP_NEXT_X_HOURS", comment: "") // lokalisera
        
        return (ahead == 1) ? localHour : String(format: localHours, ahead)
    }
}

let forecastCalloutDirectionSize: CGFloat = 30

class ForecastCalloutView: UIView {
    let icon = UIImageView()
    let empty = UIView()
    let arrowView = UIImageView()
    let label = UILabel()
    var data: [ForecastDataPoint]?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.vaavudBlueColor()
        
        icon.frame.size = CGSize(width: 44, height: 44)
        icon.frame.origin = CGPoint(x: 4, y: 4)
        addSubview(icon)
        
        empty.frame.size = CGSize(width: forecastCalloutDirectionSize, height: forecastCalloutDirectionSize)
        empty.frame.origin.x = icon.frame.maxX + 10
        empty.frame.origin.y = icon.frame.minY
        addSubview(empty)
        
        arrowView.image = UIImage(named: "Map-arrow")
        arrowView.sizeToFit()
        arrowView.center = empty.bounds.center
        arrowView.alpha = 0
        empty.addSubview(arrowView)
        
        label.textColor = UIColor.whiteColor()
        label.font = UIFont.systemFontOfSize(12)
        label.textAlignment = .Center
        label.frame.size = CGSize(width: forecastCalloutDirectionSize + 10, height: 44 - forecastCalloutDirectionSize)
        label.frame.origin.x = icon.frame.maxX + 5
        label.frame.origin.y = icon.frame.maxY - label.frame.height
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        addSubview(label)

//        icon.backgroundColor = UIColor.greenColor()
//        empty.backgroundColor = UIColor.yellowColor()
//        label.backgroundColor = UIColor.redColor().colorWithAlpha(0.2)
//        arrowView.backgroundColor = UIColor.blackColor().colorWithAlpha(0.2)
    }
    
    func setup(annotation: ForecastAnnotation) {
        if let newData = annotation.data, data = data where newData == data {
            return
        }
        
        data = annotation.data
        
        let ahead = Property.getAsInteger(KEY_MAP_FORECAST_HOURS, defaultValue: 2).integerValue

        if let newData = annotation.data where newData.count > ahead {
            let unit = VaavudFormatter.shared.windSpeedUnit
            let dataPoint = newData[ahead]
            
            label.text = String(Int(round(unit.fromBase(dataPoint.windSpeed)))) + " " + unit.localizedString
            arrowView.transform = Affine.rotation(dataPoint.windDirection.radians + π)
            arrowView.alpha = 1
            icon.image = asset(dataPoint.state, prefix: "Map-")
            icon.alpha = 1
        }
        else {
            arrowView.alpha = 0
            label.text = nil
            icon.alpha = 0
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ForecastLoader: NSObject {
    static let shared = ForecastLoader()
    
    private let geocoder = CLGeocoder()
    
    private let apiKey = "cb4bab2c67a85ffb3ffcd90abfaaba7f"
    private var baseURL: NSURL { return NSURL(string: "https://api.forecast.io/forecast/\(apiKey)/")! }
    private override init() { super.init() }
    
    func setup(annotation: ForecastAnnotation, mapView: MKMapView) {
        requestForecast(annotation.coordinate) {
            annotation.setup($0)
            if let pv = mapView.viewForAnnotation(annotation) as? MKPinAnnotationView,
                callout = pv.leftCalloutAccessoryView as? ForecastCalloutView,
                button = pv.rightCalloutAccessoryView as? UIButton {
                    mapView.removeAnnotation(annotation)
                    pv.animatesDrop = false
                    mapView.addAnnotation(annotation)
                    callout.setup(annotation)
                    
                    mapView.selectAnnotation(annotation, animated: true)
                    
                    button.enabled = true
                    pv.animatesDrop = true
            }
        }
        
        requestGeocode(annotation.coordinate) {
            annotation.geocode = $0
        }
    }
    
    func requestGeocode(location: CLLocationCoordinate2D, callback: String -> ()) {
        geocoder.reverseGeocodeLocation(CLLocation(latitude: location.latitude, longitude: location.longitude)) { placemarks, error in
            dispatch_async(dispatch_get_main_queue()) {
                if let error = error {
                    print("Geocode failed with error: \(error)")
                    return
                }
                
                if let first = placemarks?.first,
                    let geocode = first.thoroughfare ?? first.locality ?? first.country {
                        callback(geocode)
                }
            }
        }
    }
    
    func requestForecast(location: CLLocationCoordinate2D, callback: [ForecastDataPoint] -> ()) {
        let forecastUrl = NSURL(string: "\(location.latitude),\(location.longitude)", relativeToURL:baseURL)!
        let sharedSession = NSURLSession.sharedSession()
        
        let downloadTask: NSURLSessionDownloadTask = sharedSession.downloadTaskWithURL(forecastUrl) {
            (location: NSURL?, response: NSURLResponse?, error: NSError?) in
            
            if error != nil { return }
            if let location = location, dataObject = NSData(contentsOfURL: location),
                let dict = (try? NSJSONSerialization.JSONObjectWithData(dataObject, options: [])) as? NSDictionary,
                let hourly = dict["hourly"] as? [String : AnyObject],
                let data = parseHourly(hourly) {
                    dispatch_async(dispatch_get_main_queue()) {
                        callback(data)
                    }
            }
        }
        
        downloadTask.resume()
    }
    
    func requestCurrent(location: CLLocationCoordinate2D, callback: (Double, Double, Int?) -> ()) {
        let forecastUrl = NSURL(string: "\(location.latitude),\(location.longitude)", relativeToURL:baseURL)!
        let sharedSession = NSURLSession.sharedSession()
                
        let downloadTask: NSURLSessionDownloadTask = sharedSession.downloadTaskWithURL(forecastUrl) {
            (location: NSURL?, response: NSURLResponse?, error: NSError?) in
            if error != nil { return }
            if let location = location,
                dataObject = NSData(contentsOfURL: location),
                dict = (try? NSJSONSerialization.JSONObjectWithData(dataObject, options: [])) as? NSDictionary,
                currently = dict["currently"] as? [String : AnyObject],
                data = parseCurrently(currently) {
                    dispatch_async(dispatch_get_main_queue()) {
                        callback(data)
                    }
            }
        }
        
        downloadTask.resume()
    }
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

func parseCurrently(dict: [String : AnyObject]) -> (Double, Double, Int?)? {
    if let temperature = dict["temperature"] as? Double, pressure = dict["pressure"] as? Double {
        return ((temperature + 459.67)*5/9, pressure, dict["windBearing"] as? Int)
    }
    
    return nil
}


protocol AssetState {
    var prefix: String { get }
    var rawValue: String { get }
}

func asset(state: AssetState) -> UIImage {
    return UIImage(named: state.prefix + state.rawValue)!
}

func asset(state: AssetState, prefix: String) -> UIImage {
    return UIImage(named: prefix + state.rawValue)!
}

enum WeatherState: String, AssetState {
    case ClearDay = "clear-day"
    case ClearNight = "clear-night"
    case Rain = "rain"
    case Snow = "snow"
    case Sleet = "sleet"
    case Wind = "wind"
    case Fog = "fog"
    case Cloudy = "cloudy"
    case PartlyCloudyDay = "partly-cloudy-day"
    case PartlyCloudyNight = "partly-cloudy-night"
    case Unknown = "unknown"
    
    init(icon: String) {
        self = WeatherState(rawValue: icon) ?? .Unknown
    }
    
    var prefix: String { return "Forecast-" }
}

struct ForecastDataPoint: Equatable {
    let temp: CGFloat
    let state: WeatherState
    let windDirection: CGFloat
    let windSpeed: CGFloat
    let date: NSDate
}

func ==(lhs: ForecastDataPoint, rhs: ForecastDataPoint) -> Bool {
    return lhs.temp == rhs.temp &&
        lhs.state == rhs.state &&
        lhs.windDirection == rhs.windDirection &&
        lhs.windSpeed == rhs.windSpeed &&
        lhs.date == rhs.date
}

class ForecastViewController: UIViewController, UIScrollViewDelegate {
    var location: CLLocationCoordinate2D?
    var geocode: String?
    var data: [ForecastDataPoint]?
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var sidebar: GradientView!
    @IBOutlet weak var sidebarWidth: NSLayoutConstraint!
    
    @IBOutlet weak var proBadge: UIButton!
    
    private var legendView: ForecastLegendView!
    private var forecastView: ForecastView!

    private var didSetup = false
    
    private let logHelper = LogHelper(.Forecast, counters: "scrolled")

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        if Property.isMixpanelEnabled() {
            Mixpanel.sharedInstance().track("Forecast Screen")
        }
            
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "unitsChanged:", name: KEY_UNIT_CHANGED, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewDidAppear(animated: Bool) {
        logHelper.began()
    }
    
    override func viewDidDisappear(animated: Bool) {
        logHelper.ended()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if didSetup { return }
        
        didSetup = true
        setupMap()
        setupForecast()
        
        if let geocode = geocode {
            title = geocode
        }
        else if let location = location {
            ForecastLoader.shared.requestGeocode(location) { self.title = $0 }
        }
        
        if !Property.getAsBoolean(KEY_FORECAST_OVERLAY_SHOWN, defaultValue: false), let tbc = tabBarController {
            Property.setAsBoolean(true, forKey: KEY_FORECAST_OVERLAY_SHOWN)
            if Property.isMixpanelEnabled() {
                Mixpanel.sharedInstance().track("Forecast Pro Badge Overlay")
            }

            let p = tbc.view.convertPoint(proBadge.center, fromView: nil)
            let pos = CGPoint(x: p.x/tbc.view.frame.width, y: p.y/tbc.view.frame.height)
            let text = "Vejrudsigter er en pro funktion, som er gratis ind til videre! Tryk på emblemet for mere information." // lokalisera
            let icon = UIImage(named: "ForecastProOverlay")
            tbc.view.addSubview(RadialOverlay(frame: tbc.view.bounds, position: pos, text: text, icon: icon, radius: 50))
        }
    }
    
    func unitsChanged(note: NSNotification) {
        setupForecast()
    }
    
    func setup(annotation: ForecastAnnotation) {
        if let annotationData = annotation.data {
            location = annotation.coordinate
            data = annotationData
        }
    }
    
    func setupMap() {
        if let location = location {
            mapView.centerCoordinate = location
            mapView.region = MKCoordinateRegion(center: location, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        }
    }
    
    func setupForecast() {
        forecastView?.removeFromSuperview()
        legendView?.removeFromSuperview()
        
        if let data = data {
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
    }
    
    @IBAction func tappedAttribution(sender: UIButton) {
        if let url = NSURL(string: "http://forecast.io") {
            LogHelper.log(event: "Tapped-Forecast-Attribution", properties: ["place" : "forecast"])
            UIApplication.sharedApplication().openURL(url)
        }
    }
    
    @IBAction func tappedProBadge(sender: UIButton) {
        LogHelper.log(event: "Tapped-Pro-Badge", properties: ["place" : "forecast"])
    }

    func scrollViewDidScroll(scrollView: UIScrollView) {
        let offset = scrollView.contentInset.left + scrollView.contentOffset.x
        
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
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        logHelper.increase("scrolled")
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let webViewController = segue.destinationViewController as? WebViewController {
            if segue.identifier == "ProBadgeSeque" {
                if Property.isMixpanelEnabled() {
                    Mixpanel.sharedInstance().track("Pro Badge Screen")
                }

                webViewController.title = "Pro features"

                if let file = NSBundle.mainBundle().pathForResource("ProBadge", ofType: "html") {
                    webViewController.baseUrl = NSURL(fileURLWithPath: NSBundle.mainBundle().bundlePath)
                    webViewController.html = try? String(contentsOfFile: file, encoding: NSUTF8StringEncoding)
                }
                else {
                    webViewController.html = "Vi vil tilføje flere nye spændende funktioner til Vaavud appen. Nogle af disse funktioner vil kun være tilgængelig for Pro medlemmer. For en begrænset periode, så kan alle vores brugere prøve dem!".html()
                }
            }
        }
    }
}

class ForecastView: UIView {
    let barFrame: CGRect
    let hourY: CGFloat
    let dayViews: [ForecastDayView]
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(frame: CGRect, data: [ForecastDataPoint], steps: [Int]) {
        let dvFrame = CGRect(x: 0, y: 0, width: 0, height: frame.height)
        
        dayViews = divide(data) { VaavudFormatter.shared.hourValue($0.date) == 0 }.map { ForecastDayView(frame: dvFrame, data: $0, steps: steps) }
        
        barFrame = dayViews[0].barFrame
        hourY = dayViews[0].hourY
        
        _ = dayViews.map { $0.reveal(0, animated: false) }
        
        super.init(frame: frame)
        
        _ = dayViews.map(addSubview)
        self.frame.size.width = stackHorizontally(0, margin: 25, views: dayViews) + forecastBorder
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

    required init?(coder aDecoder: NSCoder) {
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
        
        hourLabel.text = NSLocalizedString("TIME", comment: "") // lokalisera
        hourLabel.textAlignment = .Right
        hourLabel.font = font
        hourLabel.textColor = fontColor
        hourLabel.sizeToFit()
        hourLabel.frame.size.width = frame.width - forecastLegendPadding
        hourLabel.center.y = hourY
        
        super.init(frame: frame)
        
        addSubview(temperatureUnitLabel)
        addSubview(unitLabel)
        _ = scaleLabels.map(addSubview)
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
        
        let newPath = curveUntil(hours, ys: ys, barFrame: barFrame).CGPath
        
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

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(frame: CGRect, data: [ForecastDataPoint], steps: [Int]) {
        let adjustedBorder = forecastBorder - 10
        
        dayLegend.font = UIFont(name: "Roboto-Bold", size: forecastFontSizeSmall)
        dayLegend.textColor = UIColor.lightGrayColor()
        dayLegend.text = VaavudFormatter.shared.localizedRelativeDate(data[0].date)
        dayLegend.sizeToFit()
        dayLegend.textAlignment = .Center
        dayLegend.frame.size.width += 10
        dayLegend.frame.origin.y = frame.height - dayLegend.frame.height - adjustedBorder
        
        let size = CGSize(width: 27, height: frame.height - dayLegend.frame.height - adjustedBorder - 5)
        hourViews = data.map { ForecastHourView(frame: CGRect(origin: CGPoint(), size: size), dataPoint: $0, steps: steps) }
        let width = stackHorizontally(margin: forecastHorizontalPadding, views: hourViews)
        barFrame = hourViews[0].barFrame
        hourY = hourViews[0].hourLabel.center.y
        
        let lineFrame = barFrame.width(width)
        lineView = ForecastLineView(frame: lineFrame, steps: steps, hours: hourViews.count)

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
        _ = hourViews.map(addSubview)
        addSubview(graphView)
        
        self.frame.size.width = width
    }
}

func curveUntil(n: Int, ys: [CGFloat], barFrame: CGRect) -> UIBezierPath {
    let path = UIBezierPath()
    for (i, y) in ys.enumerate() {
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
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(frame: CGRect, steps: [Int], hours: Int) {
        super.init(frame: frame)
     
        shapeLayer.lineWidth = 1
        shapeLayer.lineCap = kCALineCapRound
        shapeLayer.strokeColor = UIColor.lightGrayColor().CGColor
        shapeLayer.fillColor = nil
        shapeLayer.strokeEnd = 0
        
        let path = UIBezierPath()
        
        let hourWidth = (frame.width + forecastHorizontalPadding)/CGFloat(hours)
        let dashWidth = (hourWidth - 2*forecastHorizontalPadding)/2
        
        for i in steps {
            let y = frame.height*(1 - CGFloat(i)/CGFloat(steps.last!))
            for j in 0..<hours {
                let start = CGPoint(x: CGFloat(j)*hourWidth, y: y)
                path.moveToPoint(start)
                path.addLineToPoint(start + CGPoint(x: dashWidth, y: 0))
                
                path.moveToPoint(start + CGPoint(x: dashWidth + forecastHorizontalPadding, y: 0))
                path.addLineToPoint(start + CGPoint(x: 2*dashWidth + forecastHorizontalPadding, y: 0))
            }
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
    private let fontColor = UIColor.darkGrayColor()

    private let temperatureLabel = UILabel()
    private let stateView = UIImageView()
    private let directionView = UIImageView()
    private let barView = ShapeView()
    private let hourLabel = UILabel()
    
    private let barMargin: CGFloat = 10
    
    var barFrame: CGRect { return barView.frame.insetY(barMargin) }
    
    required init?(coder aDecoder: NSCoder) {
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

        stackVertically(forecastBorder, margin: forecastVerticalPadding, views: views) + forecastBorder
        
        directionView.transform = Affine.rotation(dataPoint.windDirection.radians + π)

        super.init(frame: frame.width(width))

//        backgroundColor = UIColor.redColor().colorWithAlpha(0.2)
        
        _ = views.map(addSubview)
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



