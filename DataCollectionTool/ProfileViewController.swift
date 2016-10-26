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
import SwiftCharts

private enum MyExampleModelDataType {
    case Type0, Type1, Type2, Type3
}

private enum Shape {
    case Triangle, Square, Circle, Cross
}

class Env {
    
    static var iPad: Bool {
        return UIDevice.currentDevice().userInterfaceIdiom == .Pad
    }
}

struct ExamplesDefaults {
    
    static var chartSettings: ChartSettings {
        if Env.iPad {
            return self.iPadChartSettings
        } else {
            return self.iPhoneChartSettings
        }
    }
    
    private static var iPadChartSettings: ChartSettings {
        let chartSettings = ChartSettings()
        chartSettings.leading = 20
        chartSettings.top = 20
        chartSettings.trailing = 20
        chartSettings.bottom = 20
        chartSettings.labelsToAxisSpacingX = 10
        chartSettings.labelsToAxisSpacingY = 10
        chartSettings.axisTitleLabelsToLabelsSpacing = 5
        chartSettings.axisStrokeWidth = 1
        chartSettings.spacingBetweenAxesX = 15
        chartSettings.spacingBetweenAxesY = 15
        return chartSettings
    }
    
    private static var iPhoneChartSettings: ChartSettings {
        let chartSettings = ChartSettings()
        chartSettings.leading = 10
        chartSettings.top = 10
        chartSettings.trailing = 10
        chartSettings.bottom = 10
        chartSettings.labelsToAxisSpacingX = 5
        chartSettings.labelsToAxisSpacingY = 5
        chartSettings.axisTitleLabelsToLabelsSpacing = 4
        chartSettings.axisStrokeWidth = 0.2
        chartSettings.spacingBetweenAxesX = 8
        chartSettings.spacingBetweenAxesY = 8
        return chartSettings
    }
    
    static func chartFrame(containerBounds: CGRect) -> CGRect {
        return CGRectMake(0, 70, containerBounds.size.width, containerBounds.size.height - 70)
    }
    
    static var labelSettings: ChartLabelSettings {
        return ChartLabelSettings(font: ExamplesDefaults.labelFont)
    }
    
    static var labelFont: UIFont {
        return ExamplesDefaults.fontWithSize(Env.iPad ? 14 : 11)
    }
    
    static var labelFontSmall: UIFont {
        return ExamplesDefaults.fontWithSize(Env.iPad ? 12 : 10)
    }
    
    static func fontWithSize(size: CGFloat) -> UIFont {
        return UIFont(name: "Helvetica", size: size) ?? UIFont.systemFontOfSize(size)
    }
    
    static var guidelinesWidth: CGFloat {
        return Env.iPad ? 0.5 : 0.1
    }
    
    static var minBarSpacing: CGFloat {
        return Env.iPad ? 10 : 5
    }
}

class ProfileViewController: UIViewController {

    @IBOutlet weak var totalRatedLabel: UILabel!
    @IBOutlet weak var avgFlavorLabel: UILabel!
    @IBOutlet weak var avgTextureLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    
    @IBOutlet weak var scatterChartView: UIView!
    private var chart: Chart?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.navigationBar.hidden = false

        // Get user data
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
        let labelSettings = ChartLabelSettings(font: ExamplesDefaults.labelFont)
        
        let models: [(x: Double, y: Double, type: MyExampleModelDataType)] = [
            (246.56, 138.98, .Type1), (218.33, 132.71, .Type0),  (171.75, 135.92, .Type1), (236.93, 117.1, .Type2), (201.97, 135, .Type3), (265.41, 80.62, .Type3), (312.42, 96.21, .Type1), (232, 141.18, .Type0), (348.75, 132.65, .Type1),  (344.74, 136.65, .Type0)
        ]
        
        let layerSpecifications: [MyExampleModelDataType : (shape: Shape, color: UIColor)] = [
            .Type0 : (.Triangle, UIColor.redColor()),
            .Type1 : (.Square, UIColor.blueColor()),
            .Type2 : (.Circle, UIColor.greenColor()),
            .Type3 : (.Cross, UIColor.blackColor())
        ]
        
