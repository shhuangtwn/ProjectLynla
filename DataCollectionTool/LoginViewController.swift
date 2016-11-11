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
import FirebaseAnalytics
import FBSDKLoginKit
import Crashlytics


class LoginViewController: UIViewController, FBSDKLoginButtonDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var loginButton: FBSDKLoginButton!
    
    @IBAction func segueToHome(segue: UIStoryboardSegue) {
        viewDidLoad()
    }

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var loginSpinner: UIActivityIndicatorView!
    @IBOutlet weak var createNewAccountButton: UIButton!
    @IBOutlet weak var loginWithEmailButton: UIButton!
    @IBOutlet weak var loginWithoutFBButton: UIButton!
    @IBAction func loginWithoutFBButton(sender: UIButton) {
    
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let CaptureViewController: UIViewController = mainStoryboard.instantiateViewControllerWithIdentifier("NaviToCaptureView")
        
        self.presentViewController(CaptureViewController, animated: true, completion: nil)
    
    }
    
    @IBAction func createNewAccount(sender: UIButton) {
    
        alertForCreateAccount()
    
    }
    
    @IBAction func loginWithEmail(sender: UIButton) {
        
        let email = emailTextField.text
        let password = passwordTextField.text
        
        self.loginWithEmailButton.hidden = true
        self.loginSpinner.hidden = false
        self.loginSpinner.startAnimating()
        
        if email != "" && password != "" {
            FIRAuth.auth()?.signInWithEmail(email!, password: password!, completion: { (user, error) in
                
                self.saveUserToNSUserDefaults()
                
            })
        } else {
            
            signupErrorAlert("Oops!", message: "Please make sure you entered the right email and password")
            
            self.loginWithEmailButton.hidden = false
            self.loginSpinner.hidden = true
            self.loginSpinner.stopAnimating()
            
        }
    }
    
    
//    var loginButton: FBSDKLoginButton = FBSDKLoginButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loginWithoutFBButton.layer.borderColor = UIColor.whiteColor().CGColor
        self.loginWithoutFBButton.layer.borderWidth = 1
        self.loginWithoutFBButton.layer.cornerRadius = 2
        
        self.loginButton.hidden = true
        self.loginButton.layer.shadowColor = UIColor.blackColor().CGColor
        self.loginButton.layer.shadowOpacity = 0.5
        self.loginButton.layer.cornerRadius = 2
        self.loginButton.layer.shadowOffset = CGSizeMake(0.0, 1.0)
        self.loginButton.layer.shadowRadius = 1.5
        let path = UIBezierPath(roundedRect: self.loginButton.bounds, cornerRadius: 2).CGPath
        self.loginButton.layer.shadowPath = path
        
