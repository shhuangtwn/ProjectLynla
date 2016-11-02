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
import FBSDKLoginKit
import Haneke

class ContainerViewController: UIViewController {

    @IBOutlet weak var spinnerUI: UIActivityIndicatorView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var ratedNumberLabel: UILabel!
    @IBOutlet weak var tasteInfoLabel: UILabel!
    @IBOutlet weak var analyzeButton: UIButton!
    
    @IBOutlet weak var scanButtonShadowLabel: UILabel!
    @IBOutlet weak var ratingLevelCommentLabel: UILabel!
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var profileCardBG: UILabel!
//    @IBOutlet weak var containerProfile: UIView!
    @IBOutlet weak var containerList: UIView!
    @IBOutlet weak var scanButton: UIButton!
    @IBAction func scanButton(sender: UIButton) {
    
        
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let CaptureViewController: UIViewController = mainStoryboard.instantiateViewControllerWithIdentifier("CaptureView")
        
        self.presentViewController(CaptureViewController, animated: true, completion: nil)
        
    }
    
    @IBAction func segueToHome(segue: UIStoryboardSegue) {}
        
    var items = [ItemModel]()
    
    var destinationListVC = ListTableViewController()
    var destinationProfileVC = ProfileViewController()
    
    var userUID: String = ""
    var ratedItems: Int = 0
    var totalTexturePoints: Double = 0.0
    var totalFlavorPoints: Double = 0.0
    var tasteTextToShow: String = ""

    enum TasteType {
    
        case sweetAndSmooth
        case sweetAndThick
        case bitterAndSmooth
        case bitterAndThick
        case noTaste
        
    }
    
    @IBAction func logoutButton(sender: UIBarButtonItem) {
        
        // sign out firebase
        try! FIRAuth.auth()!.signOut()
        
        // sign out FB
        FBSDKAccessToken.setCurrentAccessToken(nil)
        
        print("user logout")
        
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let loginViewController: UIViewController = mainStoryboard.instantiateViewControllerWithIdentifier("LoginView")
        
        self.presentViewController(loginViewController, animated: true, completion: nil)

        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        getUserKey()
    
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Set UI
//        self.containerList.layer.shadowRadius = 1
//        self.containerList.layer.shadowColor = UIColor.blackColor().CGColor
//        self.containerList.layer.shadowOffset = CGSizeMake(1, 1)
//        self.containerList.layer.shadowOpacity = 0.5

        self.scanButton.layer.cornerRadius = 25
        self.scanButton.layer.masksToBounds = true
        self.scanButtonShadowLabel.layer.cornerRadius = 25
        self.scanButtonShadowLabel.layer.shadowColor = UIColor.blackColor().CGColor
        self.scanButtonShadowLabel.layer.shadowOpacity = 0.5
        self.scanButtonShadowLabel.layer.shadowRadius = 3
        self.scanButtonShadowLabel.layer.shadowOffset = CGSizeMake(1, 1)
        let path = UIBezierPath(roundedRect: scanButtonShadowLabel.bounds, cornerRadius: 25).CGPath
        self.scanButtonShadowLabel.layer.shadowPath = path
//        self.scanButtonShadowLabel.layer.masksToBounds = true

//        self.scanButtonShadowLabel.clipsToBounds = true

        self.navigationController?.navigationBar.barTintColor = UIColor(red: 43.0/255.0, green: 74.0/255.0, blue: 109.0/255.0, alpha: 1.0)
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.whiteColor()]
        self.navigationController?.navigationBar.layer.shadowColor = UIColor.blackColor().CGColor
        self.navigationController?.navigationBar.layer.shadowOffset = CGSizeMake(0, 1)
        self.navigationController?.navigationBar.layer.shadowOpacity = 0.5
        
//        self.profileCardBG.clipsToBounds = true
//        self.profileCardBG.layer.shadowPath = UIBezierPath(rect: profileCardBG.bounds).CGPath
        self.profileCardBG.layer.cornerRadius = 5
        self.profileCardBG.layer.shadowColor = UIColor.blackColor().CGColor
        self.profileCardBG.layer.shadowOpacity = 0.5
        self.profileCardBG.layer.shadowOffset = CGSizeMake(0.0, 2.0)
        self.profileCardBG.layer.shadowRadius = 2.5
        //        self.profileImageView.layer.shadowRadius = 1
//        self.profileImageView.layer.shadowColor = UIColor.blackColor().CGColor
//        self.profileImageView.layer.shadowOpacity = 0.5
//        self.profileImageView.layer.shadowOffset = CGSizeMake(0.5, 0.5)
        self.profileImageView.layer.borderColor = UIColor.grayColor().CGColor
        self.profileImageView.layer.borderWidth = 1
        
