//
//  MeasureRootViewController.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 30/05/15.
//  Copyright (c) 2015 Andreas Okholm. All rights reserved.
//

import UIKit
import CoreMotion

let updatePeriod = 1.0
let countdownInterval = 3
let limitedInterval = 7
let minimumDuration = 3.0

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

    func changedSpeedUnit(unit: SpeedUnit)
    func useMjolnir()
}

class MeasureRootViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, WindMeasurementControllerDelegate, VaavudElectronicWindDelegate, DBRestClientDelegate {
    private var pageController: UIPageViewController!
    private var viewControllers: [UIViewController]!
    private var displayLink: CADisplayLink!

    private let geocoder = CLGeocoder()
    
    private var dropboxUploader: DropboxUploader?
    
    private var altimeter: CMAltimeter?
    
    private let sdk = VEVaavudElectronicSDK.sharedVaavudElectronic()
    
    private var mjolnir: MjolnirMeasurementController?
    
    private let currentSessionUuid = UUIDUtil.generateUUID()
    
    private var currentSession: MeasurementSession? {
        return MeasurementSession.MR_findFirstByAttribute("uuid", withValue: currentSessionUuid)
    }
    
    let isSleipnirSession: Bool
    
    private var formatter = VaavudFormatter()

    @IBOutlet weak var pager: UIPageControl!
    
    @IBOutlet weak var unitButton: UIButton!
    @IBOutlet weak var readingTypeButton: UIButton!
    @IBOutlet weak var cancelButton: MeasureCancelButton!
    
    var currentConsumer: MeasurementConsumer?
    
    private var latestHeading: CGFloat = 0
    private var latestWindDirection: CGFloat = 0
    private var latestSpeed: CGFloat = 0

    private var maxSpeed: CGFloat = 0

    private var avgSpeed: CGFloat { return speedsSum/CGFloat(speedsCount) }
    private var speedsSum: CGFloat = 0
    private var speedsCount = 0
    
    private var elapsedSinceUpdate = 0.0
    
    var state = MeasureState.Done
    var timeLeft = CGFloat(countdownInterval)
    
