//
//  CoreSettingsViewController.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 11/02/15.
//  Copyright (c) 2015 Andreas Okholm. All rights reserved.
//

import Foundation
import Mixpanel
import Firebase

// fixme: move to common file
func parseSnapshot(callback: [String : AnyObject] -> ()) -> FDataSnapshot! -> () {
    return { snap in
        if let dict = snap.value as? [String : AnyObject] {
            print("parseSnapshot dict: \(dict)")
            callback(dict)
        }
        else {
            print("parseSnapshot key/value: \([snap.key : snap.value])")
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

    private var handles = [UInt]()
    
    private var formatterHandle: String!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        print("init")
    }
    
    override func viewDidLoad() {
        hideVolumeHUD()
        
        versionLabel.text = NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as? String
        
        dropboxControl.on = DBSession.sharedSession().isLinked()
        
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "wasLoggedInOut:", name: KEY_DID_LOGINOUT, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "dropboxLinkedStatus:", name: KEY_IS_DROPBOXLINKED, object: nil)
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "modelChanged:", name: KEY_WINDMETERMODEL_CHANGED, object: nil)

        formatterHandle = VaavudFormatter.shared.observeUnitChange { [unowned self] in self.refreshUnits() }
        refreshUnits()

        handles.append(deviceSettings.observeEventType(.Value, withBlock: parseSnapshot(refreshDeviceSettings)))
        
//        let deviceId = AuthorizationController.shared.deviceId
//        let deviceSettings = firebase.childByAppendingPaths("device", deviceId, "setting")
//        deviceSettings.observeEventType(.ChildChanged, withBlock: { print("---device changed: #\($0)") })
        
//        deviceSettings.observeEventType(.Value, withBlock: { print("snappp change: \($0)") })
    }
    
    func refreshDeviceSettings(dict: [String : AnyObject]) {
        print("refreshDeviceSettings: \(dict)")
        
        let _ = (dict["usesSleipnir"] as? Bool).map(refreshWindmeterModel)
        let _ = (dict["sleipnirClipSideScreen"] as? Bool).map(refreshSleipnirClipSide)
    }
    
    deinit {
        VaavudFormatter.shared.stopObserving(formatterHandle)
        let _ = handles.map(deviceSettings.removeObserverWithHandle)
    }
    
    @IBAction func logoutTapped(sender: UIBarButtonItem) {
        interactions.showLocalAlert("REGISTER_BUTTON_LOGOUT",
            messageKey: "DIALOG_CONFIRM",
            cancelKey: "BUTTON_CANCEL",
            otherKey: "BUTTON_OK",
            action: { self.doLogout() },
            on: self)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
//        let sharedSettings = firebase.childByAppendingPaths("user", firebase.authData.uid, "setting", "shared")
//        handles.append(sharedSettings.observeEventType(.ChildChanged, withBlock: parseSnapshot(readUnits)))
        
//        refreshWindmeterModel()
//        refreshTimeLimit()
        
//        let iosSettings = firebase.childByAppendingPaths("user", firebase.authData.uid, "setting", "ios", "mapGuideMarkerShown")
//        iosSettings.setValue(Int(rand()))
//
//        let deviceId = AuthorizationController.shared.deviceId
//        let deviceSettings = firebase.childByAppendingPaths("device", deviceId, "setting")
//        deviceSettings.childByAppendingPath("usesSleipnir").setValue(Int(rand()))
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        logHelper.began()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        logHelper.ended()
    }
    
//    func modelChanged(note: NSNotification) {
//        refreshWindmeterModel()
//    }
    
    func refreshUnits() {
        print("Settings: Refresh units")
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
    
//    func unitsChanged(note: NSNotification) {
//        if note.object as? CoreSettingsTableViewController != self {
//            readUnits()
//        }
//    }
    
    func dropboxLinkedStatus(note: NSNotification) {
        if let isDropboxLinked = note.object as? NSNumber.BooleanLiteralType {
            dropboxControl.on = isDropboxLinked
//            let value = isDropboxLinked ? "Linking succeeded" : "Linking failed"
//            if Property.isMixpanelEnabled() {
//                Mixpanel.sharedInstance().track("Dropbox", properties: ["Action" : value])
//            }
        }
    }
    
    func logUnitChange(unitType: String) {
        LogHelper.log(event: "Changed-Unit", properties: ["place" : "settings", "type" : unitType])
        logHelper.increase()
    }
    
//    deinit {
//        NSNotificationCenter.defaultCenter().removeObserver(self)
//    }
    
    // MARK: User actions
    
    let limitedInterval = 30 // fixme: where to put this?
    
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
    
    @IBAction func changedDropboxSetting(sender: UISwitch) { // fixme
        let value: String
        if sender.on {
            DBSession.sharedSession().linkFromController(self)
            value = "Try link"
        }
        else {
            DBSession.sharedSession().unlinkAll()
            value = "Unlinked"
        }
        Mixpanel.sharedInstance().track("Dropbox", properties: ["Action" : value])
        logHelper.increase()
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
