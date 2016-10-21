//
//  ImageAnalyticViewController.swift
//  DataCollectionTool
//
//  Created by Bryan Huang on 2016/9/30.
//  Copyright © 2016年 Steven Hunag. All rights reserved.
//

import UIKit
import SwiftyJSON
import FirebaseDatabase
import FirebaseStorage
import FirebaseAuth

class ImageAnalyticViewController: UIViewController, UITextFieldDelegate {
    
    enum MatchingCase {
        case brandNew
        case newToUser
        case existingItem
    }
    
    @IBOutlet weak var avgFlavorLabel: UILabel!
    @IBOutlet weak var avgTextureLabel: UILabel!
    @IBOutlet weak var avgPointsLabel: UILabel!
    @IBOutlet weak var ratedTimesLabel: UILabel!
    @IBOutlet weak var logoTextfield: UITextField!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var homeButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    
    var receivedBarCode: String = ""
    var receivedItemImageData = NSData()
    var receivedLogoText: String = ""
    var receivedInformationText: String = ""
    var receivedMatchingStatus: Int = 0
    var receivedItemUID: String = ""

//    case .unMatch: mode = 0
//    case .newToUser: mode = 1
//    case .existingToUser: mode = 2
    
    @IBOutlet weak var barcodeLabel: UILabel!
    @IBOutlet weak var logoResults: UILabel!
    
    var ratedPoints: Double = 3.0
    var ratedTexture: Double = 3.0
    var ratedFlavor: Double = 3.0
    var userUID: String = ""
    
    @IBAction func ratingSegmentor(sender: UISegmentedControl) {
        
        switch sender.selectedSegmentIndex {
        case 0: ratedPoints = 1.0
        case 1: ratedPoints = 2.0
        case 2: ratedPoints = 3.0
        case 3: ratedPoints = 4.0
        case 4: ratedPoints = 5.0
        default: break
        }
    }
    
