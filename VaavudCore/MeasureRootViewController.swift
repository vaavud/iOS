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
    
    func useMjolnir()
    
    func newWindSpeedMax(max: Double)

    func newWindSpeed(speed: Double)
    func newTrueWindSpeed(speed: Double)
    
    func newWindDirection(windDirection: Double)
    func newTrueWindDirection(windDirection: Double)

    func newHeading(heading: Double)
    func newVelocity(course: Double, speed: Double)
    
    func newTemperature(temperature: Double)
    
    func changedSpeedUnit(unit: SpeedUnit)
    
    func toggleVariant()
    
    var name: String { get }
}

func makeNamedLocation(name: String?, event: LocationEvent) -> Location {
    return Location(lat: event.lat, lon: event.lon, name: name, altitude: event.altitude)
}

struct StreamTracker {
    var hasNewValue = false
    private var valuesSaved = 0
    mutating func newUploadIndex() -> String? {
        guard hasNewValue else { return nil }
        let result = String(valuesSaved)
        valuesSaved += 1
        hasNewValue = false
        return result
    }
}

class MeasureRootViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, WindMeasurementControllerDelegate, DBRestClientDelegate {
    private var pageController: UIPageViewController!
    private var viewControllers: [UIViewController]!
    private var displayLink: CADisplayLink!

    private var vcsNames: [String]!
    
    private var mjolnir: MjolnirMeasurementController?
    
    private let model: WindMeterModel = VaavudSDK.shared.sleipnirAvailable() ? .Sleipnir : .Mjolnir
    
    @IBOutlet weak var pager: UIPageControl!
    
    @IBOutlet weak var unitButton: UIButton!
    @IBOutlet weak var variantButton: UIButton!
    @IBOutlet weak var cancelButton: MeasureCancelButton!
    
    @IBOutlet weak var errorMessageLabel: UILabel!
    
    @IBOutlet weak var errorOverlayBackground: UIView!
    
    private var currentConsumer: MeasurementConsumer?
    private var screenUsage = [Double]()
    
    private var elapsedSinceUpdate: Double = 0
    
    private var logHelper = LogHelper(.Measure)

    private var session: Session!
    private var geoname: String?
    private var sourced: Sourced?
    
    private var windTracker = StreamTracker()
    private var windDirectionTracker = StreamTracker()
    private var locationTracker = StreamTracker()
    private var pressureTracker = StreamTracker()
    private var velocityTracker = StreamTracker()

    private var state: MeasureState = .Done
    private var timeLeft = CGFloat(countdownInterval)
    
    private let firebase = Firebase(url: firebaseUrl)
    private var deviceSettings: Firebase { return firebase.childByAppendingPaths("device", AuthorizationController.shared.deviceId, "setting") }
    
    // MARK - Lifetime methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        hideVolumeHUD()
        cancelButton.setup()
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

