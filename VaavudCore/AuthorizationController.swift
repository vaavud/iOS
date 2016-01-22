//
//  LoginBusinessController.swift
//  Vaavud
//
//  Created by Diego R on 11/20/15.
//  Copyright © 2015 Andreas Okholm. All rights reserved.
//

import UIKit
import Firebase
import VaavudSDK

let firebaseUrl = "https://vaavud-core-demo.firebaseio.com"
//let firebaseUrl = "https://vaavud-app.firebaseio.com/"

enum LoginError: String {
    case Network = "LOGIN_ERROR_NETWORK"
    case MalformedInformation = "LOGIN_ERROR_MALFORMED"
    case WrongInformation = "LOGIN_ERROR_WRONG"
    case Facebook = "LOGIN_ERROR_FACEBOOK"
    case EmailTaken = "LOGIN_ERROR_EMAIL"
    case Firebase = "LOGIN_ERROR_FIREBASE"
    case Unknown = "LOGIN_ERROR_UNKNOWN"
    
    // fixme: All error messages should exist
    var key: String {
        switch self {
        case .Network, .Firebase, .Facebook: return LoginError.Network.rawValue
        case .MalformedInformation, .WrongInformation: return LoginError.MalformedInformation.rawValue
        case .EmailTaken: return rawValue
        case .Unknown: return "REGISTER_FEEDBACK_ERROR_MESSAGE"
        }
    }
}

protocol LoginDelegate {
    func onSuccess(showActivitySelector: Bool)
    func onError(error: LoginError)
}

class AuthorizationController: NSObject {
    private var firebase = Firebase(url: firebaseUrl)
    var delegate: LoginDelegate?
    var uid: String?
    private var _deviceId: String?
    var deviceId: String { if _deviceId != nil { return _deviceId! } else { fatalError("No device id") } }
    static let shared = AuthorizationController()
    var isAuth: Bool { return NSUserDefaults.standardUserDefaults().objectForKey("deviceId") is String && firebase.authData != nil }
    
    
    
    
    func verifyAuth() -> Bool {
        if _deviceId != nil && uid != nil {
            registerNotifications()
            return true
        }
        
        let preferences = NSUserDefaults.standardUserDefaults()
        guard let deviceId = preferences.objectForKey("deviceId") as? String, authData = firebase.authData else {
            unauth()
            return false
        }
        
        uid = authData.uid
        _deviceId = deviceId
        
        registerNotifications()
        
        return true
    }
    
    func registerNotifications(){
//        let notificationSettings = UIUserNotificationSettings(forTypes: [.Alert , .Badge , .Sound] , categories: nil)
//        UIApplication.sharedApplication().registerUserNotificationSettings(notificationSettings)
//        UIApplication.sharedApplication().registerForRemoteNotifications()
    }
    
    func saveAPNToken(token: String) {
        if let uid = uid {
            let preferences = NSUserDefaults.standardUserDefaults()
            let deviceId = preferences.objectForKey("APNToken") as? String ?? ""
            
            if (token != deviceId) {
                preferences.setValue(token, forKey: "APNToken")
                preferences.synchronize()
                print("saving token " + "\(token)")
                
                firebase.childByAppendingPaths("user", uid, "notificationId", "apn",token).setValue(NSDate().ms)
            }
        }
    }
    
    func resetPassword(email: String, delegate: LoginDelegate){
        firebase.resetPasswordForUser(email, withCompletionBlock: { error in
            if error != nil {
                print(error)
                delegate.onError(.MalformedInformation)
            } else {
                delegate.onSuccess(true)
            }
        })
    }
    
    func unauth() {
        LogHelper.logWithGroupName("Login", event: "Logout")
        NSUserDefaults.standardUserDefaults().removeObjectForKey("deviceId")
        NSUserDefaults.standardUserDefaults().removeObjectForKey("APNToken")
        NSUserDefaults.standardUserDefaults().synchronize()
        firebase.unauth()
        uid = nil
        _deviceId = nil
    }
    
    func currentDeviceId() -> String {
        let preferences = NSUserDefaults.standardUserDefaults()
        
        guard let deviceId = preferences.objectForKey("deviceId") as? String else {
            fatalError("no device Id")
        }
        
        return deviceId
    }
    
