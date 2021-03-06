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
    var alertView: UIAlertView?
    
    class func termsUrl(source: String = "settings") -> NSURL {
        let url = "https://vaavud.com/terms/"
        return NSURL(string: url)!
    }

    class func privacyUrl(source: String = "settings") -> NSURL {
        let url = "https://vaavud.com/privacy-policy/"
        return NSURL(string: url)!
    }
    
    class func buySleipnirUrl(source: String = "app") -> NSURL { // testme
        return NSURL(string: "https://vaavud.com/shop?source=iOS")!
    }
    
    class func openBuySleipnir(source: String) {
        LogHelper.log(event: "Pressed-Buy", properties: ["place" : source])
        UIApplication.sharedApplication().openURL(buySleipnirUrl(source))
    }

    func showLocalAlert(titleKey: String, messageKey: String, otherKey: String, action: () -> (), on source: UIViewController) {
        showLocalAlert(titleKey, messageKey: messageKey, cancelKey: nil, otherKey: otherKey, action: action, on: source)
    }

    func showLocalAlert(titleKey: String, messageKey: String, cancelKey: String?, otherKey: String, action: () -> (), on source: UIViewController) {
        let title = NSLocalizedString(titleKey, comment: "")
        let message = NSLocalizedString(messageKey, comment: "")
        let other = NSLocalizedString(otherKey, comment: "")

        if let cancelKey = cancelKey {
            let cancel = NSLocalizedString(cancelKey, comment: "")
            showAlert(title, message: message, cancel: cancel, other: other, action: action, on: source)
        }
        else {
            showAlert(title, message: message, other: other, action: action, on: source)
        }
    }
    
    func showAlert(title: String, message: String, other: String, action: () -> (), on source: UIViewController) {
        showAlert(title, message: message, cancel: nil, other: other, action: action, on: source)
    }
    
    func showAlert(title: String, message: String, cancel: String?, other: String, action: () -> (), on source: UIViewController) {
        alertAction = action
        if objc_getClass("UIAlertController") == nil {
            alertView = UIAlertView(title: title, message: message, delegate: self, cancelButtonTitle: cancel, otherButtonTitles: other)
            alertView?.tag = 1
            alertView?.show()
        }
        else {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
            if let cancel = cancel {
                alert.addAction(UIAlertAction(title: cancel, style: .Cancel, handler: { (action) -> Void in }))
            }
            alert.popoverPresentationController?.sourceView = source.view
            alert.popoverPresentationController?.sourceRect = source.view.bounds
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


