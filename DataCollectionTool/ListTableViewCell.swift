//
//  ListTableViewCell.swift
//  DataCollectionTool
//
//  Created by Bryan Huang on 2016/10/6.
//  Copyright © 2016年 Steven Hunag. All rights reserved.
//

import UIKit

class ListTableViewCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var barcodeLabel: UILabel!
    @IBOutlet weak var itemImageView: UIImageView!
    @IBOutlet weak var itemPoint: UILabel!
    @IBOutlet weak var itemTexture: UILabel!
    @IBOutlet weak var itemFlavor: UILabel!
    @IBOutlet weak var itemRecordDate: UILabel!
    @IBOutlet weak var cardBGLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.cardBGLabel.layer.shadowColor = UIColor.blackColor().CGColor
        self.cardBGLabel.layer.shadowOpacity = 0.5
        self.cardBGLabel.layer.shadowOffset = CGSizeMake(0.0, 2.0)
        self.cardBGLabel.layer.shadowRadius = 2.5
//        let path = UIBezierPath(roundedRect: cardBGLabel.bounds, cornerRadius: 3)
//        self.cardBGLabel.layer.shadowPath = path.CGPath

    }
    
}