    required init(coder aDecoder: NSCoder) {
        isSleipnirSession = sdk.sleipnirAvailable()
        
        super.init(coder: aDecoder)
        
        state = MeasureState.CountingDown(countdownInterval, Property.getAsBoolean(KEY_MEASUREMENT_TIME_LIMITED))
        
        let usesSleipnir = Property.getAsBoolean(KEY_USES_SLEIPNIR)
        println("CREATED ROOT (wants sleipnir : \(usesSleipnir), has sleipnir: \(isSleipnirSession))")
        
        if usesSleipnir != isSleipnirSession {
            NSNotificationCenter.defaultCenter().postNotificationName(KEY_WINDMETERMODEL_CHANGED, object: self)
        }

        if isSleipnirSession {
            println("#### Sleipnir session")
            Property.setAsBoolean(true, forKey: KEY_USES_SLEIPNIR)
            sdk.addListener(self)
            sdk.start()
        }
        else if usesSleipnir {
            // Expected Sleipnir, but it doesn't work or exist.
            println("#### Expected Sleipnir, but it doesn't work or exist")
            // Show error message and return
            stop(true)
            return
        }
        else {
            println("#### Mjolnir session")
            let mjolnirController = MjolnirMeasurementController()
            mjolnirController.delegate = self
            mjolnirController.start()
            mjolnir = mjolnirController
        }
        
        if let sessions = MeasurementSession.MR_findByAttribute("measuring", withValue: true) as? [MeasurementSession] {
            sessions.map { $0.measuring = false }
        }
        
        NSManagedObjectContext.MR_defaultContext().MR_saveToPersistentStoreWithCompletion(nil)
        
        if CMAltimeter.isRelativeAltitudeAvailable() {
            altimeter = CMAltimeter()
            updateWithPressure(currentSessionUuid)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        hideVolumeHUD()
        
        let (old, flat, round) = ("OldMeasureViewController", "FlatMeasureViewController", "RoundMeasureViewController")
        let vcsNames = isSleipnirSession ? [old, flat, round] : [old, flat]
        viewControllers = vcsNames.map { self.storyboard!.instantiateViewControllerWithIdentifier($0) as! UIViewController }
        currentConsumer = (viewControllers.first as! MeasurementConsumer)

        if !isSleipnirSession { viewControllers.map { ($0 as! MeasurementConsumer).useMjolnir() } }
        
        pager.numberOfPages = viewControllers.count
        
        pageController = storyboard?.instantiateViewControllerWithIdentifier("PageViewController") as? UIPageViewController
        pageController.dataSource = self
        pageController.delegate = self
        pageController.view.frame = view.bounds
        pageController.setViewControllers([viewControllers[0]], direction: .Forward, animated: false, completion: nil)
        
        addChildViewController(pageController)
        view.addSubview(pageController.view)
        pageController.didMoveToParentViewController(self)
        
        view.bringSubviewToFront(pager)
        view.bringSubviewToFront(unitButton)
        view.bringSubviewToFront(readingTypeButton)
        view.bringSubviewToFront(cancelButton)
        
        cancelButton.setup()
        
        displayLink = CADisplayLink(target: self, selector: Selector("tick:"))
        displayLink.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
        
        unitButton.setTitle(formatter.windSpeedUnit.localizedString, forState: .Normal)
        
        LocationManager.sharedInstance().start()
    }
    
    @IBAction func tappedUnit(sender: UIButton) {
        formatter.windSpeedUnit = formatter.windSpeedUnit.next
        unitButton.setTitle(formatter.windSpeedUnit.localizedString, forState: .Normal)
        currentConsumer?.changedSpeedUnit(formatter.windSpeedUnit)
    }
    
    @IBAction func tappedCancel(sender: MeasureCancelButton) {
        switch state {
        case .CountingDown:
            println("ROOT: tappedCancel(CountingDown)")
            stop(true)
        case .Limited:
            println("ROOT: tappedCancel(Limited)")
            stop(true)
            save(true)
        case .Unlimited:
            // TODO: Possibly check how long the measurement is before saving
            println("ROOT: tappedCancel(Unlimited)")
            stop(false)
            save(false)
        case .Done:
            println("ROOT: tappedCancel(Done)")
            break
        }
    }
    
    func tick(link: CADisplayLink) {
        currentConsumer?.tick()
        
        if state.running {
            speedsCount++
            speedsSum += latestSpeed
            elapsedSinceUpdate += link.duration
        
            if elapsedSinceUpdate > updatePeriod {
                elapsedSinceUpdate = 0
                updateSession()
            }
        }
        
        switch state {
        case let .CountingDown(_, limited):
            if timeLeft < 0 {
                if limited {
                    state = .Limited(limitedInterval)
                    timeLeft = CGFloat(limitedInterval)
                }
                else {
                    state = .Unlimited
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
                stop(false)
                save(false)
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

    func hasValidLocation(session: MeasurementSession) -> CLLocationCoordinate2D? {
        if let lat = session.latitude?.doubleValue, long = session.longitude?.doubleValue {
            let loc = CLLocationCoordinate2D(latitude: lat, longitude: long)
            if LocationManager.isCoordinateValid(loc) {
                return loc
            }
        }
        
        return nil
    }
    
    func updateWithLocation(session: MeasurementSession) {
        let loc = LocationManager.sharedInstance().latestLocation
        
        if LocationManager.isCoordinateValid(loc) {
            (session.latitude, session.longitude) = (loc.latitude, loc.longitude)
        }
    }

    func updateWithGeocode(session: MeasurementSession) {
        if let lat = session.latitude?.doubleValue, long = session.longitude?.doubleValue {
            geocoder.reverseGeocodeLocation(CLLocation(latitude: lat, longitude: long)) { placemarks, error in
                dispatch_async(dispatch_get_main_queue()) {
                    if error == nil {
                        if let first = placemarks.first as? CLPlacemark,
                            let s = NSManagedObjectContext.MR_defaultContext().existingObjectWithID(session.objectID, error: nil) as? MeasurementSession {
                                s.geoLocationNameLocalized = first.thoroughfare ?? first.locality ?? first.country
                                let userInfo = ["objectID" : s.objectID, "geoLocationNameLocalized" : true]
                                NSManagedObjectContext.MR_defaultContext().MR_saveToPersistentStoreWithCompletion { s, e in
                                    NSNotificationCenter.defaultCenter().postNotificationName(KEY_SESSION_UPDATED, object: self, userInfo: userInfo)
                                }
                        }
                    }
                    else {
                        println("Geocode failed with error: \(error)")
                    }
                }
            }
        }
    }
    
    func updateWithSourcedData(session: MeasurementSession) {
        let objectId = session.objectID
        let loc = hasValidLocation(session) ?? LocationManager.sharedInstance().latestLocation
        ServerUploadManager.sharedInstance().lookupForLat(loc.latitude, long: loc.longitude, success: { t, d, p in
            if let session = NSManagedObjectContext.MR_defaultContext().existingObjectWithID(objectId, error: nil) as? MeasurementSession {
                session.sourcedTemperature = t ?? nil
                session.sourcedPressureGroundLevel = p ?? nil // tabort
                session.sourcedWindDirection = d ?? nil
                
                let userInfo = ["objectID" : objectId, "sourcedTemperature" : t != nil, "sourcedPressureGroundLevel" : p != nil, "sourcedWindDirection" : d != nil]

                NSManagedObjectContext.MR_defaultContext().MR_saveToPersistentStoreWithCompletion { s, e in
                    NSNotificationCenter.defaultCenter().postNotificationName(KEY_SESSION_UPDATED, object: self, userInfo: userInfo)
                }
            }
            }, failure: { error in println("<<<<SOURCED LOOKUP>>>> FAILED \(error)") })
    }
    
    func updateWithPressure(uuid: String) {
        altimeter?.startRelativeAltitudeUpdatesToQueue(NSOperationQueue.mainQueue()) {
            altitudeData, error in
            if let session = MeasurementSession.MR_findFirstByAttribute("uuid", withValue: uuid) {
                let userInfo = ["objectId" : session.objectID, "pressure" : true]
                NSManagedObjectContext.MR_defaultContext().MR_saveToPersistentStoreWithCompletion { s, e in
                    NSNotificationCenter.defaultCenter().postNotificationName(KEY_SESSION_UPDATED, object: self, userInfo: userInfo)
                }
            }
        }
    }
    
    func start() {
        println("ROOT: start")

        elapsedSinceUpdate = 0
        
        let model: WindMeterModel = isSleipnirSession ? .Sleipnir : .Mjolnir
        
        let session = MeasurementSession.MR_createEntity()
        session.uuid = currentSessionUuid
        session.device = Property.getAsString(KEY_DEVICE_UUID)
        session.windMeter = model.rawValue
        session.startTime = NSDate()
        session.timezoneOffset = NSTimeZone.localTimeZone().secondsFromGMTForDate(session.startTime)
        session.endTime = session.startTime
        session.measuring = true
        session.uploaded = false
        session.startIndex = 0
        session.privacy = 1
        
        updateWithLocation(session)
        updateWithSourcedData(session)
    }
    
    func updateSession() {
        let now = NSDate()
        
        if let session = currentSession where session.measuring.boolValue {
            updateWithLocation(session)
            
            session.endTime = now
            session.windSpeedMax = maxSpeed
            session.windSpeedAvg = avgSpeed
            if isSleipnirSession { session.windDirection = mod(latestWindDirection, 360) }

            let point = MeasurementPoint.MR_createEntity()
            point.session = session
            point.time = now
            point.windSpeed = latestSpeed
            if isSleipnirSession { point.windDirection = mod(latestWindDirection, 360) }
        }
        else {
            println("ROOT: updateSession - ERROR: No current session")
            // Stopped by model, tell delegate?
        }
    }
    
    func save(cancelled: Bool) {
        println("ROOT: save(cancelled: \(cancelled))")
        
        if let session = currentSession where session.measuring.boolValue {
            session.measuring = false
            session.endTime = NSDate()
            session.windSpeedMax = maxSpeed
            session.windSpeedAvg = avgSpeed
            if isSleipnirSession { session.windDirection = mod(latestWindDirection, 360) }
            
            if let pts = session.points where pts.count > 2 { session.gustiness = gustiness(pts) }
            
            if cancelled { session.MR_deleteEntity() }
        
            updateWithLocation(session)
            updateWithGeocode(session)
            
            NSManagedObjectContext.MR_defaultContext().MR_saveToPersistentStoreWithCompletion {
                success, error in
                ServerUploadManager.sharedInstance().triggerUpload()
                
                if success {
                    println("ROOT: save - Saved and uploaded after measuring ============================")
                }
                else if error != nil {
                    println("ROOT: save - Failed to save session after measuring with error: \(error.localizedDescription)")
                }
                else {
                    println("ROOT: save - Failed to save session after measuring with no error message")
                }
                
                if !cancelled {
                    NSNotificationCenter.defaultCenter().postNotificationName(KEY_OPEN_LATEST_SUMMARY, object: self, userInfo: ["uuid" : session.uuid])
                }
            }
        
            if DBSession.sharedSession().isLinked() {
                println("ROOT: save - dropbox was linked, uploading")

                let uploader = DropboxUploader(delegate: self)
                uploader.uploadToDropbox(session)
                dropboxUploader = uploader
            }
        }
    }
    
    func stop(cancelled: Bool) {
        println("ROOT: stop")
                
        state = .Done
        
        if isSleipnirSession {
            sdk.removeListener(self)
            sdk.stop()
        }
        else if let mjolnir = mjolnir {
            mjolnir.stop()
        }

        // Temperature lookup

        altimeter?.stopRelativeAltitudeUpdates()
        
        dismissViewControllerAnimated(true) {
            self.pageController.view.removeFromSuperview()
            self.pageController.removeFromParentViewController()
            self.viewControllers.map { $0.view.removeFromSuperview() }
            self.viewControllers.map { $0.removeFromParentViewController() }
            self.viewControllers = []
            self.currentConsumer = nil
            self.displayLink.invalidate()
        }
    }

    // MARK: Mjolnir Callback
    func addSpeedMeasurement(currentSpeed: NSNumber!, avgSpeed: NSNumber!, maxSpeed: NSNumber!) {
        newSpeed(currentSpeed)
    }
    
    // MARK: SDK Callbacks
    func newWindDirection(windDirection: NSNumber!) {
        latestWindDirection = CGFloat(windDirection.floatValue)
        currentConsumer?.newWindDirection(latestWindDirection)
    }
    
    func newSpeed(speed: NSNumber!) {
        latestSpeed = CGFloat(speed.floatValue)
        currentConsumer?.newSpeed(latestSpeed)
        if latestSpeed > maxSpeed { maxSpeed = latestSpeed }
    }
    
    func newHeading(heading: NSNumber!) {
        latestHeading = CGFloat(heading.floatValue)
        currentConsumer?.newHeading(latestHeading)
    }
    
    // MARK: Dropbox Callbacks

    func restClient(client: DBRestClient!, uploadFileFailedWithError error: NSError!) {
        println("File upload failed with error: \(error)");
    }
    
    func restClient(client: DBRestClient!, uploadedFile destPath: String!, from srcPath: String!, metadata: DBMetadata!) {
        var error: NSError?
        if NSFileManager.defaultManager().removeItemAtPath(srcPath, error: &error) {
            println("File uploaded and deleted successfully to path: \(metadata.path)")
        }
        else if let error = error {
            println("File uploaded successfully, but not deleted to path: \(metadata.path), error: \(error.localizedDescription)")
        }
        else {
            println("File uploaded successfully, but not deleted to path: \(metadata.path), no error message")
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.Portrait.rawValue) | Int(UIInterfaceOrientationMask.PortraitUpsideDown.rawValue)
    }
    
    func changeConsumer(mc: MeasurementConsumer) {
        mc.newSpeed(latestSpeed)
        mc.changedSpeedUnit(formatter.windSpeedUnit)
        if isSleipnirSession {
            mc.newWindDirection(latestWindDirection)
            mc.newHeading(latestHeading)
        }
        currentConsumer = mc
    }
    
    func pageViewController(pageViewController: UIPageViewController, willTransitionToViewControllers pendingViewControllers: [AnyObject]) {
        if let vc = pendingViewControllers.last as? UIViewController, mc = vc as? MeasurementConsumer {
            changeConsumer(mc)
        }
    }
    
    func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [AnyObject], transitionCompleted completed: Bool) {
        
        if let vc = pageViewController.viewControllers.last as? UIViewController, mc = vc as? MeasurementConsumer {
            if let current = find(viewControllers, vc) {
                pager.currentPage = current
            }
            changeConsumer(mc)
            
            let alpha: CGFloat = vc is MapMeasurementViewController ? 0 : 1
            UIView.animateWithDuration(0.3) {
                self.readingTypeButton.alpha = alpha
                self.unitButton.alpha = alpha
            }
        }
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        
        if let current = find(viewControllers, viewController) {
            let next = mod(current + 1, viewControllers.count)
            return viewControllers[next]
        }
        
        return nil
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {

        if let current = find(viewControllers, viewController) {
            let previous = mod(current - 1, viewControllers.count)
            return viewControllers[previous]
        }
        
        return nil
    }
    
    // MARK: Debug
    
    @IBAction func debugPanned(sender: UIPanGestureRecognizer) {
        let y = sender.locationInView(view).y
        let x = view.bounds.midX - sender.locationInView(view).x
        let dx = sender.translationInView(view).x/2
        let dy = sender.translationInView(view).y/20
        
        newWindDirection(latestWindDirection + dx)
        newSpeed(max(0, latestSpeed - dy))
        
        sender.setTranslation(CGPoint(), inView: view)
    }
}

func windchill() {
    
}

func gustiness(points: NSOrderedSet) -> Float {
    var speeds = [Float]()
    
    for p in points {
        if let p = p as? MeasurementPoint, s = p.windSpeed?.floatValue {
            speeds.append(s)
        }
    }

    let n = Float(speeds.count)
    let mean = speeds.reduce(0, combine: +)/n
    let variance = speeds.reduce(0) { $0 + ($1 - mean)*($1 - mean) }/(n - 1)
    
    return variance/mean
}

