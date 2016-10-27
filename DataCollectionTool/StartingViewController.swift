//
//  StartingViewController.swift
//  DataCollectionTool
//
//  Created by Bryan Huang on 2016/10/12.
//  Copyright © 2016年 Steven Hunag. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FirebaseAuth
import FirebaseDatabase
import Fabric
import Crashlytics

class StartingViewController: UIViewController {
    @IBAction func cancelToPlayersViewController(segue:UIStoryboardSegue) {
    }
    
    @IBAction func logoutButton(sender: UIButton) {
        
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
    
        // Set UI
        self.navigationController?.navigationBar.hidden = false

        // The Crashlytics button
        let button = UIButton(type: UIButtonType.RoundedRect)
        button.frame = CGRectMake(20, 80, 100, 30)
        button.setTitle("Crash", forState: UIControlState.Normal)
        button.tintColor = UIColor.redColor()
        button.addTarget(self, action: #selector(self.crashButtonTapped(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        view.addSubview(button)
        
        saveUserToNSUserDefaults()
            
    }
    
    @IBAction func crashButtonTapped(sender: AnyObject) {
        Crashlytics.sharedInstance().crash()
    }
    
    func saveUserToNSUserDefaults() {
        if let user = FIRAuth.auth()?.currentUser {
            let uid = user.uid
            let username = user.displayName
            
            let userDefault = NSUserDefaults.standardUserDefaults()
            userDefault.setObject(uid, forKey: "userUID")
            userDefault.setObject(username, forKey: "username")
            userDefault.synchronize()
            
            // Log user for Crashlytics
            self.logUser(uid)

        } else {
            // No user is signed in.
        }
    }
    
    func postUserToCloud(name: String, email: String, photoUrlString: String, uid: String) {
        let databaseRef = FIRDatabase.database().reference()
        let postUserRef = databaseRef.child("users").child(uid)
        
        let postUserData: [String: AnyObject] = [
            "name": name,
            "email": email,
            "image": photoUrlString]

        postUserRef.setValue(postUserData)
        
    }
    
    func logUser(uid: String) {
        // TODO: Use the current user's information
        //Crashlytics.sharedInstance().setUserEmail("user@fabric.io")
        Crashlytics.sharedInstance().setUserIdentifier(uid)
        //Crashlytics.sharedInstance().setUserName("Test User")
    }

    
}