        let xValues = 0.stride(through: 6, by: 1).map {ChartAxisValueInt($0, labelSettings: labelSettings)}
        let yValues = 0.stride(through: 6, by: 1).map {ChartAxisValueInt($0, labelSettings: labelSettings)}
        
        let xModel = ChartAxisModel(axisValues: xValues, axisTitleLabel: ChartAxisLabel(text: "Texture", settings: labelSettings))
        let yModel = ChartAxisModel(axisValues: yValues, axisTitleLabel: ChartAxisLabel(text: "Flavor", settings: labelSettings.defaultVertical()))
        
        let chartFrame = ExamplesDefaults.chartFrame(self.view.bounds)
        let coordsSpace = ChartCoordsSpaceLeftBottomSingleAxis(chartSettings: ExamplesDefaults.chartSettings, chartFrame: chartFrame, xModel: xModel, yModel: yModel)
        let (xAxis, yAxis, innerFrame) = (coordsSpace.xAxis, coordsSpace.yAxis, coordsSpace.chartInnerFrame)
        
        let scatterLayers = self.toLayers(models, layerSpecifications: layerSpecifications, xAxis: xAxis, yAxis: yAxis, chartInnerFrame: innerFrame)
        
        let guidelinesLayerSettings = ChartGuideLinesDottedLayerSettings(linesColor: UIColor.blackColor(), linesWidth: ExamplesDefaults.guidelinesWidth)
        let guidelinesLayer = ChartGuideLinesDottedLayer(xAxis: xAxis, yAxis: yAxis, innerFrame: innerFrame, settings: guidelinesLayerSettings)
        
        let chart = Chart(
            frame: chartFrame,
            layers: [
                xAxis,
                yAxis,
                guidelinesLayer
                ] + scatterLayers
        )
        
        self.scatterChartView = chart.view
        self.view.addSubview(chart.view)
        self.chart = chart
        
        
    }
    
    private func toLayers(models: [(x: Double, y: Double, type: MyExampleModelDataType)], layerSpecifications: [MyExampleModelDataType : (shape: Shape, color: UIColor)], xAxis: ChartAxisLayer, yAxis: ChartAxisLayer, chartInnerFrame: CGRect) -> [ChartLayer] {
        
        // group chartpoints by type
        var groupedChartPoints: Dictionary<MyExampleModelDataType, [ChartPoint]> = [:]
        for model in models {
            let chartPoint = ChartPoint(x: ChartAxisValueDouble(model.x), y: ChartAxisValueDouble(model.y))
            if groupedChartPoints[model.type] != nil {
                groupedChartPoints[model.type]!.append(chartPoint)
                
            } else {
                groupedChartPoints[model.type] = [chartPoint]
            }
        }
        
        // create layer for each group
        let dim: CGFloat = Env.iPad ? 14 : 7
        let size = CGSizeMake(dim, dim)
        let layers: [ChartLayer] = groupedChartPoints.map {(type, chartPoints) in
            let layerSpecification = layerSpecifications[type]!
            switch layerSpecification.shape {
            case .Triangle:
                return ChartPointsScatterTrianglesLayer(xAxis: xAxis, yAxis: yAxis, innerFrame: chartInnerFrame, chartPoints: chartPoints, itemSize: size, itemFillColor: layerSpecification.color)
            case .Square:
                return ChartPointsScatterSquaresLayer(xAxis: xAxis, yAxis: yAxis, innerFrame: chartInnerFrame, chartPoints: chartPoints, itemSize: size, itemFillColor: layerSpecification.color)
            case .Circle:
                return ChartPointsScatterCirclesLayer(xAxis: xAxis, yAxis: yAxis, innerFrame: chartInnerFrame, chartPoints: chartPoints, itemSize: size, itemFillColor: layerSpecification.color)
            case .Cross:
                return ChartPointsScatterCrossesLayer(xAxis: xAxis, yAxis: yAxis, innerFrame: chartInnerFrame, chartPoints: chartPoints, itemSize: size, itemFillColor: layerSpecification.color)
            }
        }
        
        return layers
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
