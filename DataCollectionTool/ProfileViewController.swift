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
import SwiftCharts


class ProfileViewController: UIViewController {
    
    @IBAction func naviBackButton(sender: AnyObject) {
    self.navigationController?.popViewControllerAnimated(true)
    }
    @IBOutlet weak var totalRatedLabel: UILabel!
    @IBOutlet weak var avgFlavorLabel: UILabel!
    @IBOutlet weak var avgTextureLabel: UILabel!
    
    @IBOutlet weak var spinnerUI: UIActivityIndicatorView!
    //    var receivedTTL: Int = 0
    //    var receivedTX: Double = 0.0
    //    var receivedFL: Double = 0.0
    
    var receivedItemArray = [ItemModel]()
    
    @IBOutlet weak var scatterChartView: UIView!
    private var chart: Chart?
    private let colorBarHeight: CGFloat = 50
    private let useViewsLayer = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        self.navigationController?.navigationBar.layer.shadowColor = UIColor.blackColor().CGColor
        self.navigationController?.navigationBar.layer.shadowOffset = CGSizeMake(0, 1)
        self.navigationController?.navigationBar.layer.shadowOpacity = 0.5
        
        spinnerUI.hidden = false
        spinnerUI.startAnimating()
        
        runBubbleChart(receivedItemArray)

    }
    
    func runBubbleChart(itemArray: [ItemModel]) {
        
        spinnerUI.stopAnimating()
        spinnerUI.hidden = true
        
        let frame = ChartDefaults.chartFrame(self.scatterChartView.frame)
        var chartFrame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height)
        let colorBar = ColorBar(frame: CGRectMake(0, chartFrame.origin.y + chartFrame.size.height, chartFrame.size.width, self.colorBarHeight), c1: UIColor.redColor(), c2: UIColor.greenColor())
        //        let colorBar = ColorBar(frame: CGRectMake(0, chartFrame.origin.y + chartFrame.size.height, self.scatterChartView.frame.size.width, self.colorBarHeight), c1: UIColor.redColor(), c2: UIColor.greenColor())
        //    self.view.addSubview(colorBar)
        
        
        let labelSettings = ChartLabelSettings(font: ChartDefaults.labelFont)
        
        func toColor(percentage: Double) -> UIColor {
            return colorBar.colorForPercentage(percentage).colorWithAlphaComponent(0.6)
        }
        
        var rawData: [(Double, Double, Double, UIColor)] = []
        
        for item in itemArray {
            let colorIndex: Double = (item.itemTX + item.itemFL)/10
            let itemTuple = (item.itemFL, item.itemTX, item.itemPT, toColor(colorIndex))
            rawData.append(itemTuple)
        }
        
