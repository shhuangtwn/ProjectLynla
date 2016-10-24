//
//  ProfileViewController.swift
//  DataCollectionTool
//
//  Created by Bryan Huang on 2016/10/11.
//  Copyright © 2016年 Steven Hunag. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import Charts

class ProfileViewController: UIViewController {

    @IBOutlet weak var totalRatedLabel: UILabel!
    @IBOutlet weak var avgFlavorLabel: UILabel!
    @IBOutlet weak var avgTextureLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.navigationBar.hidden = false

        // Get user ID
        if let user = FIRAuth.auth()?.currentUser {
            let name = user.displayName
            //let email = user.email
            let photoUrl = user.photoURL
            let uid = user.uid; 
          
            self.nameLabel.text = name
            if let photoData = NSData(contentsOfURL: photoUrl!) {
                self.profileImageView.image = UIImage(data: photoData)
            }
            
            fetchUserProfile(uid)
            
        } else {
            // No user is signed in.
        }
        
    
    }
    
    
    
    func fetchUserProfile(uid: String) {
    
        let databaseRef = FIRDatabase.database().reference()
        databaseRef.child("users").queryOrderedByChild(uid).observeSingleEventOfType(.Value , withBlock: { (snapshot) in
            
            print(snapshot)
            
            guard let users = snapshot.value as? NSDictionary else{
                fatalError("not NSDictionary")
            }
        
            guard let userDict = users.valueForKey(uid) as? NSDictionary else {
                fatalError("not key:[Dict]")
            }
            
            guard
            let totalItems = userDict.valueForKey("total_items") as? Int,
            let avgTexture = userDict.valueForKey("avg_texture") as? Double,
            let avgFlavor = userDict.valueForKey("avg_flavor") as? Double
                else {return}
            
            self.totalRatedLabel.text = "You Rated \(String(totalItems)) beers"
            self.avgTextureLabel.text = "Avg. Texture: \(String(avgTexture))"
            self.avgFlavorLabel.text = "Avg. Flavor: \(String(avgFlavor))"
            
        })

    
    }
    
}
