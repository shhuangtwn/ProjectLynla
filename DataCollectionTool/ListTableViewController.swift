//
//  ListTableViewController.swift
//  DataCollectionTool
//
//  Created by Bryan Huang on 2016/10/6.
//  Copyright © 2016年 Steven Hunag. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import SwiftCharts

class ListTableViewController: UITableViewController {
    
    // ContainerViewController.sharedInstance.items //
    var items = [ItemModel]()
    var userUID: String = ""
    var ratedItems: Int = 0
    var totalTexturePoints: Double = 0.0
    var totalFlavorPoints: Double = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set UI
        self.navigationController?.navigationBar.hidden = false
     
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ListTableViewController.loadList(_:)),name:"reloadList", object: nil)
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: "loadList",name:"reloadList", object: nil)

    }
    
    func loadList(notification: NSNotification){
        //load data here
        self.tableView.reloadData()
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return items.count
        
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = self.tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! ListTableViewCell
        let item = items[indexPath.row]
        
        cell.nameLabel.text = item.name
        cell.barcodeLabel.text = item.barcode
        cell.itemPoint.text = "PT: \(String(item.itemPT))"
        cell.itemTexture.text = "TX: \(String(item.itemTX))"
        cell.itemFlavor.text = "FL: \(String(item.itemFL))"
                
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            
            if let imageData =  NSData(contentsOfURL: item.imageURL) {
                dispatch_async(dispatch_get_main_queue(), {
                    cell.itemImageView.image = UIImage(data: imageData)
                })
            }
        }
        return cell
    }
    
}
