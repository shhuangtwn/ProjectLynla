//
//  ImageAnalyticViewController.swift
//  DataCollectionTool
//
//  Created by Bryan Huang on 2016/9/30.
//  Copyright © 2016年 Steven Hunag. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseStorage

class PresentItemViewController: UIViewController {
    
    @IBOutlet weak var avgFlavorLabel: UILabel!
    @IBOutlet weak var avgTextureLabel: UILabel!
    @IBOutlet weak var avgPointsLabel: UILabel!
    @IBOutlet weak var ratedTimesLabel: UILabel!
    @IBOutlet weak var logoTextfield: UITextField!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var homeButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    
    let imagePicker = UIImagePickerController()
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    var receivedBarCode: String = ""
    var receivedItemUID: String = ""
    var detectedLogo: String = ""
    var takenItemImage: NSData!
    @IBOutlet weak var barcodeLabel: UILabel!
    @IBOutlet weak var logoResults: UILabel!
    var ratedPoints: Int = 3
    var ratedTexture: Int = 3
    var ratedFlavor: Int = 3
    
    
    @IBAction func ratingSegmentor(sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0: ratedPoints = 1
        case 1: ratedPoints = 2
        case 2: ratedPoints = 3
        case 3: ratedPoints = 4
        case 4: ratedPoints = 5
        default: break
        }
    }
    
    @IBAction func textureSegmentor(sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0: ratedTexture = 1
        case 1: ratedTexture = 2
        case 2: ratedTexture = 3
        case 3: ratedTexture = 4
        case 4: ratedTexture = 5
        default: break
        }
    }
    
    @IBAction func flavorSegmentor(sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0: ratedFlavor = 1
        case 1: ratedFlavor = 2
        case 2: ratedFlavor = 3
        case 3: ratedFlavor = 4
        case 4: ratedFlavor = 5
        default: break
        }
    }
    
    func postToCloud() {
        let databaseRef = FIRDatabase.database().reference()
        
        let postItemKey = receivedItemUID
        
        let postUserFeedbackRef = databaseRef.child("user_feedbacks").childByAutoId()
        let postUFBRatingData: [String: AnyObject] = [
            "user_uid":"random id now",
            "item_uid": postItemKey,
            "points": ratedPoints,
            "texture_points": ratedTexture,
            "flavor_points": ratedFlavor]
        
        postUserFeedbackRef.setValue(postUFBRatingData)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        barcodeLabel.text = "Barcode: \(receivedBarCode)"
        //labelResults.hidden = true
        self.logoResults.hidden = true
        //self.textResults.hidden = true
        spinner.hidesWhenStopped = true
        self.saveButton.hidden = true
        self.homeButton.hidden = true
        
    }
    
}
