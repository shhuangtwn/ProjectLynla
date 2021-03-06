//
//  CaptureViewController.swift
//  DataCollectionTool
//
//  Created by Bryan Huang on 2016/9/26.
//  Copyright © 2016年 Steven Hunag. All rights reserved.
//

import UIKit
import AVFoundation
import FirebaseAnalytics

class CaptureViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    var captureSession: AVCaptureSession!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    var barCodeFrameView = UIView()
    
    @IBAction func cancelCaptureButton(sender: AnyObject) {
    
        self.dismissViewControllerAnimated(true, completion: nil)
    
    }
    
    @IBAction func segueBackToCaptureForDismissingVC(segue: UIStoryboardSegue) {
    
        self.dismissViewControllerAnimated(true, completion: nil)
        
    }
    
    @IBOutlet weak var messageLabel: UILabel!
    //@IBOutlet weak var barCodeFrameView: UIView!
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        barCodeFrameView.layer.borderColor = UIColor.greenColor().CGColor
        barCodeFrameView.layer.borderWidth = 2
        self.view.addSubview(barCodeFrameView)
        self.view.bringSubviewToFront(barCodeFrameView)
    
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set UI
        self.navigationController?.title = "Find the barcode!"
        self.navigationController?.navigationBar.barTintColor = UIColor(red: 43.0/255.0, green: 74.0/255.0, blue: 109.0/255.0, alpha: 1.0)
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        self.navigationController?.navigationBar.layer.shadowColor = UIColor.blackColor().CGColor
        self.navigationController?.navigationBar.layer.shadowOffset = CGSizeMake(0, 1)
        self.navigationController?.navigationBar.layer.shadowOpacity = 0.5
        
        // FIrebase Analytics Event Log
        var nameForFIRAnalytics: String = ""
        let defaults = NSUserDefaults.standardUserDefaults()
        if let username = defaults.stringForKey("username") {
            nameForFIRAnalytics = username
        } else {
            nameForFIRAnalytics = "username_missing"
        }
        FIRAnalytics.logEventWithName("enter_capture", parameters: ["username": nameForFIRAnalytics])
        
        // Create a capture session
        captureSession = AVCaptureSession()
        
        // 取得 AVCaptureDevice 類別的實體來初始化一個device物件，並提供video
        // 作為媒體型態參數
        let captureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        
        // Create input object
        let videoInput: AVCaptureDeviceInput?
        
        do {
            videoInput = try AVCaptureDeviceInput(device: captureDevice)
        } catch {
            print("error caught with AVCapture device")
            return
        }
        
        // Add input to the session
        if (captureSession!.canAddInput(videoInput)) {
            captureSession!.addInput(videoInput)
        } else {
            print("error input to the session")
        }
        
        // Create output object.
        let metadataOutput = AVCaptureMetadataOutput()
        
        // Add output to the session.
        if (captureSession!.canAddOutput(metadataOutput)) {
            captureSession!.addOutput(metadataOutput)
            metadataOutput.metadataObjectTypes = [AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeUPCECode]
            // if all kinds of types -> metadataOutput.availableMetadataObjectTypes
            // Send captured data to the delegate object via a serial queue.
            metadataOutput.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
            
        } else {
            print("error while generating output")
        }
        
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer?.frame = view.layer.bounds
        videoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        view.layer.addSublayer(videoPreviewLayer)
        captureSession.startRunning()
        
    }
    
    //    override func viewWillAppear(animated: Bool) {
    //
    //        super.viewWillAppear(animated)
    //        if (captureSession?.running == false) {
    //            captureSession.startRunning()
    //        }
    //    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (captureSession?.running == true) {
            captureSession.stopRunning()
        }
    }
    
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        
        // Get the first object from the metadataObjects array.
        if let barcodeData = metadataObjects.first {
            // Turn it into machine readable code
            let barcodeReadable = barcodeData as? AVMetadataMachineReadableCodeObject;
            if let readableCode = barcodeReadable {
                
                // Send the barcode as a string to barcodeDetected()
                barcodeDetected(readableCode.stringValue);
            }
            
            // Vibrate the device to give the user some feedback.
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            
            // Avoid a very buzzy device.
            captureSession.stopRunning()
            
            }
        
    }
    
    var barCodeToAnalyze = ""
    func barcodeDetected(code: String) {
        
        self.barCodeToAnalyze = code
        print(barCodeToAnalyze)
        
        //searchForBarcodeMatch(code)
        
        self.performSegueWithIdentifier("segueToCamera", sender: nil)
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "segueToCamera" {
            let destinationViewController = segue.destinationViewController as! CameraViewController;
            destinationViewController.receivedBarCode = barCodeToAnalyze
            
        }
        
    }
    
}