//        let rawData: [(Double, Double, Double, UIColor)] = [(1, 2, 1, toColor(0)),(2.1, 5, 2, toColor(0)),(4, 4, 3, toColor(0)),(2.3, 5, 4, toColor(0)),(2, 4.5, 5, toColor(0))]
        
        let chartPoints: [ChartPointBubble] = rawData.map{ChartPointBubble(x: ChartAxisValueDouble($0, labelSettings: labelSettings), y: ChartAxisValueDouble($1), diameterScalar: $2, bgColor: $3)}
        
        let xValues = (0).stride(through: 6, by: 1).map {ChartAxisValueInt($0, labelSettings: labelSettings)}
        let yValues = (0).stride(through: 6, by: 1).map {ChartAxisValueInt($0, labelSettings: labelSettings)}
        
        let xModel = ChartAxisModel(axisValues: xValues, axisTitleLabel: ChartAxisLabel(text: "<< Sweeter                   FLAVOR                    Bitter >>", settings: labelSettings))
        let yModel = ChartAxisModel(axisValues: yValues, axisTitleLabel: ChartAxisLabel(text: "<< Smoother                   TEXTURE                   Thicker >>", settings: labelSettings.defaultVertical()))
        
        let coordsSpace = ChartCoordsSpaceLeftBottomSingleAxis(chartSettings: ChartDefaults.chartSettings, chartFrame: chartFrame, xModel: xModel, yModel: yModel)
        let (xAxis, yAxis, innerFrame) = (coordsSpace.xAxis, coordsSpace.yAxis, coordsSpace.chartInnerFrame)
        
        let bubbleLayer = self.bubblesLayer(xAxis: xAxis, yAxis: yAxis, chartInnerFrame: innerFrame, chartPoints: chartPoints)
        
        let guidelinesLayerSettings = ChartGuideLinesDottedLayerSettings(linesColor: UIColor.blackColor(), linesWidth: ChartDefaults.guidelinesWidth)
        let guidelinesLayer = ChartGuideLinesDottedLayer(xAxis: xAxis, yAxis: yAxis, innerFrame: innerFrame, settings: guidelinesLayerSettings)
        
        let guidelinesHighlightLayerSettings = ChartGuideLinesDottedLayerSettings(linesColor: UIColor.redColor(), linesWidth: 1, dotWidth: 4, dotSpacing: 0)
        let guidelinesHighlightLayer = ChartGuideLinesForValuesDottedLayer(xAxis: xAxis, yAxis: yAxis, innerFrame: innerFrame, settings: guidelinesHighlightLayerSettings, axisValuesX: [ChartAxisValueDouble(3)], axisValuesY: [ChartAxisValueDouble(3)])
        
        let chart = Chart(
            frame: chartFrame,
            layers: [
                xAxis,
                yAxis,
                guidelinesLayer,
                guidelinesHighlightLayer,
                bubbleLayer
            ]
        )
        
        self.scatterChartView.addSubview(chart.view)
        //        self.view.addSubview(chart.view)
        self.chart = chart
        
        
    }
    
    // We can use a view based layer for easy animation (or interactivity), in which case we use the default chart points layer with a generator to create bubble views.
    // On the other side, if we don't need animation or want a better performance, we use ChartPointsBubbleLayer, which instead of creating views, renders directly to the chart's context.
    private func bubblesLayer(xAxis xAxis: ChartAxisLayer, yAxis: ChartAxisLayer, chartInnerFrame: CGRect, chartPoints: [ChartPointBubble]) -> ChartLayer {
        
        let maxBubbleDiameter: Double = 150, minBubbleDiameter: Double = 80
        
        if self.useViewsLayer == true {
            
            let (minDiameterScalar, maxDiameterScalar): (Double, Double) = chartPoints.reduce((min: 0, max: 0)) {tuple, chartPoint in
                (min: min(tuple.min, chartPoint.diameterScalar), max: max(tuple.max, chartPoint.diameterScalar))
            }
            
            let diameterFactor = (maxBubbleDiameter - minBubbleDiameter) / (maxDiameterScalar - minDiameterScalar)
            
            return ChartPointsViewsLayer(xAxis: xAxis, yAxis: yAxis, innerFrame: chartInnerFrame, chartPoints: chartPoints, viewGenerator: {(chartPointModel, layer, chart) -> UIView? in
                
                let diameter = CGFloat(chartPointModel.chartPoint.diameterScalar * diameterFactor)
                
                let circleView = ChartPointEllipseView(center: chartPointModel.screenLoc, diameter: diameter)
                circleView.fillColor = chartPointModel.chartPoint.bgColor.colorWithAlphaComponent(0.2)
                circleView.borderColor = UIColor.blackColor().colorWithAlphaComponent(0)
                circleView.borderWidth = 1
                circleView.animDelay = Float(chartPointModel.index) * 0.2
                circleView.animDuration = 1.2
                circleView.animDamping = 0.4
                circleView.animInitSpringVelocity = 0.8
                return circleView
            })
            
        } else {
            return ChartPointsBubbleLayer(xAxis: xAxis, yAxis: yAxis, innerFrame: chartInnerFrame, chartPoints: chartPoints)
        }
    }
    
    class ColorBar: UIView {
        
        let dividers: [CGFloat]
        
        let gradientImg: UIImage
        
        lazy var imgData: UnsafePointer<UInt8> = {
            let provider = CGImageGetDataProvider(self.gradientImg.CGImage)
            let pixelData = CGDataProviderCopyData(provider)
            return CFDataGetBytePtr(pixelData)
        }()
        
        init(frame: CGRect, c1: UIColor, c2: UIColor) {
            
            let gradient: CAGradientLayer = CAGradientLayer()
            gradient.frame = CGRectMake(0, 0, frame.width, 6)
            gradient.colors = [UIColor.blueColor().CGColor,
                               UIColor.cyanColor().CGColor,
                               UIColor.yellowColor().CGColor,
                               UIColor.redColor().CGColor]
            gradient.startPoint = CGPointMake(0, 0.5)
            gradient.endPoint = CGPointMake(1.0, 0.5)
            
            
            let imgHeight = 1
            let imgWidth = Int(gradient.bounds.size.width)
            
            let bitmapBytesPerRow = imgWidth * 4
            
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedLast.rawValue).rawValue
            
            let context = CGBitmapContextCreate (nil,
                                                 imgWidth,
                                                 imgHeight,
                                                 8,
                                                 bitmapBytesPerRow,
                                                 colorSpace,
                                                 bitmapInfo)
            
            UIGraphicsBeginImageContext(gradient.bounds.size)
            gradient.renderInContext(context!)
            let gradientImg = UIImage(CGImage: CGBitmapContextCreateImage(context)!)
            
            UIGraphicsEndImageContext()
            self.gradientImg = gradientImg
            
            let segmentSize = gradient.frame.size.width / 6
            self.dividers = Array(segmentSize.stride(through: gradient.frame.size.width, by: segmentSize))
            
            super.init(frame: frame)
            
            self.layer.insertSublayer(gradient, atIndex: 0)
            
            let numberFormatter = NSNumberFormatter()
            numberFormatter.maximumFractionDigits = 2
            
            for x in segmentSize.stride(through: gradient.frame.size.width - 1, by: segmentSize) {
                
                let dividerW: CGFloat = 1
                let divider = UIView(frame: CGRectMake(x - dividerW / 2, 25, dividerW, 5))
                divider.backgroundColor = UIColor.blackColor()
                self.addSubview(divider)
                
                let text = "\(numberFormatter.stringFromNumber(x / gradient.frame.size.width)!)"
                let labelWidth = ChartUtils.textSize(text, font: ChartDefaults.labelFont).width
                let label = UILabel()
                label.center = CGPointMake(x - labelWidth / 2, 30)
                label.font = ChartDefaults.labelFont
                label.text = text
                label.sizeToFit()
                
                self.addSubview(label)
            }
        }
        
        func colorForPercentage(percentage: Double) -> UIColor {
            
            let data = self.imgData
            
            let xNotRounded = self.gradientImg.size.width * CGFloat(percentage)
            let x = 4 * (floor(abs(xNotRounded / 4)))
            let pixelIndex = Int(x * 4)
            
            let color = UIColor(
                red: CGFloat(data[pixelIndex + 0]) / 255.0,
                green: CGFloat(data[pixelIndex + 1]) / 255.0,
                blue: CGFloat(data[pixelIndex + 2]) / 255.0,
                alpha: CGFloat(data[pixelIndex + 3]) / 255.0
            )
            return color
        }
        
        required init(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
//    
//    func fetchUserProfile(uid: String) {
//        
//        let databaseRef = FIRDatabase.database().reference()
//        databaseRef.child("users").queryOrderedByChild(uid).observeSingleEventOfType(.Value , withBlock: { (snapshot) in
//            
//            guard let users = snapshot.value as? NSDictionary else{
//                fatalError("not NSDictionary")
//            }
//            
//            guard let userDict = users.valueForKey(uid) as? NSDictionary else {
//                fatalError("not key:[Dict]")
//            }
//            
//            guard
//                let totalItems = userDict.valueForKey("total_items") as? Int,
//                let avgTexture = userDict.valueForKey("avg_texture") as? Double,
//                let avgFlavor = userDict.valueForKey("avg_flavor") as? Double
//                else {return}
//            
//            self.totalRatedLabel.text = "You Rated \(String(totalItems)) beers"
//            self.avgTextureLabel.text = "Avg. Texture: \(String(avgTexture))"
//            self.avgFlavorLabel.text = "Avg. Flavor: \(String(avgFlavor))"
//            
//        })
//        
//        
//    }
    
}
