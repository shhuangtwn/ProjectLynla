//
//  LoginViewController.swift
//  DataCollectionTool
//
//  Created by Bryan Huang on 2016/10/11.
//  Copyright © 2016年 Steven Hunag. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import FBSDKLoginKit

class LoginViewController: UIViewController, FBSDKLoginButtonDelegate {
    
    @IBOutlet weak var loginSpinner: UIActivityIndicatorView!
    
    
    var loginButton: FBSDKLoginButton = FBSDKLoginButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loginButton.hidden = true
        
        FIRAuth.auth()?.addAuthStateDidChangeListener { auth, user in
            if user != nil {
                
                let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let startingViewController: UIViewController = mainStoryboard.instantiateViewControllerWithIdentifier("NavigationViewController")
                
                self.presentViewController(startingViewController, animated: true, completion: nil)
                
            } else {
                
                self.loginButton.center = self.view.center
                self.loginButton.readPermissions = ["public_profile", "email", "user_friends"]
                self.loginButton.delegate = self
                self.view.addSubview(self.loginButton)
                
                self.loginButton.hidden = false
                
            }
        }
    }
    
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        
        print("user login")
        self.loginButton.hidden = true
        loginSpinner.startAnimating()
        
        if (error != nil) {
            // handle error
            self.loginButton.hidden = false
            loginSpinner.stopAnimating()
            
        } else if (result.isCancelled) {
            //cancel case
            self.loginButton.hidden = false
            loginSpinner.stopAnimating()
            
        } else {
            // login
            let credential = FIRFacebookAuthProvider.credentialWithAccessToken(FBSDKAccessToken.currentAccessToken().tokenString)
            FIRAuth.auth()?.signInWithCredential(credential) { (user, error) in
                
                //check if first time login -> set initial rating if new
                self.checkIfNewUserLogin(self.getUserKey())

                print("logged in firebase: \(user)")
                
            }
        }
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        
        try! FIRAuth.auth()!.signOut()
        
    }
    
    func checkIfNewUserLogin(uid: String) {
    
        let databaseRef = FIRDatabase.database().reference()
        databaseRef.child("users").observeSingleEventOfType(.Value , withBlock: { (snapshot) in
                        
            guard let users = snapshot.value as? NSDictionary else{
                fatalError("not NSDictionary")
            }
            
            guard let keys = users.allKeys as? [String] else{
                fatalError("key error")
            }
            
            if keys.contains(uid){
                
                print("user welcome back - do nothing")
                
            } else {
            
                self.postUserInitDataToCloud(uid, totalItems: 0, avgPT: 3.0, avgTX: 3.0, avgFL: 3.0)
                print("new user welcome to Lynla!")

            }
            
        })
    }
    
    func postUserInitDataToCloud(uid: String, totalItems: Int, avgPT: Double, avgTX: Double, avgFL: Double) {
        let databaseRef = FIRDatabase.database().reference()
        let postUserRef = databaseRef.child("users").child(uid)
        
        let postUserData: [String: AnyObject] = [
            "total_items": totalItems,
            "avg_point": avgPT,
            "avg_texture": avgTX,
            "avg_flavor": avgFL]
        
        postUserRef.setValue(postUserData)
    }
    
    func getUserKey() -> String {
        var uuidString: String = ""
        if let user = FIRAuth.auth()?.currentUser {
            //            let name = user.displayName
            //            let email = user.email
            //            let photoUrl = user.photoURL
            uuidString = user.uid;  // The user's ID, unique to the Firebase project.
            // Do NOT use this value to authenticate with
            // your backend server, if you have one. Use
            // getTokenWithCompletion:completion: instead.
        } else {
            // No user is signed in.
            uuidString = "user UID missing"
        }
        return uuidString
    }

}