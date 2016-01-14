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
import Firebase

//public class VaavudLegacySDK: NSObject {
//    public static let shared = VaavudLegacySDK()
//
//    public var windSpeedCallback: (Double -> Void)?
//    public var windDirectionCallback: (Double -> Void)?
//
//    private override init() {
//        super.init()
//
//        VaavudSDK.shared.windSpeedCallback = { self.windSpeedCallback?($0.speed) }
//        VaavudSDK.shared.windDirectionCallback = { self.windDirectionCallback?($0.direction) }
//    }
//}

extension Firebase {
    func childByAppendingPaths(paths: String...) -> Firebase! {
        return paths.reduce(self) { f, p in f.childByAppendingPath(p) }
    }
}

let updatePeriod = 1.0
let countdownInterval = 3

enum WindMeterModel: String {
    case Mjolnir = "mjolnir"
    case Sleipnir = "sleipnir"
}

protocol MeasurementConsumer {
    func tick()
    
    func newWindDirection(windDirection: CGFloat)
    func newSpeed(speed: CGFloat)
    func newSpeedMax(max: CGFloat)
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
    
    private let model: WindMeterModel!
    
    @IBOutlet weak var pager: UIPageControl!
    
    @IBOutlet weak var logoView: UIImageView!
    
    @IBOutlet weak var unitButton: UIButton!
    @IBOutlet weak var variantButton: UIButton!
    @IBOutlet weak var cancelButton: MeasureCancelButton!
    
    @IBOutlet weak var errorMessageLabel: UILabel!
    
    @IBOutlet weak var errorOverlayBackground: UIView!
    
    private var currentConsumer: MeasurementConsumer?
    private var screenUsage = [Double]()
    
    private var latestHeading: HeadingEvent?

    private var latestWindDirection: WindDirectionEvent?
    private var latestWindSpeed = WindSpeedEvent(speed: 0)
    
    private var elapsedSinceUpdate: Double = 0
    private var windSpeedsSaved = 0
    
//    private var maxSpeed: Double = 0
//    private var avgSpeed: Double { return speedsSum/Double(speedsCount) }
//    private var speedsSum: Double = 0
//    private var speedsCount = 0
    
    private var logHelper = LogHelper(.Measure)

    private var session: Session!

    private var state: MeasureState = .Done
    private var timeLeft = CGFloat(countdownInterval)
    
    let firebase = Firebase(url: firebaseUrl)
    var deviceSettings: Firebase { return firebase.childByAppendingPaths("device", AuthorizationController.shared.deviceId, "setting") }
    
    // MARK - Lifetime methods
    
    required init?(coder aDecoder: NSCoder) {
        model = VaavudSDK.shared.sleipnirAvailable() ? .Sleipnir : .Mjolnir
        
        super.init(coder: aDecoder)
        
        VaavudSDK.shared.windSpeedCallback = newWindSpeed
        
        if model == .Sleipnir {
            deviceSettings.childByAppendingPath("usesSleipnir").setValue(true)
            
            VaavudSDK.shared.windDirectionCallback = newWindDirection
            VaavudSDK.shared.headingCallback = newHeading
            VaavudSDK.shared.locationCallback = newLocation
            VaavudSDK.shared.velocityCallback = newVelocity
        }
        
        if CMAltimeter.isRelativeAltitudeAvailable() {
            self.altimeter = CMAltimeter()
        }
        
        LocationManager.sharedInstance().start()
    }
    