    func login(email: String, password: String, delegate: LoginDelegate) {
        self.delegate = delegate
        
        firebase.authUser(email, password: password) { error, authData in
            if let error = error {
                if error.code == -6 {
                    self.verifyMigration(email, password: password)
                }
                else {
                    print(error)
                    self.delegate?.onError(.WrongInformation)
                }
                return
            }
            
            self.obtainUserInformation("user", key: authData.uid)
        }
    }
    
    private func obtainUserInformation(child: String, key: String) {
        firebase
            .childByAppendingPath(child).childByAppendingPath(key)
            .observeSingleEventOfType(.Value, withBlock: { data in
                guard let firebaseData = data.value as? FirebaseDictionary else {
                    self.delegate?.onError(.Unknown)
                    return
                }
                
                self.updateUserInformation(data.key, data: firebaseData)
            })
    }
    
    func signup(firstName: String, lastName: String, email: String, password: String, delegate: LoginDelegate) {
        self.delegate = delegate
        
        let country = NSLocale.currentLocale().objectForKey(NSLocaleCountryCode) as! String
        let language = NSLocale.preferredLanguages()[0]
        
        let newUserModel = User(firstName: firstName, lastName: lastName, country: country, language: language, email: email)
        
        firebase.createUser(email, password: password, withValueCompletionBlock: { error, authData in
            guard let _ = authData else {
                self.delegate?.onError(.EmailTaken)
                return
            }
            
            self.firebase.authUser(email, password: password) { error, authData in
                if let error = error {
                    if error.code == -6 {
                        self.verifyMigration(email, password: password)
                    }
                    else {
                        print(error)
                        self.delegate?.onError(.Firebase)
                    }
                    return
                }
                
                self.firebase.childByAppendingPath("user").childByAppendingPath(authData.uid).setValue(newUserModel.fireDict)
                self.updateUserInformation(authData.uid, data: newUserModel.fireDict)
            }
        })
    }
    
    func loginWithFacebook(delegate: LoginDelegate) {
        self.delegate = delegate
    
        let graphRequest = FBSDKGraphRequest(graphPath: "me", parameters:["fields" : "first_name, last_name, picture.type(large), email, name, id, gender"])
        graphRequest.startWithCompletionHandler{ (connection, result, error) in
            
            if error != nil{
                self.delegate?.onError(.Facebook)
                return
            }
            
            
            guard let email = result.valueForKey("email") as? String else {
                self.delegate?.onError(.Facebook)
                return
            }
            
            
            let firstName = result.valueForKey("first_name") as? String ?? ""
            let lastName = result.valueForKey("last_name") as? String ?? ""
            let country = NSLocale.currentLocale().objectForKey(NSLocaleCountryCode) as! String
            let language = NSLocale.preferredLanguages()[0]
                
            let callback = { (success: Bool, uid: String) in
                if success {
                    let userModel = User(firstName: firstName, lastName: lastName, country: country, language: language, email: email)
                    self.validateUserInformation(uid, userModel: userModel.fireDict)
                }
                else {
                    self.delegate?.onError(.Firebase)
                }
            }
            let token = FBSDKAccessToken.currentAccessToken().tokenString
            self.authWithFacebook(token, callback: callback)
        }
    }
    
    func updateActivity(activity: String){
        firebase.childByAppendingPath("user").childByAppendingPath(uid).updateChildValues(["activity" : activity])
    }
    
    private func validateUserInformation(uid: String, userModel: FirebaseDictionary) {
        let callback = { (data: FirebaseDictionary?) in
            if let data = data {
                self.updateUserInformation(uid, data: data)
            }
            else{
                self.firebase.childByAppendingPath("user").childByAppendingPath(uid).setValue(userModel)
                self.updateUserInformation(uid, data: userModel)
            }
        }
        
        obtainUserInformation("user", key: uid, callback: callback)
    }
    
    func validateUserSettings() {
        guard let uid = uid else { fatalError("no uid") }
        
        let ref = firebase.childByAppendingPaths("user", uid, "setting", "ios")
        ref.observeSingleEventOfType(.Value, withBlock: { data in
            if data.value is NSNull {
                ref.setValue(InstructionsShown().fireDict)
            }
        })
    }
    
    private func obtainUserInformation(child: String, key: String, callback: FirebaseDictionary? -> Void) {
        firebase
            .childByAppendingPath(child).childByAppendingPath(key)
            .observeSingleEventOfType(.Value, withBlock: { data in
                guard let firebaseData = data.value as? FirebaseDictionary else {
                    callback(nil)
                    return
                }
                
                callback(firebaseData)
            })
    }
    
