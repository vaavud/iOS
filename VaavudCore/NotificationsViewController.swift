//
//  NotificationsViewController.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 05/10/15.
//  Copyright © 2015 Andreas Okholm. All rights reserved.
//

import UIKit

let notificationsWindspeedCeiling: Float = 30

enum NotificationType: Int {
    case None = 0
    case Measurements = 1
    case Both = 2
}

class NotificationsViewController: UIViewController, MKMapViewDelegate {
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var typeControl: UISegmentedControl!
    @IBOutlet weak var windspeedLabel: UILabel!
    @IBOutlet weak var windspeedSlider: UISlider!
    
    private var windspeed: Float = 15
    private var notificationType: NotificationType = .Measurements
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        updateUI()
    }
    
    @IBAction func windspeedChanged(sender: UISlider) {
        windspeed = sender.value*notificationsWindspeedCeiling
        updateUI()
    }
    
    func updateUI() {
        windspeedLabel.text = VaavudFormatter.shared.formattedSpeed(windspeed)
        windspeedSlider.value = windspeed/notificationsWindspeedCeiling
        typeControl.selectedSegmentIndex = notificationType.rawValue
    }
    
    @IBAction func typeChanged(sender: UISegmentedControl) {
        notificationType = NotificationType(rawValue: sender.selectedSegmentIndex) ?? NotificationType.None
    }
}

