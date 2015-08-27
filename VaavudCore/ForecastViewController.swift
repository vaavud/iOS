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
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }
}

enum WeatherState {
    case Cloudy
    case Sunny
    case Rainy
}

//struct ForecastDayData {
//    let hourDataPoints: [ForecastHourDataPoint]
//}

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
        
        for dayData in data.divide(24) {
            
        }
        
        let rect = frame
        super.init(frame: rect)
    }
    
    // legend
    // day views
}

class ForecastLegendView: UIView {
    // uilabels
}

class ForecastDayView: UIView {
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(frame: CGRect, data: [ForecastDataPoint]) {

        
        let rect = frame
        super.init(frame: rect)
    }
    
    // hour views = [custom]
    // day legend = label
    // lines = custom
}

class ForecastHourView: UIView {
    //    label
    //    image
    //    image/paintcode
    //    custom view
    //    label
}