    deinit {
        print("Deinit Root")
        altimeter?.stopRelativeAltitudeUpdates()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        hideVolumeHUD()
        cancelButton.setup()

        // fixme: check?
        updateUnitButton()

        variantButton.imageView?.contentMode = .ScaleAspectFit
        
        displayLink = CADisplayLink(target: self, selector: Selector("tick:"))
        displayLink.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
        
        let (old, flat, round) = ("OldMeasureViewController", "FlatMeasureViewController", "RoundMeasureViewController")
        vcsNames = model == .Sleipnir ? [old, flat, round] : [old, flat]
        viewControllers = vcsNames.map { self.storyboard!.instantiateViewControllerWithIdentifier($0) }
        screenUsage = Array(count: vcsNames.count, repeatedValue: 0)
        
        if model == .Mjolnir { _ = viewControllers.map { ($0 as! MeasurementConsumer).useMjolnir() } }
        
        pager.numberOfPages = viewControllers.count
        
        // Move back?
        pageController = storyboard?.instantiateViewControllerWithIdentifier("PageViewController") as? UIPageViewController
        pageController.dataSource = self
        pageController.delegate = self
        pageController.view.frame = view.bounds

        addChildViewController(pageController)
        view.addSubview(pageController.view)
        pageController.didMoveToParentViewController(self)
        
        view.bringSubviewToFront(pager)
        view.bringSubviewToFront(unitButton)
        view.bringSubviewToFront(variantButton)
        view.bringSubviewToFront(errorOverlayBackground)
        view.bringSubviewToFront(cancelButton)

        let start = NSDate()

        deviceSettings.observeSingleEventOfType(.Value, withBlock: parseSnapshot { dict in
            let flipped = dict["sleipnirClipSideScreen"] as? Bool ?? false
            let measuringTime = dict["measuringTime"] as? Int ?? 0
            let desiredScreen = dict["defaultMeasurementScreen"] as? String
            
            self.state = .CountingDown(countdownInterval, measuringTime)
            
            print("Start: delay: \(NSDate().timeIntervalSinceDate(start)), flipped: \(flipped), time: \(measuringTime)")
            
            if self.model == .Sleipnir {
                self.startSleipnir(flipped)
            }
            else {
                self.startMjolnir()
            }
            
            self.showScreen(desiredScreen)
            })
    }
    