//        self.loginWithEmailButton.hidden = true
//        self.loginWithEmailButton.layer.shadowColor = UIColor.blackColor().CGColor
//        self.loginWithEmailButton.layer.cornerRadius = 2
//        self.loginWithEmailButton.layer.shadowOpacity = 0.5
//        self.loginWithEmailButton.layer.shadowOffset = CGSizeMake(0.0, 1.0)
//        self.loginWithEmailButton.layer.shadowRadius = 1.5
//        let path2 = UIBezierPath(roundedRect: self.loginWithEmailButton.bounds, cornerRadius: 2).CGPath
//        self.loginWithEmailButton.layer.shadowPath = path2
        
        self.loginWithEmailButton.layer.borderColor = UIColor.whiteColor().CGColor
        self.loginWithEmailButton.layer.borderWidth = 1
        self.loginWithEmailButton.layer.cornerRadius = 2
        
        FIRAuth.auth()?.addAuthStateDidChangeListener { auth, user in
            if user != nil {
                
                let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let profileViewController: UIViewController = mainStoryboard.instantiateViewControllerWithIdentifier("ProfileNavi")
                
                self.presentViewController(profileViewController, animated: true, completion: nil)
                
            } else {
                
//                self.loginButton.center = self.view.center
                
                
                self.loginButton.readPermissions = ["public_profile", "email", "user_friends"]
                self.loginButton.delegate = self
                self.view.addSubview(self.loginButton)
                
                self.loginButton.hidden = false
                self.loginWithEmailButton.hidden = false

            }
        }
        
        // Move keyboard and view
        emailTextField.delegate = self
        passwordTextField.delegate = self
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(LoginViewController.dismissKeyboard)))
        
    }
    
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        
        print("user login")
        self.loginButton.hidden = true
        self.loginWithEmailButton.hidden = true

        loginSpinner.startAnimating()
        
        if (error != nil) {
            // handle error
            self.loginButton.hidden = false
            self.loginWithEmailButton.hidden = false

            loginSpinner.stopAnimating()
            
        } else if (result.isCancelled) {
            //cancel case
            self.loginButton.hidden = false
            self.loginWithEmailButton.hidden = false

            loginSpinner.stopAnimating()
            
        } else {
            // login
            let credential = FIRFacebookAuthProvider.credentialWithAccessToken(FBSDKAccessToken.currentAccessToken().tokenString)
            FIRAuth.auth()?.signInWithCredential(credential) { (user, error) in
                
                //check if first time login -> set initial rating if new
                self.checkIfNewUserLogin(self.getUserKey())
                self.saveUserToNSUserDefaults()

                print("logged in firebase: \(user)")
                
            }
        }
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        
        try! FIRAuth.auth()!.signOut()
        
    }
    
    
    func alertForCreateAccount() {
        
        var usernameCreated: String = ""
        var emailCreated: String = ""
        var passwordCreated: String = ""
       
        
        let alert = UIAlertController(title: "Register New Account", message: "", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Register", style: UIAlertActionStyle.Default, handler: { action in
            
            let usernameTextField = alert.textFields![0] as UITextField
            let emailTextField = alert.textFields![1] as UITextField
            let passwardTextField = alert.textFields![2] as UITextField
            
            if let name = usernameTextField.text {usernameCreated = name}
            if let email = emailTextField.text {emailCreated = email}
            if let password = passwardTextField.text {passwordCreated = password}
            
            if usernameCreated.isBlank != true && emailCreated.isEmail && passwordCreated.isBlank != true {

                FIRAuth.auth()?.createUserWithEmail(emailCreated, password: passwordCreated, completion: { (user, error) in
                    
                    self.loginButton.hidden = true
                    self.loginWithEmailButton.hidden = true
                    self.loginSpinner.startAnimating()
                    
                    if error != nil {
                        self.signupErrorAlert("Oops!", message: "Please make sure you have entered the correct format")
                       
                        self.loginButton.hidden = false
                        self.loginWithEmailButton.hidden = false
                        self.loginSpinner.hidden = true
                        
                    } else {
                        
                        FIRAuth.auth()?.signInWithEmail(emailCreated, password: passwordCreated, completion: { (user, error) in
                            
                            if error != nil {
                            
                                self.loginButton.hidden = false
                                self.loginWithEmailButton.hidden = false
                                self.loginSpinner.hidden = true
                                
                                self.signupErrorAlert("Oops!", message: "Please try to login again")
                                
                            } else {
                                
                                self.loginButton.hidden = false
                                self.loginWithEmailButton.hidden = false
                                self.loginSpinner.hidden = true
                                
                                self.addUsernameToAccount(usernameCreated)
                            
                            }
                            
                        })
                        
                    }
                    
                })
                
            } else {
            
                self.signupErrorAlert("Oops!", message: "Don't forget to enter your email, password, and username properly")
                
            }
            
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: { action in
        }))
        
        alert.addTextFieldWithConfigurationHandler { (textField : UITextField!) -> Void in
            textField.placeholder = "Username"
        }
        alert.addTextFieldWithConfigurationHandler { (textField : UITextField!) -> Void in
            textField.placeholder = "Your_email@mail.com"
        }
        alert.addTextFieldWithConfigurationHandler { (textField : UITextField!) -> Void in
            textField.placeholder = "Password"
            textField.secureTextEntry = true
        }
        
        self.presentViewController(alert, animated: true, completion: nil)
        
    }
    
    func signupErrorAlert(title: String, message: String) {
        
        // Called upon signup error to let the user know signup didn't work.
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        let action = UIAlertAction(title: "Ok", style: .Default, handler: nil)
        alert.addAction(action)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func addUsernameToAccount(username: String) {
    
        let user = FIRAuth.auth()?.currentUser
        if let user = user {
            let changeRequest = user.profileChangeRequest()
            
            changeRequest.displayName = username
            
            changeRequest.commitChangesWithCompletion { error in
                if error != nil {
                    self.signupErrorAlert("Oops!", message: "Cannot set username")
                } else {
                    
                    self.postUserInitDataToCloud(user.uid, totalItems: 0, avgPT: 3.0, avgTX: 3.0, avgFL: 3.0)
                    self.saveUserToNSUserDefaults()
                }
            }
        }
        
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
                
//                FIRAnalyticsl.logEvent(withName: kFIREventLogin, parameters: [
//                    kFIRParameterContentType: "old_user" ,
//                    kFIRParameterItemID: "2" as NSObject
//                    ])
                
            } else {
            
                self.postUserInitDataToCloud(uid, totalItems: 0, avgPT: 3.0, avgTX: 3.0, avgFL: 3.0)
                print("new user welcome to Lynla!")
                
//                FIRAnalytics.logEvent(withName: kFIREventLogin, parameters: [
//                    kFIRParameterContentType: "new_user" ,
//                    kFIRParameterItemID: "1" as NSObject
//                    ])
                
            }
            
        })
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
    
    func logUser(uid: String) {
        // TODO: Use the current user's information
        //Crashlytics.sharedInstance().setUserEmail("user@fabric.io")
        Crashlytics.sharedInstance().setUserIdentifier(uid)
        //Crashlytics.sharedInstance().setUserName("Test User")
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

    // Keyboard setup
    func dismissKeyboard() {
        emailTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        emailTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()

        return true
    }
    
//    func textFieldDidBeginEditing(textField: UITextField) {
//        animateViewMoving(true, moveValue: 100)
//    }
//    func textFieldDidEndEditing(textField: UITextField) {
//        animateViewMoving(false, moveValue: 100)
//    }
//    
//    func animateViewMoving (up:Bool, moveValue :CGFloat){
//        let movementDuration:NSTimeInterval = 0.3
//        let movement:CGFloat = ( up ? -moveValue : moveValue)
//        UIView.beginAnimations( "animateView", context: nil)
//        UIView.setAnimationBeginsFromCurrentState(true)
//        UIView.setAnimationDuration(movementDuration )
//        self.view.frame = CGRectOffset(self.view.frame, 0,  movement)
//        UIView.commitAnimations()
//    }
    
}

extension String {
    
    //To check text field or String is blank or not
    var isBlank: Bool {
        get {
            let trimmed = stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
            return trimmed.isEmpty
        }
    }
    
    //Validate Email
    var isEmail: Bool {
        do {
            let regex = try NSRegularExpression(pattern: "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}", options: .CaseInsensitive)
            return regex.firstMatchInString(self, options: NSMatchingOptions(rawValue: 0), range: NSMakeRange(0, self.characters.count)) != nil
        } catch {
            return false
        }
    }
}