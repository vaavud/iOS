//
//  VaavudInteractions.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 03/02/15.
//  Copyright (c) 2015 Andreas Okholm. All rights reserved.
//

import Foundation
import UIKit

class VaavudInteractions: NSObject, UIAlertViewDelegate {
    var alertAction: () -> () = { }
    
    class func openBuySleipnir(source: String) {
        Mixpanel.sharedInstance().track(source + " Clicked Buy")
        let urlString = "http://vaavud.com/mobile-shop-redirect/?country=" + Property.getAsString("country") +
            "&language=" + Property.getAsString("language") +
            "&ref=" + Mixpanel.sharedInstance().distinctId +
            "&source=" + source
        
        UIApplication.sharedApplication().openURL(NSURL(string: urlString)!)
    }
    
    func showLocalAlert(titleKey: String, messageKey: String, cancelKey: String = "BUTTON_CANCEL", otherKey: String, action: () -> (), on source: UIViewController) {
        let title = NSLocalizedString(titleKey, comment: "")
        let message = NSLocalizedString(messageKey, comment: "")
        let cancel = NSLocalizedString(cancelKey, comment: "")
        let other = NSLocalizedString(otherKey, comment: "")
        showAlert(title, message: message, cancel: cancel, other: other, action: action, on: source)
    }
    
    func showAlert(title: String, message: String, cancel: String, other: String, action: () -> (), on source: UIViewController) {
        alertAction = action
        if objc_getClass("UIAlertController") == nil {
            let alert = UIAlertView(title: title, message: message, delegate: self, cancelButtonTitle: cancel, otherButtonTitles: other)
            alert.tag = 1
            alert.show()
        }
        else {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: cancel, style: .Cancel, handler: { (action) -> Void in }))
            alert.addAction(UIAlertAction(title: other, style: UIAlertActionStyle.Default, handler: { (action) -> Void in self.alertAction() }))
            source.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if alertView.tag == 1 {
            if buttonIndex == 1 {
                alertAction()
            }
        }
    }
}


