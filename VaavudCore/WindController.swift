//
//  WindController.swift
//  Pods
//
//  Created by Andreas Okholm on 24/06/15.
//
//

import Foundation
import AVFoundation
import UIKit
import MediaPlayer
import CoreLocation

class WindController: NSObject, CLLocationManagerDelegate {
    weak var delegate: WindListener!
    var audioEngine = AVAudioEngine()
    var player = AVAudioPlayerNode()
    
    let outputBuffer : AVAudioPCMBuffer
    
    let locationManager = CLLocationManager()
    var heading: Float? // Since this variable is going to be accesed from multiple threads we will use a float, which we can assume will be writen and read in one instruction and thefore will not cause problems
    
    // there is a memory management bug / leak for these input/output formats. fix later.
    let inputFormat = AVAudioFormat(commonFormat: AVAudioCommonFormat.PCMFormatInt16, sampleRate: 44100.0, channels: 1, interleaved: false)
    let outputFormat = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 2)
    
    var sampleTimeLast = AVAudioFramePosition(0)
    var sampleTimeStart = AVAudioFramePosition(-1)
    var startTime : NSDate!
    var data = [Int16](count: 16537, repeatedValue: 0)
    var audioSampleProcessor = AudioSampleProcessor()
    var tickTimeProcessor = TickTimeProcessor()
    var rotationProcessor = RotationProcessor()
    var vol = Volume()
    
    var calibrationMode = false
    
    var observers = [NSObjectProtocol]()

    init(delegate: WindListener) {
        // initialize remaining variables
        self.delegate = delegate
        outputBuffer = WindController.createBuffer(AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2))
        super.init()
        createEngineAttachNodesConnect()
    }
    
    func resetAudio() {
        audioEngine = AVAudioEngine()
        player = AVAudioPlayerNode()
    }
    
    func createEngineAttachNodesConnect() {
        audioEngine.attachNode(player)
        audioEngine.connect(player, to: audioEngine.mainMixerNode, format: outputBuffer.format)
        
        // setup input
        audioEngine.inputNode.installTapOnBus(0, bufferSize: 16537, format: inputFormat) {
            [weak self] (buffer: AVAudioPCMBuffer!, time: AVAudioTime!) in
            if let strongSelf = self {
                strongSelf.inputHandler(buffer, time: time)
            }
        }
    }

    func start() -> ErrorEvent? {
        // setup volume
        audioEngine.mainMixerNode.outputVolume = vol.getVolume()
        setVolumeToMax()
        
        // initialize AVAudioSession
        initAVAudioSession()
        
        // check current route
        if let currentRouteError = checkCurrentRoute() {
            stop()
            return currentRouteError
        }
        
        if let startEngineError = startEngine() {
            stop()
            return startEngineError
        }
        
        if let startLocationError = startLocationService() {
            stop()
            return startLocationError
        }
        
        startOutput()
        
        return nil
    }
    
    func startCalibration() -> ErrorEvent? {
        calibrationMode = true
        return start()
    }
    
    func stop() {
        observers.map(NSNotificationCenter.defaultCenter().removeObserver) // TODO: check
        vol.saveVolume()
        audioEngine.pause() // the other options (stop/reset) does ocationally cause a BAD_ACCESS CAStreamBasicDescription
    }
    
    func startEngine() -> ErrorEvent? {
        // start the engine and play
        
        /*  startAndReturnError: calls prepare if it has not already been called since stop.
        
        Starts the audio hardware via the AVAudioInputNode and/or AVAudioOutputNode instances in
        the engine. Audio begins flowing through the engine.
        
        This method will return nil for success.
        
        Reasons for potential failure include:
        
        1. There is problem in the structure of the graph. Input can't be routed to output or to a
        recording tap through converter type nodes.
        2. An AVAudioSession error.
        3. The driver failed to start the hardware. */
        
        var error: NSError?
        
        if !audioEngine.startAndReturnError(&error) {
            return ErrorEvent("Could not start engine, " + error!.localizedDescription, user: "Internal sound system error! Engine Start")
        }
        return nil
    }
    
    func startLocationService() -> ErrorEvent? {
        if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.Denied {
            return ErrorEvent("Can not start since the app is not authorized to use location services, Denied", user: "Can not start since the app is not authorized to use location services, change phone settings!")
        }
        
        if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.Restricted {
            return ErrorEvent("Can not start since the app is not authorized to use location services, Restricted", user: "Can not start since the app is not authorized to use location services")
        }
        
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        locationManager.distanceFilter = 10
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.startUpdatingLocation()
        
        locationManager.headingFilter = 5
        
        if UIDevice.currentDevice().orientation == UIDeviceOrientation.PortraitUpsideDown {
            locationManager.headingOrientation = CLDeviceOrientation.PortraitUpsideDown
        }
        locationManager.startUpdatingHeading()
        
        return nil
    }
    
    func startOutput() {
        player.play()
        player.scheduleBuffer(outputBuffer, atTime: nil, options: .Loops, completionHandler: nil)
    }
    
    func inputHandler(buffer: AVAudioPCMBuffer!, time: AVAudioTime!) {
        let sampleTimeBufferStart = time.sampleTime - Int64(buffer.frameLength)
        updateTime(sampleTimeBufferStart, bufferLength: buffer.frameLength)
        copyData(buffer)
        
        let ticks = audioSampleProcessor.processSamples(data, sampleTime: sampleTimeBufferStart)
        let (rotations, detectionErrors) = tickTimeProcessor.processTicks(ticks, heading: heading)
        let directions = rotationProcessor.processRotations(rotations)
        
        // find the correct audio volume
        let noise = noiseEstimator(data)
        let resp = AudioResponse(diff20: noise.diff20, rotations: rotations.count, detectionErrors: detectionErrors, sN: noise.sN)
        audioEngine.mainMixerNode.outputVolume = vol.newVolume(resp)
        
//        var plotData = [CGFloat](count: 256, repeatedValue: 0)
//        for i in 0..<plotData.count {
//            plotData[i] = CGFloat(data[i])
//        }
        
//        let un = Array(data[0..<256].map {CGFloat($0)})
        
        dispatch_async(dispatch_get_main_queue()) {
            for rotation in rotations {
                let measurementTime = self.sampleTimeToUnixTime(rotation.sampleTime)
                let windspeed = WindController.rotationFrequencyToWindspeed(44100/Double(rotation.timeOneRotaion))
                self.delegate.newWindSpeed(Failable(WindSpeedEvent(time: measurementTime, speed: windspeed)))
            }
            
            for direction in directions {
                let measurementTime = self.sampleTimeToUnixTime(direction.sampleTime)
                self.delegate.newWindDirection(Failable(WindDirectionEvent(time: measurementTime, direction: direction.direction)))
            }
            
//            self.delegate.debugPlot([plotData])
            
            self.delegate.debugPlot([
                self.rotationProcessor.calCoef.map {CGFloat($0)},
                self.rotationProcessor.relVelocitiesSteadyLP.map {CGFloat($0)},
//                self.rotationProcessor.relVelocitiesSDSP.map({CGFloat($0)}),
                map(zip(self.rotationProcessor.relVelocitiesSteadyLP, self.rotationProcessor.calCoef)) {CGFloat($0-$1)}
                ])
        }
        
        if calibrationMode {
            if rotationProcessor.calibrationPercentage > 100 {
                stop()
                rotationProcessor.saveCalibration()
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                self.delegate.calibrationProgress(self.rotationProcessor.calibrationPercentage)
            }
        }

        //  plot(rotationProcessor.relVelocitiesSteadyLP.map({CGFloat($0)}))
    }
    
    func setVolumeToMax() {
        let volView = MPVolumeView()
        
        for view in volView.subviews {
            let uiview = view as! UIView
            if uiview.description.rangeOfString("MPVolumeSlider") != nil {
                let mpVolumeSilder = (uiview as! UISlider)
                mpVolumeSilder.value = 1
            }
        }
    }
    
    func updateTime(sampleTime: AVAudioFramePosition, bufferLength: AVAudioFrameCount) {
        if sampleTimeStart == -1 {
            sampleTimeStart = sampleTime
            startTime = NSDate()
        }
        else {
            if sampleTimeLast + AVAudioFramePosition(bufferLength) != sampleTime {
                println("Oops. Samples Lost at time: \(sampleTime)")
            }
        }
        sampleTimeLast = sampleTime
    }
    
    func copyData(buffer: AVAudioPCMBuffer) {
        var channel = buffer.int16ChannelData[0]
        for i in 0..<Int(buffer.frameLength) {
            data[i] = channel[i]
        }
    }
    
    class func createBuffer(outputFormat: AVAudioFormat) -> AVAudioPCMBuffer {
        var buffer = AVAudioPCMBuffer(PCMFormat: outputFormat, frameCapacity: 99)
        buffer.frameLength = 99 // should end in 3
        
        let leftChannel = buffer.floatChannelData[0]
        let rightChannel = buffer.floatChannelData[1]
        
        for i in 0..<Int(buffer.frameLength) {
            leftChannel[i] = sinf(Float(i)*2*Float(M_PI)/3) // a 3 of the sample frequency
            rightChannel[i] = -sinf(Float(i)*2*Float(M_PI)/3)
        }
        return buffer
    }
    
    func sampleTimeToUnixTime(sampleTime: Int64) -> NSDate {
        return startTime.dateByAddingTimeInterval(Double(sampleTime - sampleTimeStart)/44100)
    }
    
    func noiseEstimator(samples: [Int16]) -> (diff20: Int, sN: Double) {
        let skipSamples = 10000
        let nSamples = 100
        let percentile = 19
        
        var diffValues = [Int]()

        for _ in 0..<nSamples {
            let index = Int(arc4random_uniform(UInt32(samples.count - skipSamples - 3))) + skipSamples
            var diff = 0
            
            for j in 0..<3 {
                diff = diff + abs(samples[index + j] - samples[index + j + 1])
            }
            
            diffValues.append(diff)
        }

        diffValues.sort(<)
        
        let preSN = Double(diffValues[79])/Double(diffValues[39])
        let sN = preSN == Double.infinity ? 0 : preSN
        
        return (diffValues[19], sN)
    }
    
    func checkCurrentRoute() -> ErrorEvent? {
        // Configure the audio session
        let sessionInstance = AVAudioSession.sharedInstance()
        let currentRoute = sessionInstance.currentRoute

        // check if headset and microphone wired
//        var headsetMicActive = false
//        var headphonesActive = false
        
        var headsetMicActive = true // DEBUGGING IN SIMULATOR
        var headphonesActive = true
        
        if let inputs = currentRoute.inputs where inputs.count > 0 {
            headsetMicActive = AVAudioSessionPortHeadsetMic == inputs[0].portType
        }
        
        if let outputs = currentRoute.outputs where outputs.count > 0 {
                headphonesActive = AVAudioSessionPortHeadphones == currentRoute.outputs[0].portType
        }
        
        if headsetMicActive && headphonesActive {
            return nil
        }
        
        return ErrorEvent("Could not start measuring since Sleipnir measurement is not avialable since Headset and headsetmic not available: Current route \(currentRoute)", user: "Could not start measuring since the Sleipnir wind meter is not pluged into the audio jack")
    }
    
    func initAVAudioSession() -> ErrorEvent? {
        // For complete details regarding the use of AVAudioSession see the AVAudioSession Programming Guide
        // https://developer.apple.com/library/ios/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/Introduction/Introduction.html
        
        // Configure the audio session
        let sessionInstance = AVAudioSession.sharedInstance()
        var error: NSError?
        
        let errorUserDescriptionBase = "Error configuring audio system! "
        
        var success = sessionInstance.setCategory(AVAudioSessionCategoryPlayAndRecord, error: &error)
        if !success {
            return ErrorEvent("Error setting AVAudioSession category! " + error!.localizedDescription,
                user: errorUserDescriptionBase + "Category")
        }
        
        let hsSampleRate = 44100.0
        success = sessionInstance.setPreferredSampleRate(hsSampleRate, error: &error)
        if !success {
            return ErrorEvent("Error setting preferred sample rate! " + error!.localizedDescription, user: errorUserDescriptionBase + "Sample Rate")
        }
        
        let ioBufferDuration = 0.0029
        success = sessionInstance.setPreferredIOBufferDuration(ioBufferDuration, error:&error)
        if !success {
            ErrorEvent("Error setting preferred io buffer duration! " + error!.localizedDescription, user: errorUserDescriptionBase + "Buffer Duration")
        }
        
        let nc = NSNotificationCenter.defaultCenter()
        let mainQueue = NSOperationQueue.mainQueue()

        let interuptionObserver = nc.addObserverForName(AVAudioSessionInterruptionNotification, object:sessionInstance, queue:mainQueue) {
            [unowned self] notification in
            var info = notification.userInfo!
            var intValue: UInt = 0
            (info[AVAudioSessionInterruptionTypeKey] as! NSValue).getValue(&intValue)
            if let type = AVAudioSessionInterruptionType(rawValue: intValue) {
                switch type {
                case .Began:
                    // interruption began
                    // stop sleipnir on all interuptions
                    self.stop()
                    let error = ErrorEvent("Audio interuption has stopped the measurement")
                    self.delegate.newWindDirection(Failable(error))
                    self.delegate.newWindSpeed(Failable(error))
                    println("began interuption, stoped the audio system ")
                case .Ended:
                    // interruption ended
                    println("ended interuption")
                }
            }
        }
        observers.append(interuptionObserver)
        
        var routeObserver = nc.addObserverForName(AVAudioSessionRouteChangeNotification, object:sessionInstance, queue:mainQueue) {
            [unowned self] notification in
            var info = notification.userInfo!
            var intValue: UInt = 0
            (info[AVAudioSessionRouteChangeReasonKey] as! NSValue).getValue(&intValue)
            if let type = AVAudioSessionRouteChangeReason(rawValue: intValue) {
                switch type {
                    
                case .Unknown:
                    println("unknown route change")
                case .NewDeviceAvailable:
                    println("newDeviceAvailable")
                case .OldDeviceUnavailable:
                    println("OldDeviceUnavailable")
                case .CategoryChange:
                    println("CategoryChange")
                case .Override:
                    println("Override")
                case .WakeFromSleep:
                    println("WakeFromSleep")
                case .NoSuitableRouteForCategory:
                    println("NoSuitableRouteForCategory")
                case .RouteConfigurationChange:
                    println("RouteConfigChange")
                }
            }
            // stop algorithm on all route changes
            self.stop()
            let error = ErrorEvent("Audio route has changed and the measurement has been stopped")
            self.delegate.newWindDirection(Failable(error))
            self.delegate.newWindSpeed(Failable(error))

        }
        observers.append(routeObserver)
    
        var mediaObserver = nc.addObserverForName(AVAudioSessionMediaServicesWereResetNotification, object: sessionInstance, queue: mainQueue) {
            [unowned self] notification in
            // if we've received this notification, the media server has been reset
            // re-wire all the connections and start the engine
            println("Media services have been reset!")
            println("Re-wiring connections and starting once again")
            
            self.resetAudio()
            self.createEngineAttachNodesConnect()
            self.startEngine()
            self.startOutput()
        }
        observers.append(mediaObserver)
        
        return nil
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        if let locations = locations as? [CLLocation] {
            locations.map { loc in
                println("latitude: \(loc.coordinate.latitude) and longitude: \(loc.coordinate.longitude)")
            }
        }
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateHeading newHeading: CLHeading!) {
        heading = Float(newHeading.trueHeading)
//        println("heading: \(newHeading.trueHeading) heading accuracy: \(newHeading.headingAccuracy)")
    }
    
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        println(error.debugDescription)
    }
    
    static func rotationFrequencyToWindspeed(freq: Double) -> Double {
        return freq > 0.0 ? freq*0.325 + 0.2 : 0.0
    }
    
    deinit {
        // perform the deinitialization
        println("DEINIT AudioIO")
    }
}