        deviceSettings.observeSingleEventOfType(.Value, withBlock: parseSnapshot { dict in
            let flipped = dict["sleipnirClipSideScreen"] as? Bool ?? false
            let measuringTime = dict["measuringTime"] as? Int ?? 0
            let desiredScreen = dict["defaultMeasurementScreen"] as? String
            
            self.state = .CountingDown(countdownInterval, measuringTime)
            
            VaavudSDK.shared.windSpeedCallback = self.newWindSpeed
            VaavudSDK.shared.locationCallback = self.newLocation
            VaavudSDK.shared.pressureCallback = self.newPressure
            VaavudSDK.shared.velocityCallback = self.newVelocity

            if self.model == .Sleipnir {
                VaavudSDK.shared.windDirectionCallback = self.newWindDirection
                VaavudSDK.shared.headingCallback = self.newHeading

                self.deviceSettings.childByAppendingPath("usesSleipnir").setValue(true)
                self.startSleipnir(flipped)
            }
            else {
                self.startMjolnir()
                _ = try? VaavudSDK.shared.startLocationAndPressureOnly()
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
        
        logHelper.began(["time-limit" : state.timed ?? 0, "device" : model.rawValue.capitalizedString])
        elapsedSinceUpdate = 0
    }

    func tick(link: CADisplayLink) {
        currentConsumer?.tick()
        
        if state.running {
            screenUsage[pager.currentPage] += link.duration
            elapsedSinceUpdate += link.duration

            if elapsedSinceUpdate > updatePeriod {
                updateSession()
                updateStreams()
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
    
    func updateConsumer(mc: MeasurementConsumer) {
        _ = (sourced?.temperature).map(mc.newTemperature)
    }
    
    func updateSession() {
        session.windDirection = VaavudSDK.shared.session.meanDirection
        session.location = VaavudSDK.shared.session.locations.last.map { makeNamedLocation(geoname, event: $0) }
        session.sourced = sourced
        session.pressure = VaavudSDK.shared.session.pressures.last?.pressure
        session.windMean = VaavudSDK.shared.session.meanSpeed
        session.windMax = VaavudSDK.shared.session.maxSpeed
        
        firebase
            .childByAppendingPaths("session", session.key)
            .setValue(session.fireDict)
    }
    
    func updateStreams() {
        if let index = windDirectionTracker.newUploadIndex() {
            firebase
                .childByAppendingPaths("windDirection", session.key, index)
                .setValue(VaavudSDK.shared.session.windDirections.last!.fireDict)
        }
        
        if let index = locationTracker.newUploadIndex() {
            firebase
                .childByAppendingPaths("location", session.key, index)
                .setValue(VaavudSDK.shared.session.locations.last!.fireDict)
        }
        
        if let index = pressureTracker.newUploadIndex() {
            firebase
                .childByAppendingPaths("pressure", session.key, index)
                .setValue(VaavudSDK.shared.session.pressures.last!.fireDict)
        }
        
        if let index = velocityTracker.newUploadIndex() {
            firebase
                .childByAppendingPaths("velocity", session.key, index)
                .setValue(VaavudSDK.shared.session.velocities.last!.fireDict)
        }
        
        if mjolnir?.dynamicsIsValid == false {
            return
        }
        
        if let index = windTracker.newUploadIndex() {
            firebase
                .childByAppendingPaths("wind", session.key, index)
                .setValue(VaavudSDK.shared.session.windSpeeds.last!.fireDict)
        }
    }

    func save(userCancelled: Bool) {
        guard !state.countingDown && !userCancelled && session.windMean > 0 else {
            return
        }
        
        session.timeEnd = NSDate()
        session.turbulence = VaavudSDK.shared.session.turbulence
        
        firebase
            .childByAppendingPaths("session", session.key)
            .setValue(session.fireDict)
        
        let post = firebase
            .childByAppendingPaths("sessionComplete", "queue", "tasks")
            .childByAutoId()
        
        post.setValue(["sessionKey" : session.key])
        
        if DBSession.sharedSession().isLinked() {
            DropboxUploader.shared.uploadToDropbox(VaavudSDK.shared.session, aggregate: session)
        }
    }
    
    func stop(userCancelled: Bool) {
        let cancel = userCancelled || session.windMean == 0 || state.countingDown
        
        VaavudSDK.shared.stop()

        if model == .Mjolnir {
            mjolnir?.stop()
            mjolnir?.delegate = nil
        }
        
        reportToUrlSchemeCaller(cancel)
        
        displayLink.invalidate()
        currentConsumer = nil
        
        VaavudSDK.shared.removeAllCallbacks()

        if cancel {
            if state.running {
                firebase.childByAppendingPaths("session", session.key).removeValue()
                firebase.childByAppendingPaths("sessionDeleted", session.key).setValue(session.fireDict)
            }
            
            dismissViewControllerAnimated(true) {
                self.viewControllers = []
            }
        }
        else {
            let summary = storyboard!.instantiateViewControllerWithIdentifier("SummaryViewController") as! SummaryViewController
            summary.session = session
            
            pageController.dataSource = nil
            pageController.setViewControllers([summary], direction: .Forward, animated: true) { _ in
                self.viewControllers = []
            }
            
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
    
    // MARK: Mjolnir Delegate
    
    func changedValidity(isValid: Bool, dynamicsIsValid: Bool) {
        if !isValid {
            currentConsumer?.newWindSpeed(0)
        }

        if !dynamicsIsValid {
            UIView.animateWithDuration(0.2, delay: 2, options: [], animations: { self.errorOverlayBackground.alpha = 1 }, completion: nil)
        }
        else {
            errorOverlayBackground.layer.removeAllAnimations()
            UIView.animateWithDuration(0.2) {
                self.errorOverlayBackground.alpha = 0
            }
        }
    }
    
    func addSpeedMeasurement(currentSpeed: NSNumber!, avgSpeed: NSNumber!, maxSpeed: NSNumber!) {
        if mjolnir?.dynamicsIsValid == false {
            return
        }

        VaavudSDK.shared.newWindSpeed(WindSpeedEvent(time: NSDate(), speed: currentSpeed.doubleValue))
    }
    
    // MARK: SDK Delegate
    
    func newWindSpeed(event: WindSpeedEvent) {
        windTracker.hasNewValue = true
        currentConsumer?.newWindSpeed(event.speed)
        guard let session = session else { return }
        currentConsumer?.newWindSpeedMax(session.windMax)
    }
    
    func newWindDirection(event: WindDirectionEvent) {
        windDirectionTracker.hasNewValue = true
        currentConsumer?.newWindDirection(event.direction)
    }

    func newTrueWindDirection(event: WindDirectionEvent) {
//        print("CLLocation newTrueWindDirection \(event)")
        currentConsumer?.newTrueWindDirection(event.direction)
    }
    
    func newTrueWindSpeed(event: WindSpeedEvent) {
//        print("CLLocation newTrueWindSpeed \(event)")
        currentConsumer?.newTrueWindSpeed(event.speed)
    }
    
    func newHeading(event: HeadingEvent) {
        currentConsumer?.newHeading(event.heading)
    }
    
    func newLocation(event: LocationEvent) {
        locationTracker.hasNewValue = true
        
        if geoname == nil {
            requestGeocode(event.location.coordinate)
        }
        if sourced == nil {
            requestSourcedData(event.location.coordinate)
        }
    }
    
    func newVelocity(event: VelocityEvent) {
        velocityTracker.hasNewValue = true
        currentConsumer?.newVelocity(event.course, speed: event.speed)
    }
    
    func newPressure(event: PressureEvent) {
        pressureTracker.hasNewValue = true
    }
    
    // MARK - Network requests
    
    func requestGeocode(location: CLLocationCoordinate2D) {
        ForecastLoader.shared.requestGeocode(location) { name in
            guard let name = name else { return }
            self.geoname = name

            guard self.session != nil else { return }
            self.updateSession()
        }
    }
    
    func requestSourcedData(location: CLLocationCoordinate2D) {
        ForecastLoader.shared.requestFullForecast(location) { sourced in
            self.sourced = sourced
            if let mc = self.currentConsumer { self.updateConsumer(mc) }

            guard self.session != nil else { return }
            self.updateSession()
        }
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
    
    private func logStop(manner: String) {
        var props: [String : AnyObject] = ["manner" : manner]
        
        for (index, key) in vcsNames.enumerate() {
            props[key] = screenUsage[index]
        }
        logHelper.ended(props)
    }

    private func changeConsumer(mc: MeasurementConsumer) {
        mc.newWindSpeed(VaavudSDK.shared.session.windSpeeds.last?.speed ?? 0)
        mc.changedSpeedUnit(VaavudFormatter.shared.speedUnit)
        
        if model == .Sleipnir,
            let wd = VaavudSDK.shared.session.windDirections.last?.direction,
            h = VaavudSDK.shared.session.headings.last?.heading {
            mc.newWindDirection(wd)
            mc.newHeading(h)
        }
        currentConsumer = mc
        
        updateConsumer(mc)
    }

    private func startSleipnir(flipped: Bool) {
        // fixme: handle error
        do {
            try VaavudSDK.shared.start(flipped)
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
        
        pager.currentPage = screenToShow
        
        let mc = viewControllers[screenToShow] as! MeasurementConsumer
        
        currentConsumer = mc
        updateVariantButton(mc)
        
        pageController.setViewControllers([viewControllers[screenToShow]], direction: .Forward, animated: false, completion: nil)
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
        let speed = VaavudSDK.shared.session.windSpeeds.last?.speed ?? 0
        let event = WindSpeedEvent(time: NSDate(), speed: max(0, speed - dy))
        
        VaavudSDK.shared.newWindSpeed(event)
        
        sender.setTranslation(CGPoint(), inView: view)
    }
}

func windchill(kelvin: Double?, _ windspeed: Double?) -> Double? {
    guard let kelvin = kelvin, windspeed = windspeed else {
        return nil
    }
    
    let celsius = kelvin - 273.15
    let kmh = windspeed*3.6
    
    if celsius > 10 || kmh < 4.8 {
        return nil
    }

    let k = 13.12
    let a = 0.6215
    let b = -11.37
    let c = 0.3965
    let d = 0.16

    return 273.15 + k + a*celsius + b*pow(kmh, d) + c*celsius*pow(kmh, d)
}


