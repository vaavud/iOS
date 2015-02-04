//
//  VaavudInteractions.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 03/02/15.
//  Copyright (c) 2015 Andreas Okholm. All rights reserved.
//

import Foundation

class VaavudInteractions {
    class func openBuySleipnir() {
        UIApplication.sharedApplication().openURL(NSURL(string: "http://vaavud.com/product/vaavud-sleipnir")!)
    }
}
