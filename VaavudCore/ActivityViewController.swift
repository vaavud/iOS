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
    let dataSourceKeys = ["sailing", "kitesurfing", "windsurfing", "weather", "flying", "other"]
    private let logHelper = LogHelper(.Login)


    override func viewDidLoad() {
        super.viewDidLoad()
        activityPicker.delegate = self
        logHelper.log("Activity")
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        rowSelected = row
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return NSLocalizedString(dataSourceKeys[row], comment: "")
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return dataSourceKeys.count
    }
    
    @IBAction func savePushed() {
        logHelper.log("Activity", properties: ["type:" : dataSourceKeys[rowSelected]] )
        AuthorizationController.shared.updateActivity(dataSourceKeys[rowSelected])
        gotoAppFrom(navigationController!, inside: view.window!.rootViewController!)
    }
}
