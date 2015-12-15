//
//  MeasureRootViewController.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 30/05/15.
//  Copyright (c) 2015 Andreas Okholm. All rights reserved.
//

import UIKit
import CoreMotion
import VaavudSDK
import Mixpanel
import Firebase

let updatePeriod = 1.0
let countdownInterval = 3
let limitedInterval = 30

enum WindMeterModel: Int {
    case Unknown = 0
    case Mjolnir = 1
    case Sleipnir = 2
}

protocol MeasurementConsumer {
    func tick()
    
    func newWindDirection(windDirection: CGFloat)
    func newSpeed(speed: CGFloat)
    func newHeading(heading: CGFloat)
    
    func newTemperature(temperature: CGFloat)
    
    func changedSpeedUnit(unit: SpeedUnit)
    func useMjolnir()
    
    func toggleVariant()
    
    var name: String { get }
}

class MeasureRootViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, WindMeasurementControllerDelegate, DBRestClientDelegate {
    private var pageController: UIPageViewController!
    private var viewControllers: [UIViewController]!
    private var displayLink: CADisplayLink!

    private var vcsNames: [String]!
    private let geocoder = CLGeocoder()
    
    private var altimeter: CMAltimeter?
        
    private var mjolnir: MjolnirMeasurementController?
    
    private let currentSessionUuid = UUIDUtil.generateUUID()
    
    private var currentSession: MeasurementSession? {
        return MeasurementSession.MR_findFirstByAttribute("uuid", withValue: currentSessionUuid)
    }
    
    let isSleipnirSession: Bool

    @IBOutlet weak var pager: UIPageControl!
    
    @IBOutlet weak var logoView: UIImageView!
    
    @IBOutlet weak var unitButton: UIButton!
    @IBOutlet weak var variantButton: UIButton!
    @IBOutlet weak var cancelButton: MeasureCancelButton!
    
    @IBOutlet weak var errorMessageLabel: UILabel!
    
    @IBOutlet weak var errorOverlayBackground: UIView!
    
    var currentConsumer: MeasurementConsumer?
    var screenUsage = [Double]()
    
    private var latestHeading: CGFloat?
    private var latestWindDirection: CGFloat?
    private var latestSpeed: CGFloat = 0

    private var maxSpeed: CGFloat = 0
    
//    private var avgSpeed: CGFloat { return 10 } // fixme: revert
    private var avgSpeed: CGFloat { return speedsSum/CGFloat(speedsCount) }
    private var speedsSum: CGFloat = 0
    private var speedsCount = 0
    
    private var elapsedSinceUpdate = 0.0
    
    private var logHelper = LogHelper(.Measure)
    
    var state: MeasureState = .Done
    var timeLeft = CGFloat(countdownInterval)
    
    let vaavudFirebase = Firebase(url: "https://vaavud-core-demo.firebaseio.com/")
    
