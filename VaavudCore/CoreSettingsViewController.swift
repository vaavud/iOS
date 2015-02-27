//
//  CoreSettingsViewController.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 11/02/15.
//  Copyright (c) 2015 Andreas Okholm. All rights reserved.
//

import Foundation

class CoreSettingsTableViewController: UITableViewController {
    @IBOutlet weak var logoutButton: UIBarButtonItem!
    
    @IBOutlet weak var speedUnitControl: UISegmentedControl!
    @IBOutlet weak var directionUnitControl: UISegmentedControl!
    @IBOutlet weak var pressureUnitControl: UISegmentedControl!
    @IBOutlet weak var temperatureUnitControl: UISegmentedControl!
//    @IBOutlet weak var facebookControl: UISwitch!
    
    @IBOutlet weak var versionLabel: UILabel!
    
    override func viewDidLoad() {
        versionLabel.text = NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as? String
//        facebookControl.on = Property.getAsBoolean("enableFacebookShareDialog", defaultValue: false)
        readUnits()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "unitsChanged:", name: "UnitChange", object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        refreshLogoutButton()
    }
    
    func refreshLogoutButton() {
        let titleKey = AccountManager.sharedInstance().isLoggedIn() ? "REGISTER_BUTTON_LOGOUT" : "REGISTER_BUTTON_LOGIN"
        logoutButton.title = NSLocalizedString(titleKey, comment: "")
    }
    
    func unitsChanged(note: NSNotification) {
        if note.object as? CoreSettingsTableViewController != self {
            readUnits()
        }
    }
    
    func postUnitChange() {
        NSNotificationCenter.defaultCenter().postNotificationName("UnitChange", object: self)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func readUnits() {
        if let speedUnit = Property.getAsInteger("windSpeedUnit")?.integerValue {
            speedUnitControl.selectedSegmentIndex = speedUnit
        }
        if let directionUnit = Property.getAsInteger("directionUnit")?.integerValue {
            directionUnitControl.selectedSegmentIndex = directionUnit
        }
        if let pressureUnit = Property.getAsInteger("pressureUnit")?.integerValue {
            pressureUnitControl.selectedSegmentIndex = pressureUnit
        }
        if let temperatureUnit = Property.getAsInteger("temperatureUnit")?.integerValue {
            temperatureUnitControl.selectedSegmentIndex = temperatureUnit
        }
    }
    
    @IBAction func calibrationDone(segue: UIStoryboardSegue) {
    
    }
    
    @IBAction func logInOutTapped(sender: AnyObject) {
        if AccountManager.sharedInstance().isLoggedIn() {
            VaavudInteractions().showLocalAlert("REGISTER_BUTTON_LOGOUT",
                messageKey: "DIALOG_CONFIRM",
                otherKey: "BUTTON_OK",
                action: { self.logoutConfirmed() },
                on: self)
        }
        else {
            registerUser()
            refreshLogoutButton()
        }
    }
    
    func logoutConfirmed() {
        AccountManager.sharedInstance().logout()
        refreshLogoutButton()
    }
    
    func registerUser() {
        let register = UIStoryboard(name: "Register", bundle: nil).instantiateViewControllerWithIdentifier("RegisterViewController") as RegisterViewController
        register.completion = { loggedIn in let _ = self.navigationController?.popToViewController(self, animated: true) }

        navigationController?.pushViewController(register, animated: true)
    }
    
    @IBAction func changedSpeedUnit(sender: UISegmentedControl) {
        Property.setAsInteger(sender.selectedSegmentIndex, forKey: "windSpeedUnit")
        postUnitChange()
    }
    
    @IBAction func changedDirectionUnit(sender: UISegmentedControl) {
        Property.setAsInteger(sender.selectedSegmentIndex, forKey: "directionUnit")
        postUnitChange()
    }
    
    @IBAction func changedPressureUnit(sender: UISegmentedControl) {
        Property.setAsInteger(sender.selectedSegmentIndex, forKey: "pressureUnit")
        postUnitChange()
    }
    
    @IBAction func changedTemperatureUnit(sender: UISegmentedControl) {
        Property.setAsInteger(sender.selectedSegmentIndex, forKey: "temperatureUnit")
        postUnitChange()
    }
    
    @IBAction func changedFacebookSetting(sender: UISwitch) {
        Property.setAsBoolean(sender.on, forKey: "enableFacebookShareDialog")
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let webViewController = segue.destinationViewController as? WebViewController {
            if segue.identifier == "AboutSegue" {
                webViewController.html = NSLocalizedString("ABOUT_VAAVUD_TEXT", comment: "").html()
            }
            else if segue.identifier == "TermsSegue" {
                webViewController.url = VaavudInteractions.termsUrl()
                webViewController.title = NSLocalizedString("LINK_TERMS_OF_SERVICE", comment: "")
            }
            else if segue.identifier == "PrivacySegue" {
                webViewController.url = VaavudInteractions.privacyUrl()
                webViewController.title = NSLocalizedString("LINK_PRIVACY_POLICY", comment: "")
            }
            else if segue.identifier == "BuyWindmeterSegue" {
                webViewController.url = VaavudInteractions.buySleipnirUrl(source: "settings")
                webViewController.title = NSLocalizedString("SETTINGS_SHOP_LINK", comment: "")
            }
        }
        else if let firstTimeViewController = segue.destinationViewController as? FirstTimeFlowController {
            firstTimeViewController.returnViaDismiss = true
        }
//        else if let modal = segue.destinationViewController as? CalibrateSleipnirViewController {
//            println("REMOVE TABBAR")
//            tabBarController?.tabBar.hidden = true
//        }
    }
}

class WebViewController: UIViewController {
    @IBOutlet weak var webView: UIWebView!
    var baseUrl = NSURL(string: "http://vaavud.com")
    var html: String?
    var url: NSURL?
    
    override func viewDidLoad() {
        load()
    }
    
    func load() {
        if let url = url {
            webView.loadRequest(NSURLRequest(URL: url))
        }
        else if let html = html {
            webView.loadHTMLString(html, baseURL: baseUrl)
        }
    }
}

extension String {
    func html() -> String {
        return "<html><head><style type='text/css'>a {color:#00aeef;text-decoration:none}\n" +
            "body {background-color:#f8f8f8;}</style></head><body>" +
            "<center style='padding-top:20px;font-family:helvetica,arial'>" +
            stringByReplacingOccurrencesOfString("\n" , withString: "<br/><br/>", options: nil) + "</center></body></html>"
    }
}





