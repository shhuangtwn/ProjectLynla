//
//  CameraViewController.swift
//  DataCollectionTool
//
//  Created by Bryan Huang on 2016/10/14.
//  Copyright © 2016年 Steven Hunag. All rights reserved.
//

import UIKit

class CameraViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var receivedBarCode: String = ""
    let imagePicker = UIImagePickerController()
    var isFirstTime = true
    var itemImageData = NSData()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(animated: Bool) {
        
        self.navigationController?.navigationBar.hidden = true
        
        super.viewDidAppear(false)
        if isFirstTime{
            isFirstTime = false
            openCamera()
        }else{
            self.performSegueWithIdentifier("segueToAnalyze", sender: nil)
        }
        
        
    }
    
    func openCamera() {
        
        imagePicker.delegate = self
        
        if UIImagePickerController.availableCaptureModesForCameraDevice(.Rear) != nil {
            imagePicker.allowsEditing = false
            imagePicker.sourceType = UIImagePickerControllerSourceType.Camera
            imagePicker.cameraCaptureMode = .Photo
            presentViewController(imagePicker, animated: false, completion: nil)
        } else {
            noCamera()
        }
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(false, completion: nil)
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let startingViewController: UIViewController = mainStoryboard.instantiateViewControllerWithIdentifier("NavigationViewController")
        
        self.presentViewController(startingViewController, animated: true, completion: nil)
    }
    
    func noCamera(){
        let alertVC = UIAlertController(
            title: "No Camera",
            message: "Sorry, this device has no camera",
            preferredStyle: .Alert)
        let okAction = UIAlertAction(
            title: "OK",
            style:.Default,
            handler: nil)
        alertVC.addAction(okAction)
        presentViewController(alertVC,
                              animated: false,
                              completion: nil)
    }
    
    var takenItemImageString: String = ""
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
            // Base64 encode the image and create the request
            
            itemImageData = base64EncodeImage(pickedImage)
            
            imagePicker.dismissViewControllerAnimated(false, completion: nil)
            
        }
        
        
        //dismissViewControllerAnimated(true, completion: nil)
    }
    
    func resizeImage(imageSize: CGSize, image: UIImage) -> NSData {
        UIGraphicsBeginImageContext(imageSize)
        image.drawInRect(CGRectMake(0, 0, imageSize.width, imageSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        let resizedImage = UIImagePNGRepresentation(newImage)
        UIGraphicsEndImageContext()
        return resizedImage!
    }
    
    
    func base64EncodeImage(image: UIImage) -> NSData {
        var imagedata = UIImagePNGRepresentation(image)
        
        // Resize the image if it exceeds the 0.1MB API limit
        if (imagedata?.length > 100000) {
            let oldSize: CGSize = image.size
            let newSize: CGSize = CGSizeMake(300, oldSize.height / oldSize.width * 300)
            imagedata = resizeImage(newSize, image: image)
        }
        
        return imagedata!
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "segueToAnalyze" {
            let destinationViewController = segue.destinationViewController as! AnalyzingViewController;
            destinationViewController.receivedItemImageData = itemImageData
            destinationViewController.receivedBarCode = receivedBarCode
        }
        
    }
    
}