    required init?(coder aDecoder: NSCoder) {
        isSleipnirSession = VaavudSDK.shared.sleipnirAvailable()
        
        super.init(coder: aDecoder)
        
        state = .CountingDown(countdownInterval, Property.getAsBoolean(KEY_MEASUREMENT_TIME_UNLIMITED))
        
        let wantsSleipnir = Property.getAsBoolean(KEY_USES_SLEIPNIR)
        
        if isSleipnirSession && !wantsSleipnir {
            NSNotificationCenter.defaultCenter().postNotificationName(KEY_WINDMETERMODEL_CHANGED, object: self)
        }
        
        if isSleipnirSession {
            Property.setAsBoolean(true, forKey: KEY_USES_SLEIPNIR)
            VaavudSDK.shared.windSpeedCallback = newWindSpeed
            VaavudSDK.shared.windDirectionCallback = newWindDirection
            VaavudSDK.shared.headingCallback = newHeading
            // fixme: handle
            do {
                try VaavudSDK.shared.start()
            }
            catch {
                dismissViewControllerAnimated(true) {
                    print("Failed to start SDK and dismissed Measure screen")
                }
                return
            }
        }
        else {
            let mjolnirController = MjolnirMeasurementController()
            mjolnirController.start()
            mjolnir = mjolnirController
        }
        
        if let sessions = MeasurementSession.MR_findByAttribute("measuring", withValue: true) as? [MeasurementSession] {
            _ = sessions.map { $0.measuring = false }
        }
        
        NSManagedObjectContext.MR_defaultContext().MR_saveToPersistentStoreWithCompletion(nil)
        
        if CMAltimeter.isRelativeAltitudeAvailable() {
            altimeter = CMAltimeter()
        }
        
        LocationManager.sharedInstance().start()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        hideVolumeHUD()
        
        let (old, flat, round) = ("OldMeasureViewController", "FlatMeasureViewController", "RoundMeasureViewController")
        vcsNames = isSleipnirSession ? [old, flat, round] : [old, flat]
        viewControllers = vcsNames.map { self.storyboard!.instantiateViewControllerWithIdentifier($0) }
        screenUsage = Array(count: vcsNames.count, repeatedValue: 0)

        if !isSleipnirSession { _ = viewControllers.map { ($0 as! MeasurementConsumer).useMjolnir() } }
        
        pager.numberOfPages = viewControllers.count
        
        let desiredScreen = Property.getAsString(KEY_DEFAULT_SCREEN) ?? flat
        let screenToShow = vcsNames.indexOf(desiredScreen) ?? 0

        pager.currentPage = screenToShow

        let mc = viewControllers[screenToShow] as! MeasurementConsumer

        currentConsumer = mc
        updateVariantButton(mc)
        
        pageController = storyboard?.instantiateViewControllerWithIdentifier("PageViewController") as? UIPageViewController
        pageController.dataSource = self
        pageController.delegate = self
        pageController.view.frame = view.bounds
        pageController.setViewControllers([viewControllers[screenToShow]], direction: .Forward, animated: false, completion: nil)
        
        addChildViewController(pageController)
        view.addSubview(pageController.view)
        pageController.didMoveToParentViewController(self)
        
        view.bringSubviewToFront(pager)
        view.bringSubviewToFront(unitButton)
        view.bringSubviewToFront(variantButton)
        view.bringSubviewToFront(errorOverlayBackground)
        view.bringSubviewToFront(cancelButton)
        
        variantButton.imageView?.contentMode = .ScaleAspectFit
        
        cancelButton.setup()
        
        displayLink = CADisplayLink(target: self, selector: Selector("tick:"))
        displayLink.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
        
        unitButton.setTitle(VaavudFormatter.shared.windSpeedUnit.localizedString, forState: .Normal)
        
        if Property.isMixpanelEnabled() {
            Mixpanel.sharedInstance().track("Measure Screen")
        }
        
        if let mjolnir = mjolnir {
            mjolnir.delegate = self
        }
    }
    
    func postUnitChange(unitType: String) {
        LogHelper.log(event: "Changed-Unit", properties: ["place" : "measure", "type" : unitType])
    }
    
    @IBAction func pressedVariant(sender: UILongPressGestureRecognizer) {
        let image = UIImage(named: "News12Logo")
        variantButton.setImage(image, forState: .Normal)
        variantButton.setImage(image, forState: .Highlighted)
    }
    
    @IBAction func tappedVariant(sender: UIButton) {
        currentConsumer?.toggleVariant()
    }

    @IBAction func tappedUnit(sender: UIButton) {
        VaavudFormatter.shared.windSpeedUnit = VaavudFormatter.shared.windSpeedUnit.next
        unitButton.setTitle(VaavudFormatter.shared.windSpeedUnit.localizedString, forState: .Normal)
        currentConsumer?.changedSpeedUnit(VaavudFormatter.shared.windSpeedUnit)
        postUnitChange("speed")
    }
    
    @IBAction func tappedCancel(sender: MeasureCancelButton) {
        if let vc = pageController.viewControllers?.last, mc = vc as? MeasurementConsumer {
            Property.setAsString(mc.name, forKey: KEY_DEFAULT_SCREEN)
        }
        
        switch state {
        case .CountingDown:
            stop(true)
        case .Limited:
            save(true)
            stop(true)
            mixpanelSend("Cancelled")
            logStop("cancelled")
        case .Unlimited:
            save(false)
            stop(false)
            mixpanelSend("Stopped")
            logStop("stopped")
        case .Done:
            break
        }
    }
    
