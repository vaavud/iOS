//
//  HistoryCellController.swift
//  Vaavud
//
//  Created by Diego R on 12/4/15.
//  Copyright © 2015 Andreas Okholm. All rights reserved.
//

import UIKit

class HistoryCell: UITableViewCell {
    
    
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var location: UILabel!
    @IBOutlet weak var speed: UILabel!
    @IBOutlet weak var speedUnit: UILabel!
    @IBOutlet weak var directionUnit: UILabel!
    @IBOutlet weak var directionArrow: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
}
