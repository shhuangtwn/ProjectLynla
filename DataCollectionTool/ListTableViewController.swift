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
import Haneke

class ListTableViewController: UITableViewController {
    
    // ContainerViewController.sharedInstance.items //
    var items = [ItemModel]()
    var userUID: String = ""
    var ratedItems: Int = 0
    var totalTexturePoints: Double = 0.0
    var totalFlavorPoints: Double = 0.0
    
    var sendingBarode: String = ""
    var sendingItemImageURL = NSURL()
    var sendingLogoText: String = ""
    var sendingMatchingStatus: Int = 2
    var sendingItemUID: String = ""
    var sendingPoints: Double = 3.0
    var sendingTexture: Double = 3.0
    var sendingFlavor: Double = 3.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set UI
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ListTableViewController.loadList(_:)),name:"reloadList", object: nil)
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: "loadList",name:"reloadList", object: nil)
//        self.navigationController?.navigationBar.backgroundColor = UIColor(red: 239.0/255.0, green: 62.0/255.0, blue: 54.0/255.0, alpha: 1.0)

        tableView.separatorStyle = .None        
        
    }
    
    func loadList(notification: NSNotification){
        //load data here
        self.tableView.reloadData()
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return items.count
        
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let rowIndex = indexPath.row
        
        sendingBarode = items[rowIndex].barcode
        sendingItemImageURL = items[rowIndex].imageURL
        sendingLogoText = items[rowIndex].name
        sendingItemUID = items[rowIndex].itemUID
        sendingPoints = items[rowIndex].itemPT
        sendingTexture = items[rowIndex].itemTX
        sendingFlavor = items[rowIndex].itemFL
        
        performSegueWithIdentifier("modalSegueToItem", sender: nil)
        
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
        let cellIdentifier = "Cell"
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier,forIndexPath: indexPath) as! ListTableViewCell
        
        cell.itemImageView.image = nil
        //UIImage(named: "beerIcon")
        
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = self.tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! ListTableViewCell
        let item = items[indexPath.row]
        
        let fl = item.itemFL
        let tx = item.itemTX
        var flString: String = ""
        var txString: String = ""
        
        if fl < 3.0 {
            flString = "Sweet"
        } else if fl > 3.0 {
            flString = "Bitter"
        } else {
            flString = "Medium"
        }
        
        if tx < 3.0 {
            txString = "Smooth"
        } else if tx > 3.0 {
            txString = "Thick"
        } else {
            txString = "Normal"
        }
        
        cell.nameLabel.text = item.name
        cell.barcodeLabel.text = item.barcode
        cell.itemPoint.text = "\(String(Int(item.itemPT))) stars"
        cell.itemTexture.text = txString
        cell.itemFlavor.text = flString
        cell.itemImageView.hnk_setImageFromURL(item.imageURL)
        
        return cell
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "modalSegueToItem" {
            
            let destinationViewController = segue.destinationViewController as! PresentItemViewController;
            destinationViewController.receivedItemImageURL = sendingItemImageURL
            destinationViewController.receivedBarCode = sendingBarode
            destinationViewController.receivedItemUID = sendingItemUID
            destinationViewController.receivedLogoText = sendingLogoText
            
            destinationViewController.ratedPoints = sendingPoints
            destinationViewController.ratedTexture = sendingTexture
            destinationViewController.ratedFlavor = sendingFlavor
            
            destinationViewController.receivedMatchingStatus = sendingMatchingStatus
            
        }
        
    }
    
}
