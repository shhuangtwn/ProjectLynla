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

class ListTableViewController: UITableViewController {
    
    var items = [ItemModel]()
    var userUID: String = ""
    var ratedItems: Int = 0
    var totalTexturePoints: Double = 0.0
    var totalFlavorPoints: Double = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.hidden = false
        
        getUserKey()
        fetchItems()
        
        
    }
    
    func fetchItems() {
        
        let database = FIRDatabase.database().reference()
        
        // Get user drank items
        database.child("user_feedbacks").queryOrderedByChild("user_uid").queryEqualToValue(userUID).observeEventType(.ChildAdded , withBlock: { snapshot in
            
//            print(snapshot.value)
            
            guard
                let itemUID = snapshot.value!["item_uid"] as? String,
                let itemPT = snapshot.value!["points"] as? Double,
                let itemTX = snapshot.value!["texture_points"] as? Double,
                let itemFL = snapshot.value!["flavor_points"] as? Double,
                let itemIMG = snapshot.value!["user_taken_image"] as? String
                else {return}
            
//            print(itemUID)
//            print(itemPT)
//            print(itemTX)
//            print(itemFL)
//            print(itemIMG)
            
            
            
            // Get each item details
            database.child("items").child(itemUID).observeSingleEventOfType(.Value , withBlock: { snapshot in
    
                print(snapshot)
                
                guard let name = snapshot.value!["name"] as? String else {return}
                let imageURL = NSURL(string: itemIMG)
//                let imageData = NSData(contentsOfURL: imageURL!)
                
                print("in name?:\(name)")
                
                //Firebase was written in async
                database.child("barcodes").queryOrderedByValue().queryEqualToValue(itemUID).observeSingleEventOfType(.ChildAdded, withBlock: { snapshot in
                    
                    let barcode = snapshot.key
                    
                    print(barcode)
                    print("-----------------------------")
                    
                    let item = ItemModel(name: name, barcode: barcode, imageURL: imageURL!, itemPT: itemPT, itemTX: itemTX, itemFL: itemFL)
                    self.items.append(item)
                
                    self.totalTexturePoints = self.totalTexturePoints + itemTX
                    self.totalFlavorPoints = self.totalFlavorPoints + itemFL
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        
                        self.ratedItems = self.items.count
                        self.tableView.reloadData()
                        self.uploadAverageData(self.ratedItems, ttlTX: self.totalTexturePoints, ttlFL: self.totalFlavorPoints)

                    })
                    
                })
                
            })
            
        })
        
    }
    
        
    func getUserKey() {
        if let user = FIRAuth.auth()?.currentUser {
            //            let name = user.displayName
            //            let email = user.email
            //            let photoUrl = user.photoURL
            self.userUID = user.uid;  // The user's ID, unique to the Firebase project.
            // Do NOT use this value to authenticate with
            // your backend server, if you have one. Use
            // getTokenWithCompletion:completion: instead.
        } else {
            // No user is signed in.
            self.userUID = "user UID missing"
        }
    }
    
    func uploadAverageData(ttlRated: Int, ttlTX: Double, ttlFL: Double) {
    
        let avgTX = ttlTX / Double(ttlRated)
        let avgFL = ttlFL / Double(ttlRated)
        
        let databaseRef = FIRDatabase.database().reference()
        let postCalculatedRef = databaseRef.child("users").child(userUID)
        
        let postCalculatedData: [String: AnyObject] = [
            "total_items": ttlRated,
            "avg_texture": avgTX,
            "avg_flavor": avgFL
            ]
        
        postCalculatedRef.setValue(postCalculatedData)
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
