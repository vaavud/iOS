//
//  User.swift
//  samplePush
//
//  Created by Diego R on 11/13/15.
//  Copyright © 2015 Diego R Galindo. All rights reserved.
//

//
//  Device.swift
//  Vaavud
//
//  Created by Diego R on 11/20/15.
//  Copyright © 2015 Andreas Okholm. All rights reserved.
//

import UIKit
import VaavudSDK


typealias FirebaseDictionary = [String:AnyObject]

struct Device {
    let appVersion: String
    let model: String
    let vendor: String
    let osVersion: String
    let uid: String
    let created = [".sv": "timestamp"]
    
//    init?(dict: FirebaseDictionary) {
//        guard let appVersion = dict["appVersion"] as? String,
//            model = dict["model"] as? String,
//            vendor = dict["vendor"] as? String,
//            osVersion = dict["osVersion"] as? String,
//            uid = dict["uid"] as? String
//            else {
//                return nil
//        }
//        
//        self.appVersion = appVersion
//        self.model = model
//        self.vendor = vendor
//        self.osVersion = osVersion
//        self.uid = uid
//    }
    
    var fireDict : FirebaseDictionary {
        return ["appVersion" : appVersion, "model" : model, "vendor" : vendor, "osVersion" : osVersion, "uid" : uid, "created" : created]
    }
}

struct User {
    let firstName: String
    let lastName: String
    let country: String
    let language: String
    let email: String
    let created = [".sv": "timestamp"]
    
//    init?(dict: FirebaseDictionary) {
//        guard let firstName = dict["firstName"] as? String,
//            lastName = dict["lastName"] as? String,
//            country = dict["country"] as? String,
//            language = dict["language"] as? String,
//            email = dict["email"] as? String,
//            created = dict["created"] as? Double
//            else {
//                return nil
//        }
//        
//        self.firstName = firstName
//        self.lastName = lastName
//        self.country = country
//        self.language = language
//        self.email = email
//        self.created = created
//        
//        self.activity = dict["activity"] as? String
//    }
    
    var fireDict: FirebaseDictionary {
        let dict: FirebaseDictionary = ["firstName" : firstName, "lastName" : lastName, "country" : country, "language" : language, "email" : email, "created" : created]
        return dict
    }
}