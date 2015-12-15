//
//  LoginBusinessController.swift
//  Vaavud
//
//  Created by Diego R on 11/20/15.
//  Copyright © 2015 Andreas Okholm. All rights reserved.
//

import UIKit
import Firebase

enum LoginError: String {
    case Network = "LOGIN_ERROR_NETWORK"
    case MalformedInformation = "1"
    case WrongInformation = "2"
    case Facebook = "3"
    case EmailTaken = "4"
    case Unknown = "5"
}

protocol LoginDelegate {
    func onSuccess(showActivitySelector: Bool)
    func onError(error: LoginError)
}

class AuthorizationController: NSObject {
    private let firebaseUrl = "https://vaavud-core-demo.firebaseio.com"
    private var vaavudRootFirebase: Firebase
    var delegate: LoginDelegate?
    var uid: String?
    private var _deviceId: String?
    var deviceId: String { if _deviceId != nil { return _deviceId! } else { fatalError("No device id") } }
    
   static let shared = AuthorizationController()

    private override init() {
        vaavudRootFirebase = Firebase(url: firebaseUrl)
    }
    
    func verifyAuth() -> Bool {
        if _deviceId != nil && uid != nil {
            return true
        }
        
        let preferences = NSUserDefaults.standardUserDefaults()
        
        guard let deviceId = preferences.objectForKey("deviceId") as? String, authData = vaavudRootFirebase.authData  else {
            unauth()
            return false
        }
        
    
        
        uid = authData.uid
        _deviceId = deviceId
        
        return true
    }
    
    func unauth(){
        NSUserDefaults.standardUserDefaults().removeObjectForKey("deviceId")
        vaavudRootFirebase.unauth()
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
        
        vaavudRootFirebase.authUser(email, password: password) { error, authData in
            if let error = error {
                if error.code == -6 {
                    self.verifyMigration(email, password: password)
                }
                else {
                    print(error)
                    //self.delegate?.onError("Login error", message: "Your information is not correct")
                }
                return
            }
            
            self.obtainUserInformation("user", key: authData.uid)
        }
    }
    
    private func obtainUserInformation(child: String, key: String) {
        let ref = vaavudRootFirebase.childByAppendingPath(child).childByAppendingPath(key)
        ref.observeSingleEventOfType(.Value, withBlock: { data in
            guard let firebaseData = data.value as? FirebaseDictionary else {
                //self.delegate?.onError("data error", message: "")
                return
            }
            
            self.updateUserInformation(data.key, data: firebaseData)
        })
    }
    
    func signup(firstName: String, lastName: String, email: String, password: String, delegate: LoginDelegate){
        self.delegate = delegate
        let newUserModel = User(dict: ["firstName": firstName, "lastName": lastName, "country": "DK", "language": "EN", "email": email, "created": 812739 ]) //TODO
        
        vaavudRootFirebase.createUser(email, password: password, withValueCompletionBlock: { error, authData in
            guard let _ = authData else {
                //self.delegate?.onError("Signup error", message: "This email is already used")
                return
            }
            
            self.vaavudRootFirebase.authUser(email, password: password) { error, authData in
                if let error = error {
                    if error.code == -6 {
                        self.verifyMigration(email, password: password)
                    }
                    else {
                        print(error)
                        //self.delegate?.onError("", message: "Created user, but it couldnt loging")
                    }
                    return
                }
                
                guard let model = newUserModel?.dict else {
                    fatalError()
                }
                
                self.vaavudRootFirebase.childByAppendingPath("user").childByAppendingPath(authData.uid).setValue(model)
                self.updateUserInformation(authData.uid, data: model)
            }
        })
    }
    
