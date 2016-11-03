//
//  AnalyzingViewController.swift
//  DataCollectionTool
//
//  Created by Bryan Huang on 2016/10/19.
//  Copyright © 2016年 freelance. All rights reserved.
//

import UIKit
import SwiftyJSON
import FirebaseAuth
import FirebaseDatabase

class AnalyzingViewController: UIViewController {
    
    var receivedBarCode: String = ""
    var receivedItemImageData = NSData()
    var detectedLogo: String = ""
    
    var userUID: String = ""
    var itemUID: String = ""
    
    var currentPoints: Double = 3.0
    var currentTexture: Double = 3.0
    var currentFlavor: Double = 3.0
    
    var matchingStatus: MatchingCase = .unMatch
    enum MatchingCase {
        case unMatch
        case newToUser
        case existingToUser
    }
    
    @IBOutlet weak var spinnerUI: UIActivityIndicatorView!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var checkImage: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
       
        self.navigationController?.title = "Analyzing..."
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        self.navigationController?.navigationBar.layer.shadowColor = UIColor.blackColor().CGColor
        self.navigationController?.navigationBar.layer.shadowOffset = CGSizeMake(0, 1)
        self.navigationController?.navigationBar.layer.shadowOpacity = 0.5
        
        self.navigationController?.navigationBar.backItem?.hidesBackButton = true
        
        self.checkImage.hidden = true
        
        // Get userUID
        let defaults = NSUserDefaults.standardUserDefaults()
        if let uuid = defaults.stringForKey("userUID") {
            self.userUID = uuid
        } else {
            getUserKey()
        }
        
