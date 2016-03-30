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

let sleipnirFromCallbackAttempts = 10

class TabBarController: UITabBarController,UITabBarControllerDelegate {
    
    private let button = UIButton(type: .Custom)
    private var laidOutWidth: CGFloat?
    private var sleipnirFromCallbackAttemptsLeft = sleipnirFromCallbackAttempts
    var tabToSelect = 1
    let firebase = Firebase(url: firebaseUrl)
    private let logHelper = LogHelper(.Free)

    
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: Selector("receiveNotification:"),
            name: "PushNotification",
            object: nil)
    }
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        let preferences = NSUserDefaults.standardUserDefaults()
        let notificationViewShown = preferences.boolForKey("firstTimeNotifications")
        
        if !notificationViewShown {
            preferences.setValue(true, forKey: "firstTimeNotifications")
            preferences.synchronize()
            
            if let whatsNewViewController = storyboard?.instantiateViewControllerWithIdentifier("whatsNewViewController") {
                presentViewController(whatsNewViewController, animated: true, completion: nil)
            }
        }
        
        firebase.childByAppendingPaths("user", firebase.authData.uid,"activity").observeSingleEventOfType(.Value, withBlock: { snapshot in
            LogHelper.setUserProperty("Activity",value: snapshot.value as? String ?? "unknown")
        })
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        button.bounds.size.width = 70
        button.bounds.size.height = tabBar.bounds.height
        button.setImage(UIImage(named: "MeasureButton"), forState: .Normal)
        tabBar.addSubview(button)
        selectedIndex = tabToSelect
        
        tabBar.tintColor = .vaavudBlueColor()
        delegate = self
        
        
        
        
//        [[NSNotificationCenter defaultCenter] addObserver:self
//            selector:@selector(receiveNotification:)
//        name:@"PushNotification"
//        object:nil];
//    
    
//        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
//        CGRect frame = self.tabBar.bounds;
//        frame.size.width = 70;
//        button.frame = frame;
//        button.layer.zPosition = 100;
//        [button setImage:[UIImage imageNamed:@"MeasureButton"] forState:UIControlStateNormal];
//        
//        [self.tabBar addSubview:button];
//        
//        self.interactions = [VaavudInteractions new];
//        self.measureButton = button;
//        
//        self.delegate = self;
//        
//        [self setSelectedIndex:1];
//        
//        self.tabBar.tintColor = [UIColor vaavudBlueColor];
//        
//        NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"GuideView" owner:self options:nil];
//        self.calloutGuideView = [topLevelObjects objectAtIndex:0];
//        self.calloutGuideView.frame = CGRectMake(0, 0, CALLOUT_GUIDE_VIEW_WIDTH, [self.calloutGuideView preferredHeight]);
//        self.calloutGuideView.backgroundColor = [UIColor clearColor];
//        self.calloutGuideView.headingLabel.textColor = [UIColor darkGrayColor];
//        self.calloutGuideView.explanationLabel.textColor = [UIColor darkGrayColor];
//        self.calloutGuideView.topSpaceConstraint.constant = 10.0;
//        self.calloutGuideView.headingLabelWidthConstraint.constant = CALLOUT_GUIDE_VIEW_WIDTH - 20.0;
//        self.calloutGuideView.explanationLabelWidthConstraint.constant = CALLOUT_GUIDE_VIEW_WIDTH - 20.0;
//        self.calloutGuideView.labelVerticalSpaceConstraint.constant = 5.0;
//        
//        UITapGestureRecognizer *calloutGuideViewTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(guideViewTap:)];
//        [self.calloutGuideView addGestureRecognizer:calloutGuideViewTapRecognizer];
//        
//        self.isCalloutGuideViewShown = NO;
//        
//        self.calloutView = [SMCalloutView new];
//        self.calloutView.delegate = self;
//        self.calloutView.presentAnimation = SMCalloutAnimationStretch;
//        self.calloutView.translatesAutoresizingMaskIntoConstraints = YES;
//        self.calloutView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
//        
//        for (UITabBarItem *item in self.tabBar.items) {
//            item.imageInsets = UIEdgeInsetsMake(6.0, 0.0, -6.0, 0.0);
//        }
        
        for item in tabBar.items! {
            item.imageInsets = UIEdgeInsetsMake(6.0, 0.0, -6.0, 0.0);
        }
    }
    
    func receiveNotification(notification: NSNotification) {
        if notification.name == "PushNotification" {
            print("Push Notification in TabBar")
            
            if selectedIndex == 1 {
                return
            }
            
            if let tabArray = tabBar.items {
                if let count = tabArray[1].badgeValue {
                    tabArray[1].badgeValue = "\(Int(count)! + 1)"
                }
                else{
                    tabArray[1].badgeValue = "1"
                }
            }
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
        
        let deviceSettings = firebase.childByAppendingPaths("device", AuthorizationController.shared.deviceId, "setting")
        deviceSettings.observeSingleEventOfType(.Value, withBlock: parseSnapshot { dict in
            if dict["usesSleipnir"] as? Bool == true && !VaavudSDK.shared.sleipnirAvailable() {
                if fromUrlScheme && self.sleipnirFromCallbackAttemptsLeft > 0 {
                    self.sleipnirFromCallbackAttemptsLeft -= 1
                    NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: "takeMeasurementFromUrlScheme", userInfo: nil, repeats: false)
                    return
                }
                
                VaavudInteractions().showLocalAlert("SLEIPNIR_PROBLEM_TITLE", messageKey: "SLEIPNIR_PROBLEM_MESSAGE", cancelKey: "BUTTON_OK", otherKey: "SLEIPNIR_PROBLEM_SWITCH", action: {
                    deviceSettings.childByAppendingPath("usesSleipnir").setValue(false)
                    self.performSegueWithIdentifier("ShowMeasureScreen", sender: self)
                    }, on: self)
            }
            else {
                self.performSegueWithIdentifier("ShowMeasureScreen", sender: self)
            }
            self.sleipnirFromCallbackAttemptsLeft = sleipnirFromCallbackAttempts
            })
    }
}