    func tick(link: CADisplayLink) {
        currentConsumer?.tick()
        
        if state.running {
            speedsCount++
            speedsSum += latestSpeed
            elapsedSinceUpdate += link.duration
            screenUsage[pager.currentPage] += link.duration
        
            if elapsedSinceUpdate > updatePeriod {
                elapsedSinceUpdate = 0
                updateSession()
            }
        }
        
        switch state {
        case let .CountingDown(_, unlimited):
            if timeLeft < 0 {
                if unlimited {
                    state = .Unlimited
                }
                else {
                    state = .Limited(limitedInterval)
                    timeLeft = CGFloat(limitedInterval)
                }
                start()
            }
            else {
                timeLeft -= CGFloat(link.duration)
            }
        case .Limited:
            if timeLeft < 0 {
                timeLeft = 0
                state = .Done
                save(false)
                stop(false)
                mixpanelSend("Ended")
                logStop("ended")
            }
            else {
                timeLeft -= CGFloat(link.duration)
            }
        case .Unlimited:
            timeLeft = 0
        case .Done:
            break
        }
        
        cancelButton.update(timeLeft, state: state)
    }

    func hasValidLocation(session: Session) -> CLLocationCoordinate2D? {
        if let latlon = session.location {
            let loc = CLLocationCoordinate2D(latitude: latlon.lat, longitude: latlon.lon)
            if LocationManager.isCoordinateValid(loc) {
                return loc
            }
        }
        
        return nil
    }
    
    func updateWithLocation(session: Session) {
        //if session.managedObjectContext == nil || session.deleted { return }
        
        let loc = LocationManager.sharedInstance().latestLocation
        
        if LocationManager.isCoordinateValid(loc) {
            
            let l = [
                "lat" : loc.latitude,
                "lon" : loc.longitude
            ]
            
            vaavudFirebase.childByAppendingPath("session").childByAppendingPath(session.key).childByAppendingPath("location").updateChildValues(l)
            
            let latlong = CLLocation(latitude: loc.latitude, longitude: loc.longitude)
            
            updateWithGeocode(latlong,sessionKey: session.key!)
            updateWithSourcedData(latlong,sessionKey: session.key!)
            
//            (session.latitude, session.longitude) = (loc.latitude, loc.longitude)
//            
//            NSManagedObjectContext.MR_defaultContext().MR_saveToPersistentStoreWithCompletion { s, e in
//                if s {
//                    let userInfo = ["objectID" : session.objectID, "latitude" : true, "longitude" : true]
//                    NSNotificationCenter.defaultCenter().postNotificationName(KEY_SESSION_UPDATED, object: self, userInfo: userInfo)
//                }
//            }

        }
    }
    
    func updateWithGeocode(latlon: CLLocation, sessionKey: String) {
        geocoder.reverseGeocodeLocation(latlon) { placemarks, error in
            //if session.managedObjectContext == nil || session.deleted { return }

            if error == nil {
                if let first = placemarks?.first {
                    
                    let nameLocation = ["name" : first.thoroughfare ?? first.locality ?? first.country ?? "unknown"]
                    self.vaavudFirebase
                        .childByAppendingPath("session")
                        .childByAppendingPath(sessionKey)
                        .childByAppendingPath("location")
                        .updateChildValues(nameLocation)
                    
//                    session.geoLocationNameLocalized = first.thoroughfare ?? first.locality ?? first.country
//                    NSManagedObjectContext.MR_defaultContext().MR_saveToPersistentStoreWithCompletion { s, e in
//                        if s {
//                            let userInfo = ["objectID" : session.objectID, "geoLocationNameLocalized" : true]
//                            NSNotificationCenter.defaultCenter().postNotificationName(KEY_SESSION_UPDATED, object: self, userInfo: userInfo)
//                        }
//                    }
                }
            }
            else {
                print("Geocode failed with error: \(error)")
            }
        }
        
    }

    func updateWithWindchill(session: MeasurementSession) {
        if session.managedObjectContext == nil || session.deleted { return }

        if let kelvin = session.sourcedTemperature, ms = session.windSpeedAvg ?? session.sourcedWindSpeedAvg, chill = windchill(kelvin.floatValue, ms.floatValue) {
            session.windChill = chill
            NSManagedObjectContext.MR_defaultContext().MR_saveToPersistentStoreWithCompletion { s, e in
                if s {
                    let userInfo = ["objectID" : session.objectID, "windChill" : true]
                    NSNotificationCenter.defaultCenter().postNotificationName(KEY_SESSION_UPDATED, object: self, userInfo: userInfo)
                }
            }
        }
    }
    
