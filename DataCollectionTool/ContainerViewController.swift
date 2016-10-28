//
//  ContainerViewController.swift
//  DataCollectionTool
//
//  Created by Bryan Huang on 2016/10/23.
//  Copyright © 2016年 freelance. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth

class ContainerViewController: UIViewController {

    @IBOutlet weak var containerProfile: UIView!
    @IBOutlet weak var containerList: UIView!
    
    var items = [ItemModel]()
    
    var destinationListVC = ListTableViewController()
    var destinationProfileVC = ProfileViewController()
    
    var userUID: String = ""
    var ratedItems: Int = 0
    var totalTexturePoints: Double = 0.0
    var totalFlavorPoints: Double = 0.0
    
    enum ViewSwitch: Int {
        case profile = 0
        case list = 1
    }
    
    enum TasteType {
    
        case sweetAndSmooth
        case sweetAndThick
        case bitterAndSmooth
        case bitterAndThick
        
    }
    
    @IBAction func viewSwitcher(sender: UISegmentedControl) {
    
        let currentContainer = ViewSwitch(rawValue: sender.selectedSegmentIndex)!
    
        switch currentContainer {
        case .profile:
            containerProfile.alpha = 1
            containerList.alpha = 0
            
        case .list:
            containerProfile.alpha = 0
            containerList.alpha = 1
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        getUserKey()
        fetchItems()
    
    }

    func fetchItems() {
        
        let database = FIRDatabase.database().reference()
        
        // Get user drank items
        database.child("user_feedbacks").queryOrderedByChild("user_uid").queryEqualToValue(userUID).observeEventType(.ChildAdded , withBlock: { snapshot in
            
            guard
                let itemUID = snapshot.value!["item_uid"] as? String,
                let itemPT = snapshot.value!["points"] as? Double,
                let itemTX = snapshot.value!["texture_points"] as? Double,
                let itemFL = snapshot.value!["flavor_points"] as? Double,
                let itemIMG = snapshot.value!["user_taken_image"] as? String
                else {return}
            
            // Get each item details
            database.child("items").child(itemUID).observeSingleEventOfType(.Value , withBlock: { snapshot in
                
                print(snapshot)
                
                guard let name = snapshot.value!["name"] as? String else {return}
                let imageURL = NSURL(string: itemIMG)
                
                //Firebase was written in async
                database.child("barcodes").queryOrderedByValue().queryEqualToValue(itemUID).observeSingleEventOfType(.ChildAdded, withBlock: { snapshot in
                    
                    let barcode = snapshot.key
                                        
                    let item = ItemModel(name: name, barcode: barcode, imageURL: imageURL!, itemPT: itemPT, itemTX: itemTX, itemFL: itemFL)
                    self.items.append(item)
                    
                    self.totalTexturePoints = self.totalTexturePoints + itemTX
                    self.totalFlavorPoints = self.totalFlavorPoints + itemFL
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        
                        self.ratedItems = self.items.count
                        self.uploadAverageData(self.ratedItems, ttlTX: self.totalTexturePoints, ttlFL: self.totalFlavorPoints)
                        self.notifyToReloadList()
                        self.updateAvgNumbers(self.ratedItems, ttlTX: self.totalTexturePoints, ttlFL: self.totalFlavorPoints)
                        self.drawGraph(self.items)
                    })
                    
                })
                
            })
            
        })
        
    }
    
    func updateAvgNumbers(ttlRated: Int, ttlTX: Double, ttlFL: Double) {
        
        let avgTX = ttlTX / Double(ttlRated)
        let avgFL = ttlFL / Double(ttlRated)
        
        let tasteType: TasteType
        
        if avgTX <= 2.5 && avgFL <= 2.5 {
            
        }
        
        destinationProfileVC.totalRatedLabel.text = "You Rated \(String(ttlRated))"
        destinationProfileVC.avgTextureLabel.text = "Avg. Texture: \(String(avgTX))"
        destinationProfileVC.avgFlavorLabel.text = "Avg. Flavor: \(String(avgFL))"
        
    }
    
    func notifyToReloadList() {
    
        self.destinationListVC.items = self.items
        self.destinationProfileVC.receivedItemArray = self.items
        NSNotificationCenter.defaultCenter().postNotificationName("reloadList", object: nil)
    
    }
    
    func drawGraph(itemArray: [ItemModel]) {
    
        destinationProfileVC.runBubbleChart(itemArray)

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

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "embedToList" {
            guard let destinationViewControllerList = segue.destinationViewController as? ListTableViewController else {
                return
            }
            destinationListVC = destinationViewControllerList
        }
        if segue.identifier == "embedToProfile" {
            guard let destinationViewControllerProfile = segue.destinationViewController as? ProfileViewController else {
                return
            }
            destinationProfileVC = destinationViewControllerProfile
        }
        
    }
    
}
