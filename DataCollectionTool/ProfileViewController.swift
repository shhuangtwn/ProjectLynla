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
    
    @IBOutlet weak var barChartView: BarChartView!
    var months: [String]!

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
        
        // Set Chart UI
        months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        let unitsSold = [20.0, 4.0, 6.0, 3.0, 12.0, 16.0, 4.0, 18.0, 2.0, 4.0, 5.0, 4.0]
        
        setChart(months, values: unitsSold)
    
    }
    
    func setChart(dataPoints: [String], values: [Double]) {
        barChartView.noDataText = "Calculating..."
        
        var dataEntries: [BarChartDataEntry] = []
        
        for i in 0..<dataPoints.count {
            let dataEntry = BarChartDataEntry(value: values[i], xIndex: i)
            dataEntries.append(dataEntry)
        }
        
        let chartDataSet = BarChartDataSet(yVals: dataEntries, label: "Units Sold")
        let chartData = BarChartData(xVals: months, dataSet: chartDataSet)
        barChartView.data = chartData
        chartDataSet.colors = ChartColorTemplates.material()
        barChartView.xAxis.labelPosition = .Bottom
        barChartView.animate(xAxisDuration: 1.0, yAxisDuration: 1.0)
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
