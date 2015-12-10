//
//  LoginBusinessController.swift
//  Vaavud
//
//  Created by Diego R on 11/20/15.
//  Copyright © 2015 Andreas Okholm. All rights reserved.
//

import UIKit
import Firebase


protocol LoginCoreDelegate {
    func onSuccess()
    func onError(titie: String, message: String)
    func missingActivity()
}


class AuthorizationController {
    
    private let firebaseUrl = "https://vaavud-core-demo.firebaseio.com"
    private let vaavudRootFirebase : Firebase
    var delegate: LoginCoreDelegate?
    var uid: String?
    private var _deviceId: String?
    var deviceId: String { if _deviceId != nil{ return _deviceId! } else{ fatalError("No device id") } }
    
   static let shared = AuthorizationController()
    
    private init() {
        vaavudRootFirebase = Firebase(url: firebaseUrl)
    }
    
    func verifyAuth() -> Bool {
        if _deviceId != nil && uid != nil {
            return true
        }
        
        let preferences = NSUserDefaults.standardUserDefaults()
        guard let uidKey = vaavudRootFirebase.authData.uid, deviceId = preferences.objectForKey("deviceId") as? String else {
            return false
        }
        
        self.uid = uidKey
        _deviceId = deviceId
        
        return true
    }
    
    
    func login(email: String, password: String, delegate: LoginCoreDelegate){
        
        self.delegate = delegate
        
        let callback = { (success: Bool, uid: String) in
            if success {
                self.getUserInformation("user", key: uid,callback: nil)
            }
            else{
                self.delegate?.onError("Login error", message: "Your information is not correct")
            }
        }
        authWithEmail(email, password: password, callback: callback)
    }
    
    
    func signup(firstName: String, lastName: String, email: String, password: String, delegate: LoginCoreDelegate){
        self.delegate = delegate
        let newUserModel = User(dict: ["firstName": firstName, "lastName": lastName, "country": "DK", "language": "EN", "email": email, "created": 81273981273 ]) //TODO
        
        vaavudRootFirebase.createUser(email, password: password, withValueCompletionBlock: { error, authData in
            
            guard let _ = authData else {
                self.delegate?.onError("Signup error", message: "This email is already used")
                return
            }
            
            let callback = { (success: Bool, uid: String) in
                if success {
                    
                    guard let model = newUserModel?.dict else {
                        fatalError()
                    }
                    
                    self.vaavudRootFirebase.childByAppendingPath("user").childByAppendingPath(uid).setValue(model)
                    self.userInformation(uid,data: model)
                }
                else{
                    fatalError("Created user, but it couldnt loging")
                }
            }
                
            self.authWithEmail(email, password: password, callback: callback)
        })
    }
    
