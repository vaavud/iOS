//
//  User.swift
//  samplePush
//
//  Created by Diego R on 11/13/15.
//  Copyright © 2015 Diego R Galindo. All rights reserved.
//

import UIKit

struct User {
    
    let firstName : String
    let lastName : String
    let country : String
    let language : String
    let email : String
    let created : Double
    var activity : String?
    
    
    init? (dict: FirebaseDictionary){
        guard let firstName = dict["firstName"] as? String, lastName = dict["lastName"] as? String, country = dict["country"] as? String, language = dict["language"] as? String, email = dict["email"] as? String, created = dict["created"] as? Double  else {
            return nil
        }
        
        if let activity = dict["activity"] as? String {
            self.activity = activity
        }
        
        self.firstName = firstName
        self.lastName = lastName
        self.country = country
        self.language = language
        self.email = email
        self.created = created
    }
    
    var dict : FirebaseDictionary {
        return ["firstName": firstName, "lastName": lastName, "country": country, "language": language, "email": email, "created": created ]
    }
}