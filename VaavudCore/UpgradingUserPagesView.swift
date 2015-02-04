//
//  UpgradingUserPagesView.swift
//  Vaavud
//
//  Created by Gustaf Kugelberg on 29/01/15.
//  Copyright (c) 2015 Andreas Okholm. All rights reserved.
//

import UIKit

class UpgradingUserPagesView: UIView {
    // <--- Should be taken care of in storyboard
    @IBOutlet weak var heading0: UILabel!
    @IBOutlet weak var heading1: UILabel!
    
    @IBOutlet weak var label0: UILabel!
    @IBOutlet weak var label1: UILabel!
    @IBOutlet weak var button: UIButton!
    // Should be taken care of in storyboard --->
    
    weak var owner: UpgradingUserViewController!
    
    func localize() {
        heading0.text = NSLocalizedString("INTRO_UPGRADE_WHATS_NEW", comment: "")
        heading1.text = NSLocalizedString("INTRO_UPGRADE_WHATS_NEW", comment: "")
        
        label0.text = NSLocalizedString("INTRO_UPGRADE_TEXT0", comment: "")
        label1.text = NSLocalizedString("INTRO_UPGRADE_TEXT1", comment: "")
        button.setTitle(NSLocalizedString("INTRO_UPGRADE_CTA_BUY", comment: ""), forState: .Normal)
    }
    
    @IBAction func tappedBuy() {
        owner.openBuyDevice()
    }
}
