//
//  CoreSettingsViewController.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 11/02/15.
//  Copyright (c) 2015 Andreas Okholm. All rights reserved.
//

import Foundation
import Firebase

// fixme: move to common file
func parseSnapshot(callback: [String : AnyObject] -> ()) -> FDataSnapshot! -> () {
    return { snap in
        if let dict = snap.value as? [String : AnyObject] {
            callback(dict)
        }
        else {
            callback([snap.key : snap.value])
        }
    }
}

func parseSnapshot<T>(key: String, callback: T? -> ()) -> FDataSnapshot! -> () {
    return parseSnapshot { dict in
        callback(dict[key] as? T)
    }
}

class CoreSettingsTableViewController: UITableViewController {
    let interactions = VaavudInteractions()
    
    @IBOutlet weak var limitControl: UISegmentedControl!
    
    @IBOutlet weak var logoutButton: UIBarButtonItem!
    @IBOutlet weak var meterTypeControl: UISegmentedControl!
    
    @IBOutlet weak var speedUnitControl: UISegmentedControl!
    @IBOutlet weak var directionUnitControl: UISegmentedControl!
    @IBOutlet weak var pressureUnitControl: UISegmentedControl!
    @IBOutlet weak var temperatureUnitControl: UISegmentedControl!

    @IBOutlet weak var dropboxControl: UISwitch!
    @IBOutlet weak var sleipnirClipControl: UISegmentedControl!
    
    @IBOutlet weak var sleipnirClipCell: UITableViewCell!
    
    @IBOutlet weak var sleipnirClipView: UIView!
    
    @IBOutlet weak var versionLabel: UILabel!
    
    private let logHelper = LogHelper(.Settings, counters: "scrolled")
    
    private lazy var deviceSettings = { return Firebase(url: firebaseUrl).childByAppendingPaths("device", AuthorizationController.shared.deviceId, "setting") }()

    private var deviceHandle: UInt!
    
    private var formatterHandle: String!
    
    override func viewDidLoad() {
        hideVolumeHUD()
        
        versionLabel.text = NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as? String

        dropboxControl.on = DBSession.sharedSession().isLinked()

//        // fixme: actually use notifications
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "dropboxLinkedStatus:", name: "dropboxIsLinked", object: nil)

        formatterHandle = VaavudFormatter.shared.observeUnitChange { [unowned self] in self.refreshUnits() }
        refreshUnits()
        
