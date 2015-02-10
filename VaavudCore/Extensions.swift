//
//  Extensions.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 10/02/15.
//  Copyright (c) 2015 Andreas Okholm. All rights reserved.
//

import Foundation
import MediaPlayer

extension UIViewController {
    func hideVolumeHUD() {
        view.addSubview(MPVolumeView(frame: CGRect(x: -1000, y: -1000, width: 100, height: 100)))
    }
}