    func updateWithSourcedData(latlon: CLLocation, sessionKey: String) {
//        let loc = hasValidLocation(latlon) ?? LocationManager.sharedInstance().latestLocation
        
        ForecastLoader.shared.requestFullForecast(latlon.coordinate) { sourced in
            print(sourced.dict())
            self.vaavudFirebase
                .childByAppendingPath("session")
                .childByAppendingPath(sessionKey)
                .childByAppendingPath("sourced")
                .updateChildValues(sourced.dict())
        }
        
        
        //["humidity": 0.83, "icon": clear-day, "pressure": 1019.9, "temperature": 40.12, "windMean": 5.6, "windDirection": 348]
        
        
        
        
        
        
            //self.currentConsumer?.newTemperature(CGFloat(t))
            
            
//            session.sourcedTemperature = t
//            session.sourcedPressureGroundLevel = p
//            session.sourcedWindDirection = d
//            
//            NSManagedObjectContext.MR_defaultContext().MR_saveToPersistentStoreWithCompletion { s, e in
//                if s {
//                    let userInfo = ["objectID" : session.objectID, "sourcedTemperature" : true, "sourcedPressureGroundLevel" : true, "sourcedWindDirection" : d != nil]
//                    NSNotificationCenter.defaultCenter().postNotificationName(KEY_SESSION_UPDATED, object: self, userInfo: userInfo)
//                }
//            }
        //}
    }
    
    func updateWithPressure(session: MeasurementSession) {
        altimeter?.startRelativeAltitudeUpdatesToQueue(NSOperationQueue.mainQueue()) {
            altitudeData, error in
            if let kpa = altitudeData?.pressure.doubleValue {
                self.altimeter?.stopRelativeAltitudeUpdates()

                if session.managedObjectContext == nil || session.deleted { return }
                session.pressure = 10*kpa

                NSManagedObjectContext.MR_defaultContext().MR_saveToPersistentStoreWithCompletion { s, e in
                    if s {
                        let userInfo = ["objectId" : session.objectID, "pressure" : true]
                        NSNotificationCenter.defaultCenter().postNotificationName(KEY_SESSION_UPDATED, object: self, userInfo: userInfo)
                    }
                }
            }
        }
    }
    
    func changedValidity(isValid: Bool, dynamicsIsValid: Bool) {
        if !isValid {
            currentConsumer?.newSpeed(0)
        }
        
        UIView.animateWithDuration(0.2) {
            self.errorOverlayBackground.alpha = dynamicsIsValid ? 0 : 1
        }
    }
    
    var mainSession : Session?
    
    func start() {
        elapsedSinceUpdate = 0
        
        //let model: WindMeterModel = isSleipnirSession ? .Sleipnir : .Mjolnir
        let model = isSleipnirSession ? "sleipnir" : "mjolnir"
        
        var session = Session(uid: vaavudFirebase.authData.uid, deviceId: AuthorizationController.shared.currentDeviceId(), timeStart: NSDate().timeIntervalSince1970, windMeter: model)
        print(session.initDict())
        
        let ref = vaavudFirebase.childByAppendingPath("session")
        let post = ref.childByAutoId()
        post.setValue(session.initDict())
        let sessionKey = post.key
        
        session.key = sessionKey
        print(sessionKey)
        
        mainSession = session
        
//        let session = MeasurementSession.MR_createEntity()!
//        session.uuid = currentSessionUuid
//        session.device = Property.getAsString(KEY_DEVICE_UUID)
//        session.windMeter = model.rawValue
//        session.startTime = NSDate()
//        session.timezoneOffset = NSTimeZone.localTimeZone().secondsFromGMTForDate(session.startTime)
//        session.endTime = session.startTime
//        session.measuring = true
//        session.uploaded = false
//        session.startIndex = 0
//        session.privacy = 1
//        
        updateWithLocation(session)
//        updateWithGeocode(session)
//        updateWithSourcedData(session)
//        updateWithPressure(session)
//        
//        logHelper.began(["time-limit" : state.timed ?? 0, "device" : isSleipnirSession ? "Sleipnir" : "Mjolnir"])
//        
//        mixpanelSend("Started")
    }
    