    private func updateUserInformation(uid: String, data: FirebaseDictionary) {
        let osVersion =  UIDevice.currentDevice().systemVersion
        let appVersion = NSBundle.mainBundle().infoDictionary!["CFBundleShortVersionString"] as! String
        let appBuild = NSBundle.mainBundle().infoDictionary!["CFBundleVersion"] as! String
        let model = AuthorizationController.deviceModel
        let vendor = "Apple"
        
        let deviceObj = Device(appVersion: appVersion, appBuild: appBuild, model: model, vendor: vendor, osVersion: osVersion, uid: uid)
        
        let ref = firebase.childByAppendingPath("device")
        let post = ref.childByAutoId()
        post.setValue(deviceObj.fireDict)
        let deviceId = post.key
        
        post.childByAppendingPath("setting").setValue(DeviceSettings(mapHour: 24,
            hasAskedForLocationAccess: false,
            hasApprovedLocationAccess: false,
            usesSleipnir: false,
            sleipnirClipSideScreen: false,
            isDropboxLinked: false,
            measuringTime: 30,
            defaultMeasurementScreen: "OldMeasureViewController").fireDict)
        
        let preferences = NSUserDefaults.standardUserDefaults()
        preferences.setValue(deviceId, forKey: "deviceId")
        preferences.synchronize()
        
        self.uid = uid
        self._deviceId = deviceId
        
        verifyAuth()
        
        validateUserSettings()
        
        delegate?.onSuccess(!(data["activity"] is String))
    }
    
    private func verifyMigration(email: String, password: String) {
        let hashPassword = PasswordUtil.createHash(password, salt: email)
        let params = ["email":email, "clientPasswordHash" : hashPassword, "action" : "checkPassword"]
        let request = NSMutableURLRequest(URL: NSURL(string: "https://mobile-api.vaavud.com/api/password")!)
        request.HTTPMethod = "POST"
        
        do {
            try request.HTTPBody = NSJSONSerialization.dataWithJSONObject(params, options: [])
        }
        catch {
        }
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
            data, response, error in
            
            if error != nil {
                self.delegate?.onError(.Network)
                return
            }
            
            do {
                let responseObject = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as? NSDictionary
                print(responseObject)
                
                guard let result = responseObject!["status"] as? String else {
                    self.delegate?.onError(.Network)
                    return
                }
                   
                if result == "CORRECT_PASSWORD" {
                    let oldPassword =  email + "\(responseObject!["user_id"] as! NSNumber)"
                    print(oldPassword)
                        
                    self.firebase.changePasswordForUser(email, fromOld: oldPassword, toNew: password, withCompletionBlock: {error in
                        guard let error = error else {
                            print("Login correct with new password")
                            self.login(email, password: password, delegate: self.delegate!)
                            return
                        }
                        
                        self.delegate?.onError(.MalformedInformation)
                        print(error)
                    })
                }
                else {
                    self.delegate?.onError(.MalformedInformation)
                }
            }
            catch {
                fatalError()
            }
        }
        task.resume()
    }
    
    private func authWithFacebook(accessToken : String, callback: (Bool, String) -> Void) {
        firebase.authWithOAuthProvider("facebook", token: accessToken) { error, authData in
            guard let error = error else {
                callback(true, authData.uid)
                print("Logged in! \(authData.uid)")
                return
            }
            
            print("Login failed. \(error)")
            callback(false, "")
        }
    }
    
    // MARK - Static convenience methods
    
    class var deviceModel: String {
        var sysInfo: [CChar] = Array(count: sizeof(utsname), repeatedValue: 0)
        
        // We need to get to the underlying memory of the array:
        let machine = sysInfo.withUnsafeMutableBufferPointer {
            (inout ptr: UnsafeMutableBufferPointer<CChar>) -> String in
            uname(UnsafeMutablePointer<utsname>(ptr.baseAddress))
            let machinePtr = ptr.baseAddress.advancedBy(Int(_SYS_NAMELEN * 4))
            
            // Create a Swift string from the C string
            return String.fromCString(machinePtr)!
        }
        return machine
    }
    
    static var deviceIsIphone4: Bool {
        return deviceModel.hasPrefix("iPhone3")
    }
}
