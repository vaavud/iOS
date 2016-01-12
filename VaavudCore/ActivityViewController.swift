//
//  ActivityViewController.swift
//  Vaavud
//
//  Created by Diego R on 11/27/15.
//  Copyright © 2015 Andreas Okholm. All rights reserved.
//

import UIKit

class ActivityViewController: UIViewController, UIPickerViewDelegate {
    @IBOutlet weak var activityPicker: UIPickerView!
    
    var rowSelected = 0
    let pickerDataSource = ["sailing", "kitesurfing", "windsurfing", "weather", "flying", "other"]

    override func viewDidLoad() {
        super.viewDidLoad()
        activityPicker.delegate = self
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        rowSelected = row
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerDataSource[row]
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerDataSource.count
    }

    @IBAction func savePushed() {
        AuthorizationController.shared.updateActivity(pickerDataSource[rowSelected])
        gotoAppFrom(navigationController!, inside: view.window!.rootViewController!)
    }
}
