//
//  RoundedField.swift
//  Vaavud
//
//  Created by Diego R on 11/26/15.
//  Copyright © 2015 Andreas Okholm. All rights reserved.
//

import UIKit

class RoundedField: UITextField {
    @IBInspectable var filled: Bool = true
    @IBInspectable var color: UIColor = UIColor.whiteColor()
    
    let padding: CGFloat = 5
    
    func setup() {
        let attributes = [NSForegroundColorAttributeName : color.colorWithAlphaComponent(0.5)]
        attributedPlaceholder = NSAttributedString(string: placeholder ?? "", attributes: attributes)
    }
    
    override func textRectForBounds(bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: padding, dy: 0)
    }
    
    override func editingRectForBounds(bounds: CGRect) -> CGRect {
        return textRectForBounds(bounds)
    }
    
    override func placeholderRectForBounds(bounds: CGRect) -> CGRect {
        return textRectForBounds(bounds)
    }
}
