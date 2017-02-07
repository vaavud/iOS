//
//  TabBarController.swift
//  Vaavud
//
//  Created by Diego R on 12/11/15.
//  Copyright © 2015 Andreas Okholm. All rights reserved.
//

import UIKit
import Firebase
import VaavudSDK
import Palau


extension PalauDefaults {
    /// a NSUserDefaults Entry of Type String with the key "backingName"
    public static var time: PalauDefaultsEntry<Int> {
        get { return value("time") }
        set { }
    }
    
    public static var windSpeed: PalauDefaultsEntry<Int> {
        get { return value("windSpeed") }
        set { }
    }
    
    public static var direction: PalauDefaultsEntry<Int> {
        get { return value("direction") }
        set { }
    }
    
    public static var pressure: PalauDefaultsEntry<Int> {
        get { return value("pressure") }
        set { }
    }
    
    public static var temperature: PalauDefaultsEntry<Int> {
        get { return value("temperature") }
        set { }
    }
    
    public static var dropbox: PalauDefaultsEntry<Int> {
        get { return value("dropbox") }
        set { }
    }
    
    public static var windMeterModel: PalauDefaultsEntry<Int> {
        get { return value("windMeterModel") }
        set { }
    }
    
    public static var placement: PalauDefaultsEntry<Int> {
        get { return value("placement") }
        set { }
    }
}


let sleipnirFromCallbackAttempts = 10

class TabBarController: UITabBarController,UITabBarControllerDelegate {
    
    private let button = UIButton(type: .Custom)
    private var laidOutWidth: CGFloat?
    private var sleipnirFromCallbackAttemptsLeft = sleipnirFromCallbackAttempts
    var tabToSelect = 1
    let firebase = FIRDatabase.database().reference()
    private let logHelper = LogHelper(.Free)

    
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        
        guard let _ = PalauDefaults.direction.value else {
            PalauDefaults.time.value = 0
            PalauDefaults.direction.value = 0
            PalauDefaults.windSpeed.value = 0
            PalauDefaults.pressure.value = 0
            PalauDefaults.temperature.value = 0
            PalauDefaults.dropbox.value = 0
            PalauDefaults.windMeterModel.value = 0
            PalauDefaults.placement.value = 0
            return
        }
    }
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
//        let preferences = NSUserDefaults.standardUserDefaults()
//        let notificationViewShown = preferences.boolForKey("firstTimeNotifications")
//        
//        if !notificationViewShown {
//            preferences.setValue(true, forKey: "firstTimeNotifications")
//            preferences.synchronize()
//            
//            if let whatsNewViewController = storyboard?.instantiateViewControllerWithIdentifier("whatsNewViewController") {
//                presentViewController(whatsNewViewController, animated: true, completion: nil)
//            }
//        }
        
        
        if AuthorizationController.shared.isAuth {
            firebase.child("user").child(FIRAuth.auth()!.currentUser!.uid).child("activity").observeSingleEventOfType(.Value, withBlock: { snapshot in
                LogHelper.setUserProperty("Activity",value: snapshot.value as? String ?? "unknown")
            })
        }
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tabBar.shadowImage = nil
        tabBar.setValue(true, forKey: "_hidesShadow")
        
        
        button.bounds.size.width = 90
        button.bounds.size.height = 90
        button.setImage(UIImage(named: "NewMeasureButton"), forState: .Normal)
        
        tabBar.addSubview(button)
        selectedIndex = 0
        
        tabBar.tintColor = .vaavudBlueColor()
        
        delegate = self
        
        for item in tabBar.items! {
            item.imageInsets = UIEdgeInsetsMake(6.0, 0.0, -6.0, 0.0)
        }
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return [.Portrait, .PortraitUpsideDown]
    }
    
    override func viewWillLayoutSubviews() {
        let width = tabBar.bounds.width / CGFloat(tabBar.items!.count)
        let height = tabBar.bounds.height
        
        if width == laidOutWidth { return }
        
        tabBar.selectionIndicatorImage = UIImage.image(UIColor.vaavudTabbarSelectedColor(), size: CGSize(width: width, height: height))
        
        button.center = tabBar.bounds.center
        laidOutWidth = width
    }
    
    func tabBarController(tabBarController: UITabBarController, shouldSelectViewController viewController: UIViewController) -> Bool {
        if viewController == childViewControllers[2] {
            takeMeasurement(false)
            return false
        }
        
        return true
        
    }
    
    func takeMeasurementFromUrlScheme() {
        takeMeasurement(true)
    }
    
    func takeMeasurement(fromUrlScheme: Bool) {
        if let presented = presentedViewController {
            presented.dismissViewControllerAnimated(false, completion: nil)
        }
        
        if !VaavudSDK.shared.sleipnirAvailable() {
            VaavudInteractions().showLocalAlert("SLEIPNIR_PROBLEM_TITLE", messageKey: "SLEIPNIR_PROBLEM_MESSAGE", cancelKey: "BUTTON_OK", otherKey: "SLEIPNIR_PROBLEM_SWITCH", action: {
                self.performSegueWithIdentifier("ShowMeasureScreen", sender: self)
                }, on: self)
        }
        else{
            self.performSegueWithIdentifier("ShowMeasureScreen", sender: self)

        }

        
//        let deviceSettings = firebase.childByAppendingPaths("device", AuthorizationController.shared.deviceId, "setting")
//        deviceSettings.observeSingleEventOfType(.Value, withBlock: parseSnapshot { dict in
//            if dict["usesSleipnir"] as? Bool == true && !VaavudSDK.shared.sleipnirAvailable() {
//                if fromUrlScheme && self.sleipnirFromCallbackAttemptsLeft > 0 {
//                    self.sleipnirFromCallbackAttemptsLeft -= 1
//                    NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(TabBarController.takeMeasurementFromUrlScheme), userInfo: nil, repeats: false)
//                    return
//                }
//                
//                VaavudInteractions().showLocalAlert("SLEIPNIR_PROBLEM_TITLE", messageKey: "SLEIPNIR_PROBLEM_MESSAGE", cancelKey: "BUTTON_OK", otherKey: "SLEIPNIR_PROBLEM_SWITCH", action: {
//                    deviceSettings.childByAppendingPath("usesSleipnir").setValue(false)
//                    self.performSegueWithIdentifier("ShowMeasureScreen", sender: self)
//                    }, on: self)
//            }
//            else {
//                self.performSegueWithIdentifier("ShowMeasureScreen", sender: self)
//            }
//            self.sleipnirFromCallbackAttemptsLeft = sleipnirFromCallbackAttempts
//            })
    }
}
