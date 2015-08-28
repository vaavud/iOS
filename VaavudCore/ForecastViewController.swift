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
                let state: WeatherState = [.Cloudy, .Sunny, .Rainy][Int(arc4random() % 2)]
                let windDirection = CGFloat(arc4random() % 360)
                let windSpeed = CGFloat(arc4random() % 12)
                
                return ForecastDataPoint(temp: temp, state: state, windDirection: windDirection, windSpeed: windSpeed, hour: hour)
            }
            
            forecastView = ForecastView(frame: scrollView.bounds, data: (0..<53).map { randomDataPoint($0) })
            scrollView.contentSize = forecastView.bounds.size
            scrollView.addSubview(forecastView)
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
        y += view.frame.width + margin
    }
    
    return y - margin
}

enum WeatherState {
    case Cloudy
    case Sunny
    case Rainy
}

struct ForecastDataPoint {
    let temp: CGFloat
    let state: WeatherState
    let windDirection: CGFloat
    let windSpeed: CGFloat
    let hour: Int
}

class ForecastView: UIView {
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(frame: CGRect, data: [ForecastDataPoint]) {
        super.init(frame: frame)

        backgroundColor = UIColor.lightGrayColor()
        
        let maxSpeed = data.reduce(0) { max($0, $1.windSpeed) }
        
        let legend = ForecastLegendView(frame: bounds.insetY(10).moveX(10), maxSpeed: maxSpeed)
        addSubview(legend)

        var dayViews = [UIView]()
        
        for dayData in data.divide(24) {
            let dayView = ForecastDayView(frame: bounds.insetY(10), data: dayData, date: NSDate())
            dayViews.append(dayView)
            addSubview(dayView)
        }
        
        self.frame.size.width = stackHorizontally(left: legend.frame.maxX + 10, margin: 15, dayViews) + 10
    }
}

class ForecastLegendView: UIView {
    // uilabels
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(frame: CGRect, maxSpeed: CGFloat) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.purpleColor()
        
        self.frame.size.width = 30
    }
}

class ForecastDayView: UIView {
    let hourViews: [UIView]
    let dayLegend = UILabel()

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(frame: CGRect, data: [ForecastDataPoint], date: NSDate) {
        dayLegend.text = date.description
        dayLegend.sizeToFit()
        dayLegend.frame.origin.y = frame.height - dayLegend.frame.height
        
        dayLegend.backgroundColor = UIColor.blueColor()

        let size = CGSize(width: 25, height: frame.height - dayLegend.frame.height - 5)
        hourViews = data.map { ForecastHourView(frame: CGRect(origin: CGPoint(), size: size), dataPoint: $0) }
        
        super.init(frame: frame)
        
        backgroundColor = UIColor.greenColor()
        
        addSubview(dayLegend)
        hourViews.map(addSubview)
        
        self.frame.size.width = stackHorizontally(margin: 5, hourViews)
    }
    
    // lines = custom
}

class ForecastHourView: UIView {
    let barView = ShapeView()
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(frame: CGRect, dataPoint: ForecastDataPoint) {
        super.init(frame: frame)
        
        barView.shapeLayer.lineWidth = 5
        barView.shapeLayer.strokeColor = UIColor.orangeColor().CGColor
        barView.shapeLayer.path = UIBezierPath(rect: frame).CGPath
        
        addSubview(barView)
        backgroundColor = UIColor.darkGrayColor()
    }
    
    //    label
    //    image
    //    image/paintcode
    //    custom view
    //    label
}

class ShapeView: UIView {
    var shapeLayer: CAShapeLayer { return layer as! CAShapeLayer }
    override class func layerClass() -> AnyClass { return CAShapeLayer.self }
}





