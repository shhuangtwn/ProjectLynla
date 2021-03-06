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
import FirebaseAnalytics

class ImageAnalyticViewController: UIViewController, UITextFieldDelegate {
    
    enum MatchingCase {
        case brandNew
        case newToUser
        case existingItem
    }
    
    @IBAction func testSliderAction(sender: UISlider) {
        
        let step: Float = 1
        let roundedValue = round(sender.value / step) * step
        sender.value = roundedValue
        
    }
    
    @IBOutlet weak var doneButtonForSaving: UIBarButtonItem!
    @IBAction func doneButtonForSaving(sender: UIBarButtonItem) {
        if self.userUID == "" {

            let alert = UIAlertController(title: "Lynla!", message: "Thanks for trying out, please login to record your rating", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Back to Login", style: UIAlertActionStyle.Default, handler: { action in
                self.performSegueWithIdentifier("segueBackToCaptureForDismissingVC", sender: nil)
                
            }))

        self.presentViewController(alert, animated: true, completion: nil)
            
        } else {
        
            postToCloudPressed()
            
        }
        
    }
    @IBOutlet weak var avgFlavorLabel: UILabel!
    @IBOutlet weak var avgTextureLabel: UILabel!
    @IBOutlet weak var avgPointsLabel: UILabel!
    @IBOutlet weak var ratedTimesLabel: UILabel!
    @IBOutlet weak var logoTextfield: UITextField!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var testSlider: UISlider!
    var receivedBarCode: String = ""
    var receivedItemImageData = NSData()
    var receivedLogoText: String = ""
    var receivedInformationText: String = ""
    var receivedMatchingStatus: Int = 0
    var receivedItemUID: String = ""

    @IBOutlet weak var barcodeLabel: UILabel!
    @IBOutlet weak var logoResults: UILabel!
    
    var ratedPoints: Double = 3.0
    var ratedTexture: Double = 3.0
    var ratedFlavor: Double = 3.0
    var userUID: String = ""
    
    @IBOutlet weak var ratingControl: RatingControl!
    
//    @IBAction func ratingSegmentor(sender: UISegmentedControl) {
//        
//        switch sender.selectedSegmentIndex {
//        case 0: ratedPoints = 1.0
//        case 1: ratedPoints = 2.0
//        case 2: ratedPoints = 3.0
//        case 3: ratedPoints = 4.0
//        case 4: ratedPoints = 5.0
//        default: break
//        }
//    }
    
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
    @IBOutlet weak var cardBGLabel: UILabel!
    
    
    @IBOutlet weak var loadingSpinnerUI: UIActivityIndicatorView!
    @IBOutlet weak var loadingMaskView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Set UI
        
        self.loadingMaskView.hidden = true
        self.loadingSpinnerUI.hidden = true
        
        self.navigationController?.title = "Lynla"
        self.navigationController?.navigationBar.backItem?.hidesBackButton = true
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        self.navigationController?.navigationBar.layer.shadowColor = UIColor.blackColor().CGColor
        self.navigationController?.navigationBar.layer.shadowOffset = CGSizeMake(0, 1)
        self.navigationController?.navigationBar.layer.shadowOpacity = 0.5

        self.cardBGLabel.layer.shadowColor = UIColor.blackColor().CGColor
        self.cardBGLabel.layer.shadowOpacity = 0.5
        self.cardBGLabel.layer.shadowOffset = CGSizeMake(0.0, 2.0)
        self.cardBGLabel.layer.shadowRadius = 2.5

        self.imageView.layer.shadowColor = UIColor.blackColor().CGColor
        self.imageView.layer.shadowOpacity = 0.5
        self.imageView.layer.shadowOffset = CGSizeMake(0.0, 2.0)
        self.imageView.layer.shadowRadius = 2.5

        testSlider.hidden = true
        ratingSegmentor.hidden = true
        
//        ratingSegmentor.selectedSegmentIndex = (Int(ratedPoints) - 1 )
        flavorSegmentor.selectedSegmentIndex = (Int(ratedTexture) - 1 )
        textureSegmentor.selectedSegmentIndex = (Int(ratedFlavor) - 1 )
        self.ratingControl.rating = Int(ratedPoints)
        
        barcodeLabel.text = "Barcode: \(receivedBarCode)"
        self.imageView.image = UIImage(data: receivedItemImageData)
        self.logoTextfield.text = receivedLogoText
        self.avgPointsLabel.hidden = true
        self.avgTextureLabel.hidden = true
        self.avgFlavorLabel.hidden = true
        
        // Get userUID
        let defaults = NSUserDefaults.standardUserDefaults()
        if let uuid = defaults.stringForKey("userUID") {
            self.userUID = uuid
        } else {
            getUserKey()
        }
        
        
        // FIrebase Analytics Event Log
        FIRAnalytics.logEventWithName("complete_analyze", parameters: ["item": receivedLogoText])
        
        
        // Receive matching state
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
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func postToCloudPressed() {
        
        self.loadingMaskView.hidden = false
        self.loadingSpinnerUI.hidden = false
        self.loadingSpinnerUI.startAnimating()
        
        self.ratedPoints = Double(self.ratingControl.rating)
        
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
                
                // FIrebase Analytics Event Log
                FIRAnalytics.logEventWithName("complete_saving", parameters: ["state": "feedback saved"])
                
                self.alertUserDataAdded()
                
            })
        })
        
    }
    
    func alertUserDataAdded() {
        
        let alert = UIAlertController(title: "Lynla!", message: "Thanks for your feedback", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Home", style: UIAlertActionStyle.Default, handler: { action in
            
            
            self.loadingMaskView.hidden = true
            self.loadingSpinnerUI.hidden = true
            self.loadingSpinnerUI.stopAnimating()
            self.performSegueWithIdentifier("segueBackToCaptureForDismissingVC", sender: nil)

        }))
        
        alert.addAction(UIAlertAction(title: "Go back", style: UIAlertActionStyle.Cancel, handler: { action in
            
            
            self.loadingMaskView.hidden = true
            self.loadingSpinnerUI.hidden = true
            self.loadingSpinnerUI.stopAnimating()
            
        }))

        self.presentViewController(alert, animated: true, completion: nil)
        
    }
    
    // Get backup user key
    func getUserKey() {
        if let user = FIRAuth.auth()?.currentUser {
            self.userUID = user.uid;
            
        } else {
            self.userUID = ""
            
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


