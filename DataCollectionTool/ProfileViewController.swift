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
    
    //@IBOutlet weak var barChartView: BarChartView!
    var dataValue: [String]!

    @IBOutlet weak var scatterChartView: ScatterChartView!
    
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
//        dataValue = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
//        let unitsSold = [20.0, 4.0, 6.0, 3.0, 12.0, 16.0, 4.0, 18.0, 2.0, 4.0, 5.0, 4.0]
//        setChart(dataValue, values: unitsSold)

//        let dataPoints = ["1", "2", "3", "4", "5"]
//        let value1 = [1.0,1.0,1.0,1.2,1.2]
//        let value2 = [5.2,5.2,5.2,5.2,5.2]
//        
//        drawChart(dataPoints, value1: value1, value2: value2)
    }
    
    func drawChart(dataPoints:[String] , value1 :[Double] , value2:[Double])
    {
        var dataEntries1:[ChartDataEntry] = []
        
        
        
        for i in 0..<value1.count {
            let dataEntry = ChartDataEntry(value:value1[i] , xIndex : i)
            dataEntries1.append(dataEntry)
        }
        
        var dataEntries2:[ChartDataEntry] = []
        
        for i in 0..<value2.count {
            let dataEntry = ChartDataEntry(value:value2[i] , xIndex : i)
            dataEntries2.append(dataEntry)
        }
        
        let dataSet1 = ScatterChartDataSet(yVals: dataEntries1, label: "Value1" )
        dataSet1 .setColor(UIColor.blueColor())
        let dataSet2 = ScatterChartDataSet(yVals: dataEntries2 ,label: "Value2")
        dataSet2.setColor(UIColor.greenColor())
        
        var bloodPressureDataSets = [ScatterChartDataSet]()
        bloodPressureDataSets.append(dataSet1)
        bloodPressureDataSets.append(dataSet2)
        
        let barChartData = ScatterChartData(xVals: dataPoints, dataSets: bloodPressureDataSets)
        
        scatterChartView.xAxis.labelPosition = .Bottom
        scatterChartView.rightAxis.enabled = true
        //barChart.legend.enabled=false
        scatterChartView.descriptionText=""
        scatterChartView.data = barChartData
        
    }
    
//    func setChart(dataPoints: [String], values: [Double]) {
//        scatterChartView.noDataText = "Calculating..."
//        
//        var dataEntries: [BarChartDataEntry] = []
//        
//        for i in 0..<dataPoints.count {
//            let dataEntry = BarChartDataEntry(value: values[i], xIndex: i)
//            dataEntries.append(dataEntry)
//        }
//        
//        let chartDataSet = BarChartDataSet(yVals: dataEntries, label: "Units Sold")
//        let chartData = BarChartData(xVals: dataValue, dataSet: chartDataSet)
//        scatterChartView.data = chartData
//        chartDataSet.colors = ChartColorTemplates.material()
//        scatterChartView.xAxis.labelPosition = .Bottom
//        
//        scatterChartView.animate(xAxisDuration: 1.0, yAxisDuration: 1.0)
//    }
    
    
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