    func loginWithFacebook(delegate: LoginDelegate){
        self.delegate = delegate
    
        let graphRequest  = FBSDKGraphRequest(graphPath: "me", parameters:["fields" : "first_name, last_name, picture.type(large), email, name, id, gender"])
        graphRequest.startWithCompletionHandler{ (connection, result, error) in
            
            if error != nil{
                //self.delegate?.onError("Facebook error", message: "There was an error with facebook")
                return
            }
            
            let token = FBSDKAccessToken.currentAccessToken().tokenString
            let firstName = result.valueForKey("first_name") as! String
            let lastName = result.valueForKey("last_name") as! String
            let email = result.valueForKey("email") as! String
            let created = NSDate().timeIntervalSince1970 * 1000
                
            let callback = { (success: Bool, uid: String) in
                if success {
                    let userModel = User(dict: ["firstName": firstName, "lastName": lastName, "country": "DK", "language": "EN", "email": email, "created": created ])
                    
                    guard let model = userModel?.dict else {
                        fatalError()
                    }
                    
                    self.validateUserInformation(uid, userModel: model)
                }
                else {
                //.self.delegate?.onError("Login", message: "We couldnt get your information")
                }
            }
            self.authWithFacebook(token, callback: callback)
        }
    }
    
    
    func updateActivity(activity: String){
        let param = ["activity" : activity]
        vaavudRootFirebase.childByAppendingPath("user").childByAppendingPath(uid).updateChildValues(param)
    }
    
    private func validateUserInformation(uid: String, userModel: FirebaseDictionary) {
        let callback = { (data: FirebaseDictionary?) in
            if let data = data {
                self.updateUserInformation(uid, data: data)
            }
            else{
                self.vaavudRootFirebase.childByAppendingPath("user").childByAppendingPath(uid).setValue(userModel)
                self.updateUserInformation(uid, data: userModel)
            }
        }
        
        obtainUserInformation("user", key: uid, callback: callback)
    }
    
    private func obtainUserInformation(child: String, key: String, callback: FirebaseDictionary -> Void) {
        let ref = vaavudRootFirebase.childByAppendingPath(child).childByAppendingPath(key)
        ref.observeSingleEventOfType(.Value, withBlock: { data in
            guard let firebaseData = data.value as? FirebaseDictionary else {
                //self.delegate?.onError("data error", message: "")
                return
            }
            
            callback(firebaseData)
        })
    }

    private func updateUserInformation(uid: String, data: FirebaseDictionary) {
        let deviceObj = Device(dict: ["appVersion": "0.0.0", "model": "Iphone 3gs", "vendor": "Apple", "osVersion": "9.0", "uid": uid])
        
        guard let model = deviceObj?.dict else {
            fatalError("Bad data from Firebase")
        }
            
        let ref = self.vaavudRootFirebase.childByAppendingPath("device")
        let post = ref.childByAutoId()
        post.setValue(model)
        let deviceId = post.key
            
        let preferences = NSUserDefaults.standardUserDefaults()
        preferences.setValue(deviceId, forKey: "deviceId")
        preferences.synchronize()
        
        print(deviceId)
        print(data)
            
        self.uid = uid
        self._deviceId = deviceId
        
        delegate?.onSuccess(data["activity"] is String)
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
                //self.delegate?.onError("Network Error", message: "Verify your information.")
                return
            }
            
            do {
                let responseObject = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as? NSDictionary
                print(responseObject)
                
                guard let result = responseObject!["status"] as? String else {
                    //self.delegate?.onError("Network Error", message: "There was an error, try again.")
                    return
                }
                   
                if result == "CORRECT_PASSWORD" {
                    let oldPassword =  email + "\(responseObject!["user_id"] as! NSNumber)"
                    print(oldPassword)
                        
                    self.vaavudRootFirebase.changePasswordForUser(email, fromOld: oldPassword, toNew: password, withCompletionBlock: {error in
                        guard let error = error else {
                            print("Login correct with new password")
                            self.login(email, password: password, delegate: self.delegate!)
                            return
                        }
                        
                        //self.delegate?.onError("Authentication Error", message: "Your password is incorrect, try forgot password.")
                        print(error)
                    })
                }
                else {
                    //self.delegate?.onError("Authentication Error", message: "Your password is incorrect, try forgot password.")
                }
            }
            catch {
                fatalError()
            }
        }
        task.resume()
    }
    
    
    private func authWithFacebook(accessToken : String, callback: (Bool, String) -> Void){
        vaavudRootFirebase.authWithOAuthProvider("facebook", token: accessToken) { error, authData in
            
            guard let error = error else {
                callback(true, authData.uid)
                print("Logged in! \(authData.uid)")
                return
            }
            
            print("Login failed. \(error)")
            callback(false, "")
        }
    }
}
