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

extension Firebase {
    func childByAppendingPaths(paths: String...) -> Firebase! {
        return paths.reduce(self) { f, p in f.childByAppendingPath(p) }
    }
}

//extension Dictionary where Key 


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
    
    //    private var latestHeading: CGFloat?
    
    private var latestHeading: HeadingEvent?

    //    private var latestWindDirection: CGFloat?
    
    private var latestWindDirection: WindDirectionEvent?

    //    private var latestSpeed: CGFloat = 0

    private var sessionKey: String?
    private var latestWindSpeed = WindSpeedEvent(speed: 0)
    private var elapsedSinceUpdate: Double = 0
    private var windSpeedsSaved = 0
    
    private var maxSpeed: Double = 0
    private var avgSpeed: Double { return speedsSum/Double(speedsCount) }
    private var speedsSum: Double = 0
    private var speedsCount = 0
    
    private var logHelper = LogHelper(.Measure)
    
    var state: MeasureState = .Done
    var timeLeft = CGFloat(countdownInterval)
    
    let firebase = Firebase(url: firebaseUrl)
    
    required init?(coder aDecoder: NSCoder) {
        isSleipnirSession = VaavudSDK.shared.sleipnirAvailable()
        
        super.init(coder: aDecoder)
        
        state = .CountingDown(countdownInterval, Property.getAsBoolean(KEY_MEASUREMENT_TIME_UNLIMITED))
        
        let wantsSleipnir = Property.getAsBoolean(KEY_USES_SLEIPNIR)
        
        if isSleipnirSession && !wantsSleipnir {
            // fixme: change windmeter in session, don't use notifiaction
            NSNotificationCenter.defaultCenter().postNotificationName(KEY_WINDMETERMODEL_CHANGED, object: self)
        }
        
        if isSleipnirSession {
            Property.setAsBoolean(true, forKey: KEY_USES_SLEIPNIR)
            VaavudSDK.shared.windSpeedCallback = newWindSpeed
            VaavudSDK.shared.windDirectionCallback = newWindDirection
            VaavudSDK.shared.headingCallback = newHeading
            VaavudSDK.shared.locationCallback = newLocation
            VaavudSDK.shared.velocityCallback = newVelocity

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
            speedsSum += latestWindSpeed.speed
            screenUsage[pager.currentPage] += link.duration
        
            if elapsedSinceUpdate > updatePeriod {
                updateSession()
                elapsedSinceUpdate = 0
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
        if let location = session.location {
            let loc = CLLocationCoordinate2D(latitude: location.lat, longitude: location.lon)
            if LocationManager.isCoordinateValid(loc) {
                return loc
            }
        }
        
        return nil
    }
    
    func saveLocation(sessionKey: String) {
        let loc = LocationManager.sharedInstance().latestLocation
        
        if LocationManager.isCoordinateValid(loc) {
            let locationDictDelta = ["lat" : loc.latitude, "lon" : loc.longitude]
            
            firebase
                .childByAppendingPath("session")
                .childByAppendingPath(sessionKey)
                .childByAppendingPath("location")
                .updateChildValues(locationDictDelta)
            
            let latlong = CLLocation(latitude: loc.latitude, longitude: loc.longitude)
            
            updateWithGeocode(latlong, sessionKey: sessionKey)
            updateWithSourcedData(latlong, sessionKey: sessionKey)
        }
    }
    
    func updateWithGeocode(location: CLLocation, sessionKey: String) {
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("Geocode failed with error: \(error)")
                return
            }
            
            guard let first = placemarks?.first, name = first.thoroughfare ?? first.locality ?? first.country else {
                return
            }
            
            self.firebase
                .childByAppendingPath("session")
                .childByAppendingPath(sessionKey)
                .childByAppendingPath("location")
                .childByAppendingPath("name")
                .setValue(name)
            
            // fixme: summary may need to be updated
        }
    }
    
    func saveWindchill(sessionKey: String) {
        //        if let kelvin = session.sourcedTemperature, ms = session.windSpeedAvg ?? session.sourcedWindSpeedAvg, chill = windchill(kelvin.floatValue, ms.floatValue) {
        //            session.windChill = chill
        //            // fixme: summary may need to be updated
        //        }
    }
    
    func updateWithSourcedData(location: CLLocation, sessionKey: String) {
//        let loc = hasValidLocation(latlon) ?? LocationManager.sharedInstance().latestLocation
        
        ForecastLoader.shared.requestFullForecast(location.coordinate) { sourced in
            print(sourced.fireDict)
            self.firebase
                .childByAppendingPath("session")
                .childByAppendingPath(sessionKey)
                .childByAppendingPath("sourced")
                .updateChildValues(sourced.fireDict)
        }
        
        //["humidity": 0.8, "icon": clear-night, "pressure": 1020000, "temperature": 279.4333, "windMean": 1.86, "windDirection": 340]
        
            //self.currentConsumer?.newTemperature(CGFloat(t))
        
        //            // fixme: summary may need to be updated
    }
    
    func updateWithPressure(session: MeasurementSession) {
        altimeter?.startRelativeAltitudeUpdatesToQueue(NSOperationQueue.mainQueue()) {
            altitudeData, error in
            if let kpa = altitudeData?.pressure.doubleValue {
                self.altimeter?.stopRelativeAltitudeUpdates()

                if session.managedObjectContext == nil || session.deleted { return }
                session.pressure = 10*kpa

                // fixme: summary may need to be updated
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
    
    func start() {
        elapsedSinceUpdate = 0
        
        //let model: WindMeterModel = isSleipnirSession ? .Sleipnir : .Mjolnir
        let model = isSleipnirSession ? "sleipnir" : "mjolnir"
        
        let session = Session(uid: firebase.authData.uid, deviceId: AuthorizationController.shared.currentDeviceId(), timeStart: NSDate(), windMeter: model)
        print(session.initDict())
        
        let ref = firebase.childByAppendingPath("session")
        let post = ref.childByAutoId()
        post.setValue(session.initDict())
        sessionKey = post.key
        
        print(sessionKey)
        
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
//        updateWithLocation(post.key)
//        updateWithGeocode(session)
//        updateWithSourcedData(session)
//        updateWithPressure(session)
//        
//        logHelper.began(["time-limit" : state.timed ?? 0, "device" : isSleipnirSession ? "Sleipnir" : "Mjolnir"])
//        
//        mixpanelSend("Started")
    }
    
    func updateSession() {
//        if let mjolnir = mjolnir where !mjolnir.isValidCurrentStatus {
//            return // fixme: uncomment
        //        }
        
        if let sessionKey = sessionKey {
            firebase
                .childByAppendingPath("wind")
                .childByAppendingPath(sessionKey)
                .childByAppendingPath(String(windSpeedsSaved))
                .setValue(latestWindSpeed.fireDict)
            
            windSpeedsSaved += 1
            
            let session = firebase
                .childByAppendingPath("session")
                .childByAppendingPath(sessionKey)
            
            session.childByAppendingPath("windMean").setValue(avgSpeed)
            session.childByAppendingPath("windMax").setValue(maxSpeed)
            
            if isSleipnirSession, let dir = latestWindDirection?.direction {
                session.childByAppendingPath("windDirection").setValue(mod(dir, 360))
            }
        }
        else {
            print("ROOT: updateSession - ERROR: No current session")
        }
    }
    
    func save(userCancelled: Bool) {
        guard !userCancelled && avgSpeed > 0 else {
            return
        }
        
        guard let sessionKey = sessionKey else {
            return
        }
        
        var finalDict : FirebaseDictionary = [
            "timeEnd": NSDate().ms,
            "windMax": Float(maxSpeed),
            "windMean": Float(avgSpeed)
        ]
        
        if isSleipnirSession, let dir = latestWindDirection?.direction {
            finalDict["windDirection"] = mod(dir, 360)
        }
        
        //let windspeeds = speeds(session)
        
        //if windspeeds.count > 5 { session.turbulence = gustiness(windspeeds) }
        finalDict["turbulence"] = 0.29
        
        firebase
            .childByAppendingPath("session")
            .childByAppendingPath(sessionKey)
            .updateChildValues(finalDict)
        
        
        let post = firebase
            .childByAppendingPath("sessionComplete")
            .childByAppendingPath("queue")
            .childByAppendingPath("tasks")
            .childByAutoId()
        
        post.setValue(["sessionKey": sessionKey])
        let queue = post.key
        
        print(queue)
        
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
        var properties: [NSObject : AnyObject] = ["Action" : action, "Wind Meter" : model ]
        
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
        // Save on session and Firebase
        latestWindDirection = event
        currentConsumer?.newWindDirection(CGFloat(event.direction))
    }
    
    func newWindSpeed(event: WindSpeedEvent) {
        latestWindSpeed = event
        let latestSpeedValue = CGFloat(event.speed)
//        currentConsumer?.newSpeed(latestSpeed)
        currentConsumer?.newSpeed(latestSpeedValue)
    }
    
    func newHeading(event: HeadingEvent) {
        if timeLeft > 20 || timeLeft < 5 {
            print("Heading NOT sent \(timeLeft)")

            return
        }

        print("Heading sent \(timeLeft)")
        
        latestHeading = event
        let heading = CGFloat(event.heading)
        currentConsumer?.newHeading(heading)
    }
    
    func newLocation(event: LocationEvent) {
    }

    func newVelocity(event: VelocityEvent) {
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
       return [.Portrait, .PortraitUpsideDown]
    }
    
    func changeConsumer(mc: MeasurementConsumer) {
        mc.newSpeed(CGFloat(latestWindSpeed.speed))
        mc.changedSpeedUnit(VaavudFormatter.shared.windSpeedUnit)
        if isSleipnirSession, let wd = latestWindDirection?.direction, h = latestHeading?.heading {
            mc.newWindDirection(CGFloat(wd))
            mc.newHeading(CGFloat(h))
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
        let dx = Double(sender.translationInView(view).x/2)
        let dy = Double(sender.translationInView(view).y/20)
        
        if let event = latestWindDirection {
            let newDirection = event.direction + dx
            latestWindDirection = WindDirectionEvent(time: event.time, direction: newDirection)
            currentConsumer?.newWindDirection(CGFloat(newDirection))
        }
        newWindSpeed(WindSpeedEvent(time: NSDate(), speed: max(0, latestWindSpeed.speed - dy)))
        
        sender.setTranslation(CGPoint(), inView: view)
    }
}

//func speeds(session: Session) -> [Float] {
//    var speeds = [Float]()
//    
//    for p in session.wind {
//        if p.speed > 0 {
//            speeds.append(p.speed)
//        }
//    }
//
//    return speeds
//}

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