    func updateSession() {
        
        
        let now = NSDate().timeIntervalSince1970 * 1000
//        if let mjolnir = mjolnir where !mjolnir.isValidCurrentStatus {
//            return // fixme: uncomment
//        }
        
        
        if let session = mainSession {
            var wind = Wind(speed: Float(latestSpeed), time: now)
            
            var sessionNewInforamtion = [
                "windMean" : Float(avgSpeed),
                "windMax" :  Float(maxSpeed)
            ]
            
            
            if isSleipnirSession, let dir = latestWindDirection {
                let modDirection = Float(mod(dir, 360))
                wind.direction = modDirection
                sessionNewInforamtion["windDirection"] = modDirection
            }
            
            
            mainSession?.wind.append(wind)
            
            vaavudFirebase.childByAppendingPath("wind").childByAppendingPath(session.key).childByAppendingPath(session.wind.count.description).setValue(wind.fireDict())
            vaavudFirebase.childByAppendingPath("session").childByAppendingPath(session.key).updateChildValues(sessionNewInforamtion)
            
        }
        else{
            print("ROOT: updateSession - ERROR: No current session")

        }
        
        
        
//        let now = NSDate()
//        if let mjolnir = mjolnir where !mjolnir.isValidCurrentStatus {
//            return // fixme: uncomment
//        }
//        
//        if let session = currentSession where session.measuring.boolValue {
//            session.endTime = now
//            session.windSpeedMax = maxSpeed
//            session.windSpeedAvg = avgSpeed
//            
//            let point = MeasurementPoint.MR_createEntity()!
//            point.session = session
//            point.time = now
//            point.windSpeed = latestSpeed
//
//            if isSleipnirSession, let dir = latestWindDirection {
//                let modDirection = mod(dir, 360)
//                point.windDirection = modDirection
//                session.windDirection = modDirection
//            }
//        }
//        else {
//            print("ROOT: updateSession - ERROR: No current session")
//            // Stopped by model, stop?
//        }
    }
    
    func save(userCancelled: Bool) {
        guard !userCancelled && avgSpeed > 0 else {
            return
        }

        guard var session = mainSession else {
            return
        }
        
        session.timeEnd =  Float(NSDate().timeIntervalSince1970 * 1000)
        session.windMax = Float(maxSpeed)
        session.windMean = Float(avgSpeed)
        
        if isSleipnirSession, let dir = latestWindDirection {
            session.windDirection = Float(mod(dir, 360))
        }
        
        
        let windspeeds = speeds(session)
        
        if windspeeds.count > 5 { session.turbulence = gustiness(windspeeds) }
        
        
        print(session)
        
//        session.measuring = false
//        session.endTime = NSDate()
//        session.windSpeedMax = maxSpeed
//        session.windSpeedAvg = avgSpeed
//        if isSleipnirSession, let dir = latestWindDirection {
//            session.windDirection = mod(dir, 360)
//        }
//        
//        let windspeeds = speeds(session)
//        
//        if windspeeds.count > 5 { session.gustiness = gustiness(windspeeds) }
//        
//        updateWithWindchill(session)
//        
//        NSManagedObjectContext.MR_defaultContext().MR_saveToPersistentStoreWithCompletion {
//            success, error in
//            ServerUploadManager.sharedInstance().triggerUpload()
//            
//            //                if success {
//            //                    print("ROOT: save - Saved and uploaded after measuring ============================")
//            //                }
//            //                else if error != nil {
//            //                    print("ROOT: save - Failed to save session after measuring with error: \(error.localizedDescription)")
//            //                }
//            //                else {
//            //                    print("ROOT: save - Failed to save session after measuring with no error message")
//            //                }
//        }
//        
//        if DBSession.sharedSession().isLinked(), let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
//            appDelegate.uploadToDropbox(session)
//        }
    }
    
