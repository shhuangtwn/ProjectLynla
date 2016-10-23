//
//  ContainerViewController.swift
//  DataCollectionTool
//
//  Created by Bryan Huang on 2016/10/23.
//  Copyright © 2016年 freelance. All rights reserved.
//

import UIKit

class ContainerViewController: UIViewController {

    @IBOutlet weak var containerProfile: UIView!
    @IBOutlet weak var containerList: UIView!
    
    enum ViewSwitch: Int {
        case profile = 0
        case list = 1
    }
    
    @IBAction func viewSwitcher(sender: UISegmentedControl) {
    
        let currentContainer = ViewSwitch(rawValue: sender.selectedSegmentIndex)!
    
        switch currentContainer {
        case .profile:
            containerProfile.alpha = 1
            containerList.alpha = 0
            
        case .list:
            containerProfile.alpha = 0
            containerList.alpha = 1
        
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        
    
    
    }

}