    @IBAction func textureSegmentor(sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0: ratedTexture = 1.0
        case 1: ratedTexture = 2.0
        case 2: ratedTexture = 3.0
        case 3: ratedTexture = 4.0
        case 4: ratedTexture = 5.0
        default: break
        }
    }
    
    @IBAction func flavorSegmentor(sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0: ratedFlavor = 1.0
        case 1: ratedFlavor = 2.0
        case 2: ratedFlavor = 3.0
        case 3: ratedFlavor = 4.0
        case 4: ratedFlavor = 5.0
        default: break
        }
    }
    
    @IBOutlet weak var ratingSegmentor: UISegmentedControl!
    @IBOutlet weak var textureSegmentor: UISegmentedControl!
    @IBOutlet weak var flavorSegmentor: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get userUID
        
        self.navigationController?.navigationBar.hidden = true
        
        let defaults = NSUserDefaults.standardUserDefaults()
        if let uuid = defaults.stringForKey("userUID") {
            self.userUID = uuid
        } else {
            getUserKey()
        }
        
        // Set UI
        ratingSegmentor.selectedSegmentIndex = (Int(ratedPoints) - 1 )
        flavorSegmentor.selectedSegmentIndex = (Int(ratedTexture) - 1 )
        textureSegmentor.selectedSegmentIndex = (Int(ratedFlavor) - 1 )
        barcodeLabel.text = "Barcode: \(receivedBarCode)"
        self.imageView.image = UIImage(data: receivedItemImageData)
        self.logoTextfield.text = receivedLogoText
        self.avgPointsLabel.hidden = true
        self.avgTextureLabel.hidden = true
        self.avgFlavorLabel.hidden = true
        print("reci: \(ratedPoints)")
        
        if receivedMatchingStatus == 0 {
        
            // Unmatch -> user to submit new item
            print("enter unMatch")
            
            
        } else if receivedMatchingStatus == 1 {
        
            // New to user -> user to feedback from default value 3
            print("enter newToUser")
            self.logoTextfield.enabled = false
            
        } else if receivedMatchingStatus == 2 {
        
            // Existing item -> user to re-feedback from previous value
            print("enter existingItem")
            self.logoTextfield.enabled = false
            
        } else {
            fatalError("segue fail")
        }
        
        // Move keyboard and view
        logoTextfield.delegate = self
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ImageAnalyticViewController.dismissKeyboard)))
        
        // Save to cloud button tapped
        self.saveButton.addTarget(self, action: #selector(self.postToCloudPressed(_:)), forControlEvents: .TouchUpInside)
        
    }
    
    func postToCloudPressed(sender: UIButton) {
        
        // TO DO: Need to identify if same item saving
        
        let databaseRef = FIRDatabase.database().reference()
        let postItemRef = databaseRef.child("items").childByAutoId()
        
        // save barcode with item
        var postItemKey: String = ""
        if receivedMatchingStatus == 0 {
            postItemKey = postItemRef.key
        } else {
            postItemKey = receivedItemUID
        }
        
        databaseRef.child("barcodes").child(receivedBarCode).setValue(postItemKey)
        
        let storageRef = FIRStorage.storage().reference().child("user_item_images/TESTUSERKEY/\(postItemKey).png")
        let uploadMetadata = FIRStorageMetadata()
        uploadMetadata.contentType = "image/png"
        var itemImageUrlString: String = ""
        storageRef.putData(receivedItemImageData, metadata: uploadMetadata, completion: { (metadata, error) in
            if (error != nil) {
                print("uploading error: \(error)")
            } else {
                print("upload good: \(metadata)")
                itemImageUrlString = metadata!.downloadURL()!.absoluteString
            }
            
            let postItemData: [String: AnyObject] = [
                "name": self.logoTextfield.text!,
                "image": itemImageUrlString]
            
            postItemRef.setValue(postItemData)
            
            dispatch_async(dispatch_get_main_queue(), {
                let uniqueFeedbackKey = "\(self.userUID)\(postItemKey)"
                let postUserFeedbackRef = databaseRef.child("user_feedbacks").child(uniqueFeedbackKey)
                let postUFBRatingData: [String: AnyObject] = [
                    "user_uid":self.userUID,
                    "item_uid": postItemKey,
                    "points": self.ratedPoints,
                    "texture_points": self.ratedTexture,
                    "flavor_points": self.ratedFlavor,
                    "user_taken_image": itemImageUrlString]
                
                postUserFeedbackRef.setValue(postUFBRatingData)
                
                self.alertUserDataAdded()
                
            })
        })
        
    }
    
    func alertUserDataAdded() {
        
        let alert = UIAlertController(title: "Lynla!", message: "Thanks for your feedback", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Home", style: UIAlertActionStyle.Default, handler: { action in
            self.performSegueWithIdentifier("segueToHome", sender: nil)
            self.navigationController?.navigationBar.hidden = false

        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: { action in
            
            
        }))

        self.presentViewController(alert, animated: true, completion: nil)
        
    }
    
    // Get backup user key
    func getUserKey() {
        if let user = FIRAuth.auth()?.currentUser {
            self.userUID = user.uid;
            
        } else {
            self.userUID = "user UID missing"
            
        }
    }
    
    // Keyboard setup
    func dismissKeyboard() {
        logoTextfield.resignFirstResponder()
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        logoTextfield.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        animateViewMoving(true, moveValue: 100)
    }
    func textFieldDidEndEditing(textField: UITextField) {
        animateViewMoving(false, moveValue: 100)
    }
    
    func animateViewMoving (up:Bool, moveValue :CGFloat){
        let movementDuration:NSTimeInterval = 0.3
        let movement:CGFloat = ( up ? -moveValue : moveValue)
        UIView.beginAnimations( "animateView", context: nil)
        UIView.setAnimationBeginsFromCurrentState(true)
        UIView.setAnimationDuration(movementDuration )
        self.view.frame = CGRectOffset(self.view.frame, 0,  movement)
        UIView.commitAnimations()
    }
    
}