    func stop(userCancelled: Bool) {
        let cancel = userCancelled || avgSpeed == 0 || state.countingDown
        
        if isSleipnirSession {
            VaavudSDK.shared.stop()
        }
        else if let mjolnir = mjolnir {
            mjolnir.stop()
        }
//
//        altimeter?.stopRelativeAltitudeUpdates()
//        
        reportToUrlSchemeCaller(cancel)
//        
//        displayLink.invalidate()
//        currentConsumer = nil
//        
//        if cancel {
//            if let session = currentSession {
//                session.MR_deleteEntity()
//            }
//
//            dismissViewControllerAnimated(true) {
//                self.pageController.view.removeFromSuperview()
//                self.pageController.removeFromParentViewController()
//                _ = self.viewControllers.map { $0.view.removeFromSuperview() }
//                _ = self.viewControllers.map { $0.removeFromParentViewController() }
//                self.viewControllers = []
//            }
//        }
//        else {
//            let session = currentSession!
//            
//            if session.geoLocationNameLocalized == nil {
//                updateWithLocation(session)
//                if hasValidLocation(session) != nil {
//                    updateWithGeocode(session)
//                }
//            }
//            
//            let summary = storyboard!.instantiateViewControllerWithIdentifier("SummaryViewController") as! CoreSummaryViewController
//            //summary.session = session
//            
//            pageController.dataSource = nil
//            pageController.setViewControllers([summary], direction: .Forward, animated: true, completion: nil)
//            
//            LogHelper.increaseUserProperty("Measurement-Count")
//            
//            UIView.animateWithDuration(0.2) {
//                self.unitButton.alpha = 0
//                self.variantButton.alpha = 0
//                self.cancelButton.alpha = 0
//                self.pager.alpha = 0
//                self.errorOverlayBackground.alpha = 0
//            }
//        }
    }
    
    func logStop(manner: String) {
        var props: [String : AnyObject] = ["manner" : manner]
        
        for (index, key) in vcsNames.enumerate() {
            props[key] = screenUsage[index]
        }
        logHelper.ended(props)
    }
    
    func mixpanelSend(action: String) {
        if !Property.isMixpanelEnabled() { return }
        
        MixpanelUtil.updateMeasurementProperties(false)
        
        let model = isSleipnirSession ? "Sleipnir" : "Mjolnir"
        var properties: [NSObject : AnyObject] = ["Action" : action, "Wind Meter" : model]
        
        let event: String
        
        if action == "Started" {
            event = "Start Measurement"
        }
        else {
            event = "Stop Measurement"
            
            if let start = currentSession?.startTime, duration = currentSession?.endTime?.timeIntervalSinceDate(start) {
                properties["Duration"] = duration
            }
            
            properties["Avg Wind Speed"] = currentSession?.windSpeedAvg?.floatValue
            properties["Max Wind Speed"] = currentSession?.windSpeedMax?.floatValue
            properties["Measure Screen Type"] = currentConsumer?.name
        }
        
        Mixpanel.sharedInstance().track(event, properties: properties)
    }

    func reportToUrlSchemeCaller(cancelled: Bool) {
        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate,
            x = appDelegate.xCallbackSuccess,
            encoded = x.stringByAddingPercentEncodingWithAllowedCharacters(.URLQueryAllowedCharacterSet()) {
                appDelegate.xCallbackSuccess = nil
                
                if cancelled, let url = NSURL(string:encoded + "?x-source=Vaavud&x-cancelled=cancel") {
                    UIApplication.sharedApplication().openURL(url)
                }
                else if let url = NSURL(string:encoded + "?x-source=Vaavud&windSpeedAvg=\(avgSpeed)&windSpeedMax=\(maxSpeed)") {
                    UIApplication.sharedApplication().openURL(url)
                }
                LogHelper.log(.URLScheme, event: "Returned", properties: ["success" : !cancelled])
        }
    }

    // MARK: Mjolnir Callback
    
    func addSpeedMeasurement(currentSpeed: NSNumber!, avgSpeed: NSNumber!, maxSpeed: NSNumber!) {
        newWindSpeed(WindSpeedEvent(time: NSDate(), speed: currentSpeed.doubleValue))
    }
    
    // MARK: SDK Callbacks
    
    func newWindDirection(event: WindDirectionEvent) {
        print("######## NEW DIRECTION: \(latestWindDirection == nil ? "FIRST" : "not first")")
        
        let direction = CGFloat(event.globalDirection)
        latestWindDirection = direction
        currentConsumer?.newWindDirection(direction)
    }
    
