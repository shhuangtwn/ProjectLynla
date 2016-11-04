//
//  ItemDataModel.swift
//  DataCollectionTool
//
//  Created by Bryan Huang on 2016/10/7.
//  Copyright © 2016年 Steven Hunag. All rights reserved.
//

import UIKit

class ItemModel {
    var name: String
    var barcode: String
    var imageURL: NSURL
    var itemPT: Double
    var itemTX: Double
    var itemFL: Double
    var itemUID: String
    
    init(name: String, barcode: String, imageURL: NSURL, itemPT: Double, itemTX: Double, itemFL: Double, itemUID: String) {
    
        self.name = name
        self.barcode = barcode
        self.imageURL = imageURL
        self.itemPT = itemPT
        self.itemTX = itemTX
        self.itemFL = itemFL
        self.itemUID = itemUID
        
    }
    
}
