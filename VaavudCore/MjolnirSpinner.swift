//
//  MjolnirSpinner.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 27/04/15.
//  Copyright (c) 2015 Andreas Okholm. All rights reserved.
//

import UIKit

class MjolnirSpinner: UIView {
    let imageView = UIImageView()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    func setup() {
        imageView.alpha = 0
        imageView.animationDuration = 0.5*35/30
        var images = [UIImage]()
        
        for i in 1...35 {
            let name = String(format: "MjolnirSpinner%03d", i)
            images.append(UIImage(named: name)!)
        }
        
        imageView.image = images.first
        imageView.sizeToFit()
        
        imageView.animationImages = images
        imageView.center = CGPoint(x: bounds.midX, y: bounds.midY)

        addSubview(imageView)
    }
    
    func show() {
        imageView.alpha = 1
        imageView.startAnimating()
    }
    
    func hide() {
        imageView.alpha = 0
        imageView.stopAnimating()
    }
}