    func newWindSpeed(event: WindSpeedEvent) {
        latestSpeed = CGFloat(event.speed)
        currentConsumer?.newSpeed(latestSpeed)
        if latestSpeed > maxSpeed { maxSpeed = latestSpeed }
    }
    
    func newHeading(event: HeadingEvent) {
        if timeLeft > 20 || timeLeft < 5 {
            print("Heading NOT sent \(timeLeft)")

            return
        }

        print("Heading sent \(timeLeft)")
        
        let heading = CGFloat(event.heading)
        latestHeading = heading
        currentConsumer?.newHeading(heading)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
       return [.Portrait, .PortraitUpsideDown]
    }
    
    func changeConsumer(mc: MeasurementConsumer) {
        mc.newSpeed(latestSpeed)
        mc.changedSpeedUnit(VaavudFormatter.shared.windSpeedUnit)
        if isSleipnirSession, let wd = latestWindDirection, h = latestHeading {
            mc.newWindDirection(wd)
            mc.newHeading(h)
        }
        currentConsumer = mc
    }
    
    func pageViewController(pageViewController: UIPageViewController, willTransitionToViewControllers pendingViewControllers: [UIViewController]) {
        if let mc = pendingViewControllers.last as? MeasurementConsumer {
            changeConsumer(mc)
            
            UIView.animateWithDuration(0.2) {
                self.updateVariantButton(mc)
            }
        }
    }
    
    func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if let vc = pageViewController.viewControllers?.last, mc = vc as? MeasurementConsumer {
            if let current = viewControllers.indexOf(vc) {
                pager.currentPage = current
                let currentName = vcsNames[current]
                logHelper.log("Swiped", properties: ["destination" : currentName])
                LogHelper.increaseUserProperty("Use-" + currentName)
            }
            changeConsumer(mc)
            
            UIView.animateWithDuration(0.2) {
                self.updateVariantButton(mc)
            }
        }
    }
    
    func updateVariantButton(mc: MeasurementConsumer) {
        self.variantButton.alpha = mc is FlatMeasureViewController ? 1 : 0
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        if let current = viewControllers.indexOf(viewController) {
            let next = mod(current + 1, viewControllers.count)
            return viewControllers[next]
        }
        
        return nil
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {

        if let current = viewControllers.indexOf(viewController) {
            let previous = mod(current - 1, viewControllers.count)
            return viewControllers[previous]
        }
        
        return nil
    }
    
    // MARK: Debug
    
    @IBAction func debugPanned(sender: UIPanGestureRecognizer) {
//        let y = sender.locationInView(view).y
//        let x = view.bounds.midX - sender.locationInView(view).x
        let dx = sender.translationInView(view).x/2
        let dy = sender.translationInView(view).y/20
        
        if let direction = latestWindDirection {
            let newDirection = direction + dx
            latestWindDirection = newDirection
            currentConsumer?.newWindDirection(newDirection)
        }
        newWindSpeed(WindSpeedEvent(time: NSDate(), speed: max(0, Double(latestSpeed - dy))))
        
        sender.setTranslation(CGPoint(), inView: view)
    }
}

func speeds(session: Session) -> [Float] {
    var speeds = [Float]()
    
    for p in session.wind {
        if p.speed > 0 {
            speeds.append(p.speed)
        }
    }

    return speeds
}

func windchill(kelvin: Float, _ windspeed: Float) -> Float? {
    let celsius = kelvin - 273.15
    let kmh = windspeed*3.6
    
    if celsius > 10 || kmh < 4.8 {
        return nil
    }

    let k: Float = 13.12
    let a: Float = 0.6215
    let b: Float = -11.37
    let c: Float = 0.3965
    let d: Float = 0.16

    return 273.15 + k + a*celsius + b*pow(kmh, d) + c*celsius*pow(kmh, d)
}

func gustiness(speeds: [Float]) -> Float {
    let n = Float(speeds.count)
    let mean = speeds.reduce(0, combine: +)/n
    let variance = speeds.reduce(0) { $0 + ($1 - mean)*($1 - mean) }/(n - 1)
    
    return variance/mean
}