    // MARK - Overrides
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return [.Portrait, .PortraitUpsideDown]
    }
    
    // MARK - Main

    func start() {
        let deviceId = AuthorizationController.shared.currentDeviceId()
        let post = firebase.childByAppendingPath("session").childByAutoId()

        session = Session(uid: firebase.authData.uid, key: post.key, deviceId: deviceId, timeStart: NSDate(), windMeter: model)
        post.setValue(session.fireDict)
        
        //        updateWithLocation(post.key)
        //        updateWithGeocode(session)
        //        updateWithSourcedData(session)
        //        updateWithPressure(session)
        
        logHelper.began(["time-limit" : state.timed ?? 0, "device" : model.rawValue.capitalizedString])
        elapsedSinceUpdate = 0

        //        mixpanelSend("Started")
    }

    func tick(link: CADisplayLink) {
        currentConsumer?.tick()
        
        if state.running {
//            speedsCount++
//            speedsSum += latestWindSpeed.speed
            screenUsage[pager.currentPage] += link.duration
            elapsedSinceUpdate += link.duration

            if elapsedSinceUpdate > updatePeriod {
                updateSession()
                elapsedSinceUpdate = 0
            }
        }
        
        switch state {
        case let .CountingDown(_, measuringTime):
            if timeLeft < 0 {
                if measuringTime == 0 {
                    state = .Unlimited
                }
                else {
                    state = .Limited(measuringTime)
                    timeLeft = CGFloat(measuringTime)
                }
                start()
            }
            else {
                timeLeft -= CGFloat(link.duration)
            }
        case .Limited:
            if timeLeft < 0 {
                timeLeft = 0
                save(false)
                stop(false)
                state = .Done
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
    
    func updateSession() {
//        if mjolnir?.isValidCurrentStatus == false {
//            return // fixme: uncomment
//        }

        session.windMean = Float(VaavudSDK.shared.session.meanSpeed)
        session.windMax = Float(VaavudSDK.shared.session.maxSpeed)
        session.windDirection = VaavudSDK.shared.session.windDirections.last.map { Float(mod($0.direction, 360)) }
        
        print("Updating: [mean : \(session.windMean)] (\(session.key))")
        
        firebase
            .childByAppendingPaths("session", session.key)
            .setValue(session.fireDict)

        firebase
            .childByAppendingPaths("wind", session.key, String(windSpeedsSaved))
            .setValue(latestWindSpeed.fireDict)
        firebase
            .childByAppendingPaths("windDirection", session.key, String(windSpeedsSaved))
            .setValue(latestWindDirection?.fireDict)
        windSpeedsSaved += 1
    }

    func save(userCancelled: Bool) {
        guard !state.countingDown && !userCancelled && session.windMean > 0 else {
            return
        }
        
        session.timeEnd = NSDate()
        session.turbulence = VaavudSDK.shared.session.turbulence.map(Float.init)
        
        print("Saving: (\(session.key)) \(session.fireDict)")
        
        firebase
            .childByAppendingPaths("session", session.key)
            .setValue(session.fireDict)
        
        let post = firebase
            .childByAppendingPaths("sessionComplete", "queue", "tasks")
            .childByAutoId()
        
        post.setValue(["sessionKey" : session.key])
        let queue = post.key

        print("Queue: \(queue)")
        print("Session: \(session)")
        
        //        updateWithWindchill(session)

        //        if DBSession.sharedSession().isLinked(), let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
        //            appDelegate.uploadToDropbox(session)
        //        }
    }
    
    func stop(userCancelled: Bool) {
            let cancel = userCancelled || session.windMean == 0 || state.countingDown
            
            if model == .Sleipnir {
                VaavudSDK.shared.stop()
            }
            else {
                mjolnir?.stop()
            }
            
            reportToUrlSchemeCaller(cancel)
            
            displayLink.invalidate()
            currentConsumer = nil
        
        if cancel {
            if state.running {
                firebase.childByAppendingPaths("session", session.key).removeValue()
                firebase.childByAppendingPaths("sessionDeleted", session.key).setValue(session.fireDict)
            }
            
            dismissViewControllerAnimated(true) {
                self.pageController.view.removeFromSuperview()
                self.pageController.removeFromParentViewController()
                _ = self.viewControllers.map { $0.view.removeFromSuperview() }
                _ = self.viewControllers.map { $0.removeFromParentViewController() }
                self.viewControllers = []
            }
        }
        else {
            //                    if session.geoLocationNameLocalized == nil {
            //                        updateWithLocation(session)
            //                        if hasValidLocation(session) != nil {
            //                            updateWithGeocode(session)
            //                        }
            //                    }
            
            let summary = storyboard!.instantiateViewControllerWithIdentifier("SummaryViewController") as! SummaryViewController
            summary.session = session
            
            pageController.dataSource = nil
            pageController.setViewControllers([summary], direction: .Forward, animated: true, completion: nil)
            
            LogHelper.increaseUserProperty("Measurement-Count")
            
            UIView.animateWithDuration(0.2) {
                self.unitButton.alpha = 0
                self.variantButton.alpha = 0
                self.cancelButton.alpha = 0
                self.pager.alpha = 0
                self.errorOverlayBackground.alpha = 0
            }
        }
    }
    
    func reportToUrlSchemeCaller(cancelled: Bool) {
        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate,
            x = appDelegate.xCallbackSuccess,
            encoded = x.stringByAddingPercentEncodingWithAllowedCharacters(.URLQueryAllowedCharacterSet()) {
                appDelegate.xCallbackSuccess = nil
                
                if cancelled, let url = NSURL(string:encoded + "?x-source=Vaavud&x-cancelled=cancel") {
                    UIApplication.sharedApplication().openURL(url)
                }
                else if let url = NSURL(string:encoded + "?x-source=Vaavud&windSpeedAvg=\(session.windMean)&windSpeedMax=\(session.windMax)") {
                    UIApplication.sharedApplication().openURL(url)
                }
                LogHelper.log(.URLScheme, event: "Returned", properties: ["success" : !cancelled])
        }
    }

    // MARK - Updating Session
    
    func saveLocation(sessionKey: String) {
        let loc = LocationManager.sharedInstance().latestLocation
        
        if LocationManager.isCoordinateValid(loc) {
            let locationDictDelta = ["lat" : loc.latitude, "lon" : loc.longitude]
            
            firebase
                .childByAppendingPaths("session", sessionKey, "location")
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
                .childByAppendingPaths("session", sessionKey, "location", "name")
                .setValue(name)
            
            // fixme: summary may need to be updated
        }
    }
    
//    func saveWindchill(sessionKey: String) {
        //        if let kelvin = session.sourcedTemperature, ms = session.windSpeedAvg ?? session.sourcedWindSpeedAvg, chill = windchill(kelvin.floatValue, ms.floatValue) {
        //            session.windChill = chill
        //            // fixme: summary may need to be updated
        //        }
//    }
    
    func updateWithSourcedData(location: CLLocation, sessionKey: String) {
//        let loc = hasValidLocation(latlon) ?? LocationManager.sharedInstance().latestLocation
        
        ForecastLoader.shared.requestFullForecast(location.coordinate) { sourced in
            print(sourced.fireDict)
            self.firebase
                .childByAppendingPaths("session", sessionKey, "sourced")
                .updateChildValues(sourced.fireDict)
        }
        
        //["humidity": 0.8, "icon": clear-night, "pressure": 1020000, "temperature": 279.4333, "windMean": 1.86, "windDirection": 340]
        
            //self.currentConsumer?.newTemperature(CGFloat(t))
        
        //            // fixme: summary may need to be updated
    }
    
    func updateWithPressure(sessionKey: String) {
        altimeter?.startRelativeAltitudeUpdatesToQueue(NSOperationQueue.mainQueue()) {
            altitudeData, error in
            if let kpa = altitudeData?.pressure.doubleValue {
                self.altimeter?.stopRelativeAltitudeUpdates()
                
                
                let pressureModel = ["temperature" : 10*kpa]
                
//                self.vaavudFirebase
//                    .childByAppendingPath("session")
//                    .childByAppendingPath(sessionKey)
//                    .updateChildValues(pressureModel)
//                

//                if session.managedObjectContext == nil || session.deleted { return }
//                session.pressure = 10*kpa

                // fixme: summary may need to be updated
                // fixme: send to firebase
            }
        }
    }
    
    // MARK: Mjolnir Delegate
    
    func changedValidity(isValid: Bool, dynamicsIsValid: Bool) {
        if !isValid {
            currentConsumer?.newSpeed(0)
        }
        
        UIView.animateWithDuration(0.2) {
            self.errorOverlayBackground.alpha = dynamicsIsValid ? 0 : 1
        }
    }
    
    func addSpeedMeasurement(currentSpeed: NSNumber!, avgSpeed: NSNumber!, maxSpeed: NSNumber!) {
        VaavudSDK.shared.newWindSpeed(WindSpeedEvent(time: NSDate(), speed: currentSpeed.doubleValue))
    }
    
    // MARK: SDK Delegate
    
    func newWindDirection(event: WindDirectionEvent) {
        // Save on session and Firebase
        latestWindDirection = event
        currentConsumer?.newWindDirection(CGFloat(event.direction))
    }
    
    func newWindSpeed(event: WindSpeedEvent) {
        latestWindSpeed = event
        currentConsumer?.newSpeed(CGFloat(event.speed))
        guard let session = session else { return }
        currentConsumer?.newSpeedMax(CGFloat(session.windMax))
    }
    
    func newTrueWindDirection(event: WindDirectionEvent) {
        print("newTrueWindDirection \(event)")
    }
    
    func newTrueWindSpeed(event: WindSpeedEvent) {
        print("newTrueWindSpeed \(event)")
    }
    
    func newHeading(event: HeadingEvent) {
        latestHeading = event
        let heading = CGFloat(event.heading)
        currentConsumer?.newHeading(heading)
    }
    
    func newLocation(event: LocationEvent) {
    }

    func newVelocity(event: VelocityEvent) {
    }
    
    // Mark - Page View Controller Delegate

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
    
    // Mark - User action
    
    @IBAction func pressedVariant(sender: UILongPressGestureRecognizer) {
        let image = UIImage(named: "News12Logo")
        variantButton.setImage(image, forState: .Normal)
        variantButton.setImage(image, forState: .Highlighted)
    }
    
    @IBAction func tappedVariant(sender: UIButton) {
        currentConsumer?.toggleVariant()
    }
    
    @IBAction func tappedUnit(sender: UIButton) {
        // fixme
        VaavudFormatter.shared.speedUnit = VaavudFormatter.shared.speedUnit.next
        updateUnitButton()
        currentConsumer?.changedSpeedUnit(VaavudFormatter.shared.speedUnit)
        LogHelper.log(event: "Changed-Unit", properties: ["place" : "measure", "type" : "speed"])
    }
    
    @IBAction func tappedCancel(sender: MeasureCancelButton) {
        if let vc = pageController.viewControllers?.last, mc = vc as? MeasurementConsumer {
            firebase
                .childByAppendingPaths("device", AuthorizationController.shared.deviceId, "setting", "defaultMeasurementScreen")
                .setValue(mc.name)
        }
        
        switch state {
        case .CountingDown:
            stop(true)
        case .Limited:
            save(true)
            stop(true)
            logStop("cancelled")
        case .Unlimited:
            save(false)
            stop(false)
            logStop("stopped")
        case .Done:
            break
        }
        
        state = .Done
    }
    
    // Mark - Updates
    
    private func updateVariantButton(mc: MeasurementConsumer) {
        variantButton.alpha = mc is FlatMeasureViewController ? 1 : 0
    }
    
    private func updateUnitButton() {
        unitButton.setTitle(VaavudFormatter.shared.speedUnit.localizedString, forState: .Normal)
    }
    
    // Mark - Convenience
    
    private func hasValidLocation(session: Session) -> CLLocationCoordinate2D? {
        if let location = session.location {
            let loc = CLLocationCoordinate2D(latitude: location.lat, longitude: location.lon)
            if LocationManager.isCoordinateValid(loc) {
                return loc
            }
        }
        
        return nil
    }
    
    private func logStop(manner: String) {
        var props: [String : AnyObject] = ["manner" : manner]
        
        for (index, key) in vcsNames.enumerate() {
            props[key] = screenUsage[index]
        }
        logHelper.ended(props)
    }

    private func changeConsumer(mc: MeasurementConsumer) {
        mc.newSpeed(CGFloat(latestWindSpeed.speed))
        mc.changedSpeedUnit(VaavudFormatter.shared.speedUnit) // fixme: test
        if model == .Sleipnir, let wd = latestWindDirection?.direction, h = latestHeading?.heading {
            mc.newWindDirection(CGFloat(wd))
            mc.newHeading(CGFloat(h))
        }
        currentConsumer = mc
    }

    private func startSleipnir(flipped: Bool) {
        // fixme: handle error
        do {
            try VaavudSDK.shared.start(flipped ?? false)  // fixme: handle flipped in sdk
        }
        catch {
            self.dismissViewControllerAnimated(true) {
                print("Failed to start SDK and dismissed Measure screen")
            }
            return
        }
    }
    
    private func startMjolnir() {
        let mjolnirController = MjolnirMeasurementController()
        mjolnirController.start()
        mjolnirController.delegate = self
        
        mjolnir = mjolnirController
    }
    
    private func showScreen(name: String?) {
        let screenToShow = name.flatMap(vcsNames.indexOf) ?? 0
        
        //        let screenToShow = vcsNames.indexOf(name) ?? 0
        
        pager.currentPage = screenToShow
        
        let mc = viewControllers[screenToShow] as! MeasurementConsumer
        
        currentConsumer = mc
        updateVariantButton(mc)
        
        //        pageController = storyboard?.instantiateViewControllerWithIdentifier("PageViewController") as? UIPageViewController
        //        pageController.dataSource = self
        //        pageController.delegate = self
        //        pageController.view.frame = view.bounds
        pageController.setViewControllers([viewControllers[screenToShow]], direction: .Forward, animated: false, completion: nil)
        
        //        addChildViewController(pageController)
        //        view.addSubview(pageController.view)
        //        pageController.didMoveToParentViewController(self)
        //
        //        view.bringSubviewToFront(pager)
        //        view.bringSubviewToFront(unitButton)
        //        view.bringSubviewToFront(variantButton)
        //        view.bringSubviewToFront(errorOverlayBackground)
        //        view.bringSubviewToFront(cancelButton)
    }
    
    // MARK: Debug
    
    @IBAction func debugPanned(sender: UIPanGestureRecognizer) {
//        let y = sender.locationInView(view).y
//        let x = view.bounds.midX - sender.locationInView(view).x
//        let dx = Double(sender.translationInView(view).x/2)
        let dy = Double(sender.translationInView(view).y/20)
        
//        if let event = latestWindDirection {
//            let newDirection = event.direction + dx
//            latestWindDirection = WindDirectionEvent(time: event.time, direction: newDirection)
//            currentConsumer?.newWindDirection(CGFloat(newDirection))
//        }
        
        let event = WindSpeedEvent(time: NSDate(), speed: max(0, latestWindSpeed.speed - dy))
        
        VaavudSDK.shared.newWindSpeed(event)
        
        sender.setTranslation(CGPoint(), inView: view)
    }
}

func windchill(kelvin: Float?, _ windspeed: Float?) -> Float? {
    guard let kelvin = kelvin, windspeed = windspeed else {
        return nil
    }
    
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


