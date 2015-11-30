//
//  Device.swift
//  Vaavud
//
//  Created by Diego R on 11/20/15.
//  Copyright © 2015 Andreas Okholm. All rights reserved.
//

import UIKit

struct Device {
    
    let appVersion: String
    let model: String
    let vendor: String
    let osVersion: String
    let uid: String
    
    init? (dict: FirebaseDictionary){
        guard let appVersion = dict["appVersion"] as? String, model = dict["model"] as? String, vendor = dict["vendor"] as? String, osVersion = dict["osVersion"] as? String, uid = dict["uid"] as? String else {
            return nil
        }
        
        self.appVersion = appVersion
        self.model = model
        self.vendor = vendor
        self.osVersion = osVersion
        self.uid = uid
    }
    
    var dict : FirebaseDictionary {
        return ["appVersion": appVersion, "model": model, "vendor": vendor, "osVersion": osVersion, "uid": uid]
    }


}