        self.containerList.backgroundColor = UIColor(red: 239.0/255.0, green: 62.0/255.0, blue: 54.0/255.0, alpha: 1.0)
        
        self.spinnerUI.startAnimating()
        fetchItems()

    }
    
    func fetchItems() {
        
        self.items = []
        
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
                        
                        self.spinnerUI.stopAnimating()
                        self.spinnerUI.hidden = true
                        self.ratedItems = self.items.count
                        self.ratedNumberLabel.text = String(self.ratedItems)
                        self.uploadAverageData(self.ratedItems, ttlTX: self.totalTexturePoints, ttlFL: self.totalFlavorPoints)
                        self.notifyToReloadList()
                        self.updateAvgNumbers(self.ratedItems, ttlTX: self.totalTexturePoints, ttlFL: self.totalFlavorPoints)
                    })
                    
                })
                
            })
            
        })
        
    }
    
    func updateAvgNumbers(ttlRated: Int, ttlTX: Double, ttlFL: Double) {
        
        let avgTX = ttlTX / Double(ttlRated)
        let avgFL = ttlFL / Double(ttlRated)
        
        var tasteType = TasteType.noTaste
        
        if avgTX <= 2.5 && avgFL <= 2.5 {
            tasteType = .sweetAndSmooth
        } else if avgTX <= 2.5 && avgFL > 2.5 {
            tasteType = .bitterAndSmooth
        } else if avgTX > 2.5 && avgFL <= 2.5 {
            tasteType = .sweetAndThick
        } else if avgTX > 2.5 && avgFL > 2.5 {
            tasteType = .bitterAndThick
        } else {
            tasteType = .noTaste
        }

        switch tasteType {
        case .sweetAndSmooth: tasteTextToShow = "Seems like you prefer sweet and smooth beers"
        case .sweetAndThick: tasteTextToShow = "Seems like you prefer sweet but thick beers"
        case .bitterAndSmooth: tasteTextToShow = "Seems like you prefer bitter but smooth beer"
        case .bitterAndThick: tasteTextToShow = "Seems like you prefer bitter and thick beer"
        case .noTaste: tasteTextToShow = "Let's scan your first beer!"
        }
        
    }
    
    func notifyToReloadList() {
    
        self.destinationListVC.items = self.items
        NSNotificationCenter.defaultCenter().postNotificationName("reloadList", object: nil)
    
    }
    
    func getUserKey() {
        if let user = FIRAuth.auth()?.currentUser {
            self.nameLabel.text = user.displayName
            //            let email = user.email
            guard let userPhotoURL = user.photoURL else {return}
            self.profileImageView.hnk_setImageFromURL(userPhotoURL)
            self.userUID = user.uid
            
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
        if segue.identifier == "segueToProfile" {
            guard let destinationViewControllerProfile = segue.destinationViewController as? ProfileViewController else {
                return
            }
            destinationProfileVC = destinationViewControllerProfile
            self.destinationProfileVC.receivedItemArray = self.items
//            self.destinationProfileVC.nameLabel.text = tasteTextToShow

        }
        
    }
    
}