        self.spinnerUI.startAnimating()
        searchForBarcodeMatch(receivedBarCode)
        
    }
    
    // Get backup user key
    func getUserKey() {
        if let user = FIRAuth.auth()?.currentUser {
            self.userUID = user.uid;
            
        } else {
            self.userUID = ""
            
        }
    }
    
    func searchForBarcodeMatch(code: String) {
        
        let database = FIRDatabase.database().reference()
        database.child("barcodes").observeSingleEventOfType(.Value, withBlock: { snapshot in
            
            
            guard let barcodeSets = snapshot.value as? NSDictionary else{
                fatalError("not NSDictionary")
            }
            
            guard let keys = barcodeSets.allKeys as? [String] else{
                fatalError("barcode key error")
            }
            
            // Found a match, return true and extract item uid
            if keys.contains(code){
                
                if let matchedItemKey: String = barcodeSets.valueForKey(code) as? String {
                    self.itemUID = matchedItemKey
                    print("match item: \(matchedItemKey)")
                    
                    // Get item name
                    self.getItemName(self.itemUID)
                    
                    // If trying...
                    if self.userUID == "" {
                        // perform
                        self.matchingStatus = .newToUser
                        self.infoLabel.text = "Found a match!"
                        self.moveToItemPage()
                        
                    } else {
                        // Check if inside user list
                        self.searchInUserList(self.userUID, code: code, iuid: self.itemUID)
                    }
                }
                
            } else {
                
                // User discover new item -> Analyze image with cloud image
                let imageStringToBeAnalyze = self.receivedItemImageData.base64EncodedStringWithOptions(.EncodingEndLineWithCarriageReturn)
                self.createRequest(imageStringToBeAnalyze)
                
            }
            
        })
        
    }
    
    func searchInUserList(uuid: String, code: String, iuid: String) {
        
        let database = FIRDatabase.database().reference()
        
        // See if matched item in user's list
        database.child("user_feedbacks").queryOrderedByChild("user_uid").queryEqualToValue(uuid).observeSingleEventOfType(.Value , withBlock: { snapshot in
            
            guard let userFeedbacks = snapshot.value as? NSDictionary else{
                fatalError("not NSDict")
            }
            
            let valueArray = userFeedbacks.allValues
            var trueForExisting: Bool = false
            
            for obj in valueArray {
                
                    if obj["item_uid"] as? String == iuid {
                        print("matched user item: \(iuid)")
                       
                        trueForExisting = true
                        self.currentPoints = obj["points"] as! Double
                        self.currentTexture = obj["texture_points"] as! Double
                        self.currentFlavor = obj["flavor_points"] as! Double
                        
                    }
            }
            
            dispatch_async(dispatch_get_main_queue(), {
                
                if trueForExisting == true {
                    
                    // User had -> load item and user feedback
                    self.matchingStatus = .existingToUser
                    self.infoLabel.text = "Found in your list!"
                    self.spinnerUI.stopAnimating()
                    
                    self.moveToItemPage()

                } else {
                
                    // New to user -> load item from DB
                    self.matchingStatus = .newToUser
                    self.infoLabel.text = "Found a match!"
                    self.spinnerUI.stopAnimating()

                    self.moveToItemPage()
                    
                }
                
            })

        })
        
    }
    
    func getItemName(iuid: String) {
        var foundItemName: String = ""
        
        let database = FIRDatabase.database().reference()
        
        // See if matched item in user's list
        database.child("items").child(iuid).observeSingleEventOfType(.Value , withBlock: { snapshot in
        
            guard let item = snapshot.value as? NSDictionary else{
                fatalError("not NSDict")
            }
            
            dispatch_async(dispatch_get_main_queue(), {

            foundItemName = item["name"] as! String
                
            self.detectedLogo = foundItemName
                
            })
        
        })
        
    }
    
    func createRequest(imageData: String) {
        
        var API_KEY: String = ""
        if let path = NSBundle.mainBundle().pathForResource("Info", ofType: "plist"), dict = NSDictionary(contentsOfFile: path) as? [String: AnyObject] {
            // use swift dictionary as normal
            if let getKey = dict["CloudVisionKey"] {
               API_KEY = getKey as! String
            }
        }
        
        // Create our request URL
        let request = NSMutableURLRequest(
            URL: NSURL(string: "https://vision.googleapis.com/v1/images:annotate?key=\(API_KEY)")!)
        request.HTTPMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(
            NSBundle.mainBundle().bundleIdentifier ?? "",
            forHTTPHeaderField: "X-Ios-Bundle-Identifier")
        
        // Build our API request
        let jsonRequest: [String: AnyObject] = [
            "requests": [
                "image": [
                    "content": imageData
                ],
                "features": [
                    [
                        "type": "LABEL_DETECTION",
                        "maxResults": 1
                    ],
                    [
                        "type": "LOGO_DETECTION",
                        "maxResults": 1
                    ],
                    [
                        "type": "TEXT_DETECTION",
                        "maxResults": 1
                    ]
                ]
            ]
        ]
        
        // Serialize the JSON
        request.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(jsonRequest, options: [])
        
        // Run the request on a background thread
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            self.runRequestOnBackgroundThread(request)
        });
        
    }
    
    func runRequestOnBackgroundThread(request: NSMutableURLRequest) {
        
        let session = NSURLSession.sharedSession()
        
        // run the request
        let task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            self.analyzeResults(data!)
        })
        task.resume()
    }
    
    func analyzeResults(dataToParse: NSData) {
        
        // Update UI on the main thread
        dispatch_async(dispatch_get_main_queue(), {
            
            // Use SwiftyJSON to parse results
            let json = JSON(data: dataToParse)
            let errorObj: JSON = json["error"]
            
            // Check for errors
            if (errorObj.dictionaryValue != [:]) {
                self.detectedLogo = "Error code \(errorObj["code"]): \(errorObj["message"])"
            } else {
                // Parse the response
                //print(json)
                let responses: JSON = json["responses"][0]
                
                
                // Get LOGO
                let logoAnnotations: JSON = responses["logoAnnotations"]
                let numLogos: Int = logoAnnotations.count
                var logos: Array<String> = []
                if numLogos > 0 {
                    var logoResultsText:String = ""
                    for index in 0..<numLogos {
                        let logo = logoAnnotations[index]["description"].stringValue
                        logos.append(logo)
                        self.detectedLogo = logo
                    }
                    for logo in logos {
                        // if it's not the last item add a comma
                        if logos[logos.count - 1] != logo {
                            logoResultsText += "\(logo), "
                        } else {
                            logoResultsText += "\(logo)"
                        }
                    }
                    self.detectedLogo = logoResultsText
                } else {
                    self.detectedLogo = "Please edit Logo"
                }
                
            }
            
            // New one -> Load item with detected logo
            self.spinnerUI.stopAnimating()
            self.matchingStatus = .unMatch
            self.infoLabel.text = "You found a new one!"
            
            self.moveToItemPage()

        })
        
    }
    
    func moveToItemPage() {
    
        // Let user read result
        self.checkImage.hidden = false
        self.spinnerUI.hidden = true
        let seconds = 1.5
        let delay = seconds * Double(NSEC_PER_SEC)  // nanoseconds per seconds
        let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        
        dispatch_after(dispatchTime, dispatch_get_main_queue(), {
            
            // here code perfomed with delay
            self.performSegueWithIdentifier("segueToItem", sender: nil)
            
        })
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "segueToItem" {
            var mode: Int = 0
            switch matchingStatus {
            
            case .unMatch: mode = 0
            case .newToUser: mode = 1
            case .existingToUser: mode = 2
                
            }
            
            let destinationViewController = segue.destinationViewController as! ImageAnalyticViewController;
            destinationViewController.receivedItemImageData = receivedItemImageData
            destinationViewController.receivedBarCode = receivedBarCode
            destinationViewController.receivedItemUID = itemUID
            destinationViewController.receivedLogoText = detectedLogo
            
            destinationViewController.ratedPoints = currentPoints
            destinationViewController.ratedTexture = currentTexture
            destinationViewController.ratedFlavor = currentFlavor

            destinationViewController.receivedInformationText = infoLabel.text!
            destinationViewController.receivedMatchingStatus = mode
            
        }
        
    }
    
}
