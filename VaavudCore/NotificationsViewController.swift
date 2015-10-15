//
//  NotificationsViewController.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 05/10/15.
//  Copyright © 2015 Andreas Okholm. All rights reserved.
//

import UIKit

class NotificationsViewController: UIViewController, MKMapViewDelegate {
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var typeControl: UISegmentedControl!
    @IBOutlet weak var windspeedLabel: UILabel!
    @IBOutlet weak var windspeedSlider: UISlider!
    
    @IBAction func windspeedChanged(sender: UISlider) {
    }
    
    @IBAction func typeChanged(sender: UISegmentedControl) {
    }
}

