//
//  StartScreenViewController.swift
//  Alarm Clock
//
//  Created by Niels Vroegindeweij on 10-03-15.
//  Copyright (c) 2015 Niels Vroegindeweij. All rights reserved.
//

import UIKit

class StartScreenViewController: UITableViewController, UIAlertViewDelegate {

    @IBOutlet weak var loginCell : UITableViewCell!
    @IBOutlet weak var noSpotifyCell : UITableViewCell!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.setNeedsStatusBarAppearanceUpdate()
        
        //Set background
        let tempImageView = UIImageView(image: UIImage(named: "LoginBackground"))
        tempImageView.frame = self.tableView.frame
        self.tableView.backgroundView = tempImageView;
        
        //Set disclosure indicators
        loginCell.accessoryView = UIImageView(image: UIImage(named: "DisclosureIndicator"))
        noSpotifyCell.accessoryView = UIImageView(image: UIImage(named: "DisclosureIndicator"))
        
        //Set select cell background
        let bgColorView = UIView()
        bgColorView.backgroundColor = UIColor.grayColor()
        loginCell.selectedBackgroundView = bgColorView
        noSpotifyCell.selectedBackgroundView = bgColorView
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        UIDevice.currentDevice().setValue(UIInterfaceOrientation.Portrait.rawValue, forKey: "orientation")
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - Alert view delegate
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex == 1 {
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "UseAlarmClockWithoutSpotify")
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    // MARK: - Table view delegate
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        switch indexPath.row {
        case 1: //Linked In
            let alert = UIAlertView(title: "Spotify Usage",
                                    message: "Are you sure you want to use the Alarm Clock without Spotify features? You can set your credentials afterwards via the settings menu.",
                                    delegate: self,
                                    cancelButtonTitle: "No",
                                    otherButtonTitles: "Yes")

            alert.show()
        default:
            break
        }
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.backgroundColor = UIColor.clearColor()
    }

}
