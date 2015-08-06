//
//  MeasureRootViewController.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 30/05/15.
//  Copyright (c) 2015 Andreas Okholm. All rights reserved.
//

import UIKit

let updatePeriod = 1.0
let countdownInterval: CGFloat = 3
let limitedInterval: CGFloat = 7
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
}

class MeasureRootViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, VaavudElectronicWindDelegate, DBRestClientDelegate {
    private var pageController: UIPageViewController!
    private var viewControllers: [UIViewController]!
    private var displayLink: CADisplayLink!

    private var dropboxUploader: DropboxUploader?
    
    private let sdk = VEVaavudElectronicSDK.sharedVaavudElectronic()
    private let currentSessionUuid = UUIDUtil.generateUUID()
    private var currentSession: MeasurementSession? {
        return MeasurementSession.MR_findFirstByAttribute("uuid", withValue: currentSessionUuid) as? MeasurementSession
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
    
    var state = MeasureState.CountingDown(Int(countdownInterval), false)
    var timeLeft = countdownInterval
    
    required init(coder aDecoder: NSCoder) {
        isSleipnirSession = sdk.sleipnirAvailable()
        
        super.init(coder: aDecoder)
        
        let usesSleipnir = Property.getAsBoolean("usesSleipnir")
        println("CREATED ROOT (wants sleipnir : \(usesSleipnir), has sleipnir: \(isSleipnirSession))")
        
        if usesSleipnir != isSleipnirSession {
            NSNotificationCenter.defaultCenter().postNotificationName("WindmeterModelChange", object: self)
        }

        if isSleipnirSession {
            println("#### Sleipnir session")
            Property.setAsBoolean(true, forKey: "usesSleipnir")
            sdk.addListener(self)
            sdk.start()
        }
        else if usesSleipnir {
            // Expected Sleipnir, but it doesn't work or exist.
            println("#### Expected Sleipnir, but it doesn't work or exist")
            // Show error message and return
            return
        }
        else {
            println("#### Mjolnir session")

            // Mjolnir
        }
        
        if let sessions = MeasurementSession.MR_findByAttribute("measuring", withValue: true) as? [MeasurementSession] {
            sessions.map { $0.measuring = false }
        }
        NSManagedObjectContext.MR_defaultContext().MR_saveToPersistentStoreWithCompletion(nil)
    }

    deinit {
        println("REMOVED ROOT")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
                
        hideVolumeHUD()
        
        let vcsNames = ["OldMeasureViewController", "RoundMeasureViewController", "FlatMeasureViewController"]
        viewControllers = vcsNames.map { self.storyboard!.instantiateViewControllerWithIdentifier($0) as! UIViewController }
        currentConsumer = (viewControllers.first as! MeasurementConsumer)
        
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
            stop()
        case .Limited:
            println("ROOT: tappedCancel(Limited)")
            stop()
            save(true)
        case .Unlimited:
            println("ROOT: tappedCancel(Unlimited)")
            stop()
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
        case let .CountingDown(_, unlimited):
            if timeLeft < 0 {
                if unlimited {
                    state = .Unlimited
                }
                else {
                    state = .Limited(Int(limitedInterval))
                    timeLeft = limitedInterval
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
                
                stop()
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

    func start() {
        println("ROOT: start")

        elapsedSinceUpdate = 0
        
        let model: WindMeterModel = isSleipnirSession ? .Sleipnir : .Mjolnir
        
        let session = MeasurementSession.MR_createEntity() as! MeasurementSession
        session.uuid = currentSessionUuid
        session.device = Property.getAsString(KEY_DEVICE_UUID)
        session.windMeter = model.rawValue
        session.startTime = NSDate()
        session.timezoneOffset = NSTimeZone.localTimeZone().secondsFromGMTForDate(session.startTime)
        session.endTime = session.startTime
        session.measuring = true
        session.uploaded = false
        session.startIndex = 0
        //        session.privacy =
        
        // Temperature lookup
        // Altimeter
        // Geocoder
    }
    
    func updateSession() {
        let now = NSDate()
        
        println("ROOT: updateSession")
        
        if let session = currentSession where session.measuring.boolValue {
            // Update location
            
            session.endTime = now
            session.windSpeedMax = maxSpeed
            session.windSpeedAvg = avgSpeed
            session.windDirection = mod(latestWindDirection, 360)

            let point = MeasurementPoint.MR_createEntity() as! MeasurementPoint
            point.session = session
            point.time = now
            point.windSpeed = latestSpeed
            point.windDirection = mod(latestWindDirection, 360)
            
//            NSManagedObjectContext.MR_defaultContext().MR_saveToPersistentStoreWithCompletion {
//                success, error in
//                if success {
//                    println("ROOT: updateSession - Saved while measuring")
//                }
//                else if error != nil {
//                    println("ROOT: updateSession - Failed to save session while measuring with error: \(error.localizedDescription)")
//                }
//                else {
//                    println("ROOT: updateSession - Failed to save session while measuring with no error message")
//                }
//            }
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
            session.windDirection = mod(latestWindDirection, 360)
            //            session.gustiness =
            //            session.windChill =
            
            let duration = session.endTime.timeIntervalSinceDate(session.startTime)
            if duration < minimumDuration || cancelled { session.MR_deleteEntity() }

            println("ROOT: save: saved session with id: \(session.uuid)")
            session.latitude = 1
            session.longitude = 1
            session.geoLocationNameLocalized = session.uuid
            
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
            }
        
            if DBSession.sharedSession().isLinked() {
                println("ROOT: save - dropbox was linked, uploading")

                let uploader = DropboxUploader(delegate: self)
                uploader.uploadToDropbox(session)
                dropboxUploader = uploader
            }
        }
    }
    
    func stop() {
        println("ROOT: stop")
        
        state = .Done
        
        if self.isSleipnirSession {
            self.sdk.removeListener(self)
            self.sdk.stop()
        }

        // Temperature lookup
        // Altimeter
        // Geocoder
        
        dismissViewControllerAnimated(true) {
            self.pageController.view.removeFromSuperview()
            self.pageController.removeFromParentViewController()
            self.viewControllers = []
            self.displayLink.invalidate()
            self.currentConsumer = nil
        }
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
        mc.newWindDirection(latestWindDirection)
        mc.newHeading(latestHeading)
        mc.changedSpeedUnit(formatter.windSpeedUnit)
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
