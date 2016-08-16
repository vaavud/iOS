//
//  LoginWallView.swift
//  Vaavud
//
//  Created by Diego Galindo on 8/9/16.
//  Copyright © 2016 Andreas Okholm. All rights reserved.
//

import UIKit

class LoginWallView: UIView {
    
    
    var callback: (() -> ())?
    var isMap = true
    
    
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var descrip: UILabel!
    @IBOutlet weak var btnLogin: UIButton!
    @IBOutlet weak var background: UIImageView!
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    func setUp() {
        
        btnLogin.layer.cornerRadius = 5
        btnLogin.layer.borderWidth = 1
        
        if isMap {
            title.text = "Live Map"
            descrip.text = "To see wind readings from users around the world for the last 24 hours you need to log in"
            icon.image =  UIImage(named: "MapWallIcon")
            background.image = UIImage(named: "mapWallBg")
            
        }
        else {
            title.text = "Measurement History"
            descrip.text = "To save measurements to your personal measurement history you need to log in"
            icon.image =  UIImage(named: "HistoryWallIcon")
            
            background.image = UIImage(named: "historyWallBg")
        }
        
    }
    
    
    @IBAction func onLogin(sender: UIButton) {
        callback?()
    }

}
