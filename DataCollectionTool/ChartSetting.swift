//
//  ChartSetting.swift
//  DataCollectionTool
//
//  Created by Bryan Huang on 2016/10/26.
//  Copyright © 2016年 freelance. All rights reserved.
//

import Foundation
import SwiftCharts

class Env {
    
    static var iPad: Bool {
        return UIDevice.currentDevice().userInterfaceIdiom == .Pad
    }
}

struct ChartDefaults {
    
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
        return CGRectMake(0, 70, containerBounds.size.width - 230, containerBounds.size.height)
        
    }
    
    static var labelSettings: ChartLabelSettings {
        return ChartLabelSettings(font: ChartDefaults.labelFont)
    }
    
    static var labelFont: UIFont {
        return ChartDefaults.fontWithSize(Env.iPad ? 14 : 11)
    }
    
    static var labelFontSmall: UIFont {
        return ChartDefaults.fontWithSize(Env.iPad ? 12 : 10)
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