        deviceHandle = deviceSettings.observeEventType(.Value, withBlock: parseSnapshot { [unowned self] in self.refreshDeviceSettings($0) })
    }
    
    func refreshDeviceSettings(dict: [String : AnyObject]) {
        _ = (dict["usesSleipnir"] as? Bool).map(refreshWindmeterModel)
        _ = (dict["sleipnirClipSideScreen"] as? Bool).map(refreshSleipnirClipSide)
        _ = (dict["measuringTime"] as? Int).map(refreshTimeLimit)
    }
    
    deinit {
        VaavudFormatter.shared.stopObserving(formatterHandle)
        deviceSettings.removeObserverWithHandle(deviceHandle)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    @IBAction func logoutTapped(sender: UIBarButtonItem) {
        interactions.showLocalAlert("REGISTER_BUTTON_LOGOUT",
            messageKey: "DIALOG_CONFIRM",
            cancelKey: "BUTTON_CANCEL",
            otherKey: "BUTTON_OK",
            action: { [unowned self] in self.doLogout() },
            on: self)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        logHelper.began()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        logHelper.ended()
    }
    
    func refreshUnits() {
        speedUnitControl.selectedSegmentIndex = VaavudFormatter.shared.speedUnit.index
        directionUnitControl.selectedSegmentIndex = VaavudFormatter.shared.directionUnit.index
        temperatureUnitControl.selectedSegmentIndex = VaavudFormatter.shared.temperatureUnit.index
        pressureUnitControl.selectedSegmentIndex = VaavudFormatter.shared.pressureUnit.index
    }
    
    func refreshWindmeterModel(usesSleipnir: Bool) {
        meterTypeControl.selectedSegmentIndex = usesSleipnir ? 1 : 0
        
        UIView.animateWithDuration(0.2) {
            self.sleipnirClipView.alpha = usesSleipnir ? 1 : 0
        }
        
        LogHelper.setUserProperty("Device", value: usesSleipnir ? "Sleipnir" : "Mjolnir")
    }

    func refreshSleipnirClipSide(front: Bool) {
        sleipnirClipControl.selectedSegmentIndex = front ? 1 : 0
        LogHelper.setUserProperty("Sleipnir-Clip-Frontside", value: front)
    }
    
    func refreshTimeLimit(timeLimit: Int) {
        LogHelper.setUserProperty("Measurement-Limit", value: timeLimit)
        limitControl.selectedSegmentIndex = timeLimit == 0 ? 1 : 0
    }
    
    func dropboxLinkedStatus(note: NSNotification) {
        if let isDropboxLinked = note.object as? NSNumber.BooleanLiteralType {
            dropboxControl.on = isDropboxLinked
            // fixme: do we track dropbox? Do we want to? Yes gustf we want :) we are artist
        }
    }
    
    func logUnitChange(unitType: String) {
        LogHelper.log(event: "Changed-Unit", properties: ["place" : "settings", "type" : unitType])
        logHelper.increase()
    }
    
    // MARK: User actions
    
    let limitedInterval = 30 // fixme: where to put this? Follow your heart it will tell you.
    
    @IBAction func changedLimitToggle(sender: UISegmentedControl) {
        deviceSettings.childByAppendingPath("measuringTime").setValue(sender.selectedSegmentIndex == 1 ? 0 : limitedInterval)
        logHelper.increase()
    }

    @IBAction func changedSpeedUnit(sender: UISegmentedControl) {
        VaavudFormatter.shared.speedUnit = SpeedUnit(index: sender.selectedSegmentIndex)
        logUnitChange("speed")
    }
    
    @IBAction func changedDirectionUnit(sender: UISegmentedControl) {
        VaavudFormatter.shared.directionUnit = DirectionUnit(index: sender.selectedSegmentIndex)
        logUnitChange("direction")
    }
    
    @IBAction func changedPressureUnit(sender: UISegmentedControl) {
        VaavudFormatter.shared.pressureUnit = PressureUnit(index: sender.selectedSegmentIndex)
        logUnitChange("pressure")
    }
    
    @IBAction func changedTemperatureUnit(sender: UISegmentedControl) {
        VaavudFormatter.shared.temperatureUnit = TemperatureUnit(index: sender.selectedSegmentIndex)
        logUnitChange("temperature")
    }
    
    @IBAction func changedDropboxSetting(sender: UISwitch) {
        let action: String
        if sender.on {
            DBSession.sharedSession().linkFromController(self)
            action = "TryToLink"
        }
        else {
            DBSession.sharedSession().unlinkAll()
            action = "Unlinked"
        }
        logHelper.increase()
        logHelper.log("Dropbox", properties: ["Action" : action])
        // fixme: track ok?
    }

    @IBAction func changedMeterModel(sender: UISegmentedControl) {
        deviceSettings.childByAppendingPath("usesSleipnir").setValue(sender.selectedSegmentIndex == 1)
        logHelper.increase()
    }

    @IBAction func changedSleipnirPlacement(sender: UISegmentedControl) {
        deviceSettings.childByAppendingPath("sleipnirClipSideScreen").setValue(sender.selectedSegmentIndex == 1)
        logHelper.increase()
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
                webViewController.url = VaavudInteractions.buySleipnirUrl("settings")
                webViewController.title = NSLocalizedString("SETTINGS_SHOP_LINK", comment: "")
                LogHelper.log(event: "Pressed-Buy", properties: ["place" : "settings"])
            }
        }
        logHelper.increase()
    }
    
    // MARK: Convenience
    
    func doLogout() {
        LogHelper.log(event: "Logged-Out", properties: ["place" : "settings"])
        
        AuthorizationController.shared.unauth()
        FBSDKLoginManager().logOut()
        
//        UIApplication.sharedApplication().unregisterForRemoteNotifications()
        gotoLoginFrom(tabBarController!, inside: view.window!.rootViewController!)
    }
}

class WebViewController: UIViewController {
    @IBOutlet weak var webView: UIWebView!
    var baseUrl = NSURL(string: "http://vaavud.com")
    var html: String?
    var url: NSURL?
    
    override func viewDidLoad() {
        webView.backgroundColor = .whiteColor()
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
            stringByReplacingOccurrencesOfString("\n" , withString: "<br/><br/>", options: []) + "</center></body></html>"
    }
}
