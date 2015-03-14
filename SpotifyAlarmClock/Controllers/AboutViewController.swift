//
//  AboutViewController.swift
//  Alarm Clock
//
//  Created by Niels Vroegindeweij on 09-03-15.
//  Copyright (c) 2015 Niels Vroegindeweij. All rights reserved.
//

import UIKit

class AboutViewController: UITableViewController {

    @IBOutlet weak private var lbVersion : UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        lbVersion.text = (NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as String)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        switch(indexPath.row) {
        case 2:
            UIApplication.sharedApplication().openURL(NSURL(string: "https://www.linkedin.com/pub/niels-vroegindeweij/21/980/24b")!)
        case 3:
            UIApplication.sharedApplication().openURL(NSURL(string: "http://alarmclock.startsmart.nl")!)
        default:
            break
        }
    }

}