    func loginWithFacebook(delegate: LoginCoreDelegate){
        
        self.delegate = delegate
    
        let graphRequest  = FBSDKGraphRequest(graphPath: "me", parameters:["fields" : "first_name, last_name, picture.type(large), email, name, id, gender"])
        graphRequest.startWithCompletionHandler{ (connection, result, error) in
            
            if error != nil{
                self.delegate?.onError("Facebook error", message: "There was an error with facebook")
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
                    
                    self.validateUserInformation(uid,userModel: model)
                }
                else{
                    self.delegate?.onError("Login", message: "We couldnt get your information")
                }
            }
            self.authWithFacebook(token, callback: callback)
        }
    }
    
    
    func updateActivity(activity: String){
        
        let param = ["activity":activity]
        vaavudRootFirebase.childByAppendingPath("user").childByAppendingPath(uid).updateChildValues(param)
    }
    
    
    private func validateUserInformation(uid: String, userModel: FirebaseDictionary){
        let callback = { (data: FirebaseDictionary?) in
            
            if let d = data {
                self.userInformation(uid, data: d)
            }
            else{
                self.vaavudRootFirebase.childByAppendingPath("user").childByAppendingPath(uid).setValue(userModel)
                self.userInformation(uid, data: userModel)
            }
        }
        
        getUserInformation("user", key: uid, callback: callback)
    }
    
    
    private func userInformation(uid: String, data: FirebaseDictionary ){
        let deviceObj = Device(dict: ["appVersion": "0.0.0", "model": "Iphone 3gs", "vendor": "Apple",  "osVersion": "9.0","uid": uid])
        
        guard let model = deviceObj?.dict else {
            fatalError("Bad data from Firebase")
        }
            
        let ref = self.vaavudRootFirebase.childByAppendingPath("device")
        let post = ref.childByAutoId()
        post.setValue(model)
        let deviceId = post.key
            
            
//           let preferences = NSUserDefaults.standardUserDefaults()
//            preferences.setValue(uid, forKey: "uid")
//            preferences.setValue(data["email"], forKey: "email")
//            preferences.setValue(deviceId, forKey: "device")
//            preferences.synchronize()
            
        print(deviceId)
        print(data)
            
        self.uid = uid
        self._deviceId = deviceId
            
        guard let _ = data["activity"] as? String else{
            self.delegate?.missingActivity()
            return
        }
            
        self.delegate?.onSuccess()
    }
    
    private func authWithEmail(user: String, password: String, callback: (Bool,String)->Void){
        vaavudRootFirebase.authUser(user, password: password) {
            error, authData in
            
            guard let error = error else {
                callback(true, authData.uid)
                return
            }
            
            if error.code == -6 {
                self.verifyMigration(user,password: password)
            }
            else{
                print(error)
                callback(false, "")
            }
        }
    }
    
    
    private func verifyMigration(email: String, password: String){
        
        let hashPassword = PasswordUtil.createHash(password, salt: email)
        let params = ["email":email, "clientPasswordHash":hashPassword, "action": "checkPassword"]
        let request = NSMutableURLRequest(URL: NSURL(string: "https://mobile-api.vaavud.com/api/password")!)
        request.HTTPMethod = "POST"
        
        do {
            try request.HTTPBody = NSJSONSerialization.dataWithJSONObject(params, options: [])
        }
        catch{
        }
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
            data, response, error in
            
            if error != nil {
                self.delegate?.onError("Network Error", message: "Verify your information.")
                return
            }
            
            do{
                let responseObject = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as? NSDictionary
                print(responseObject)
                
                guard let result = responseObject!["status"] as? String else {
                    self.delegate?.onError("Network Error", message: "There was an error, try again.")
                    return
                }
                   
                if result == "CORRECT_PASSWORD" {
                    
                    let oldPassword =  email + "\(responseObject!["user_id"] as! NSNumber)"
                    print(oldPassword)
                        
                    self.vaavudRootFirebase.changePasswordForUser(email, fromOld: oldPassword, toNew: password, withCompletionBlock: {error in
                        
                        guard let error = error else {
                            print("Login correct with new password")
                            self.login(email,password: password,delegate: self.delegate!)
                            return
                        }
                        
                        self.delegate?.onError("Authentication Error", message: "Your password is incorrect, try forgot password.")
                        print(error)
                    })
                }
                else {
                    self.delegate?.onError("Authentication Error", message: "Your password is incorrect, try forgot password.")
                }
            }
            catch{
                fatalError()
            }
        }
        task.resume()
    }
    
    
    private func authWithFacebook(accessToken : String, callback: (Bool, String) -> Void){
        vaavudRootFirebase.authWithOAuthProvider("facebook", token: accessToken, withCompletionBlock: { error, authData in
            
            guard let error = error else {
                callback(true,authData.uid)
                print("Logged in! \(authData.uid)")
                return
            }
            
            print("Login failed. \(error)")
            callback(false,"")
        })
    }
    
    private func getUserInformation(child : String, key : String, callback: ((FirebaseDictionary?)->Void)?) {
        let ref = vaavudRootFirebase.childByAppendingPath(child).childByAppendingPath(key)
        ref.observeSingleEventOfType(.Value, withBlock: { data in
            if let callback = callback {
                callback(data.value as? FirebaseDictionary)
            }
            else{
                if let dataFirebase = data.value as? FirebaseDictionary{
                    self.userInformation(data.key, data: dataFirebase)
                }
            }
        })
    }
}
