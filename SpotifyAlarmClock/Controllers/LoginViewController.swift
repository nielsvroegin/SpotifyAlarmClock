//
//  LoginViewController.swift
//  Alarm Clock
//
//  Created by Niels Vroegindeweij on 14-03-15.
//  Copyright (c) 2015 Niels Vroegindeweij. All rights reserved.
//

import UIKit

class LoginViewController: UITableViewController, SPSessionDelegate, UITextFieldDelegate {

    @IBOutlet weak private var txtUsername : UITextField!
    @IBOutlet weak private var txtPassword : UITextField!
    @IBOutlet weak private var btLogin : UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //Make navigationbar completely transculent
        if let navController = self.navigationController {
            navController.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
            navController.navigationBar.shadowImage = UIImage()
            navController.navigationBar.translucent = true
            navController.view.backgroundColor = UIColor.clearColor()
        }
        
        //Add background to table view
        let tempImageView = UIImageView(image: UIImage(named: "LoginBackground"))
        tempImageView.frame = self.tableView.frame
        self.tableView.backgroundView = tempImageView
        
        //Show keyboard
        txtUsername.becomeFirstResponder()
        
        //Set placeholders username/password
        txtUsername.attributedPlaceholder = NSAttributedString(string: "Spotify username or Facebook e-mail", attributes: [NSForegroundColorAttributeName : UIColor.whiteColor()])
        txtPassword.attributedPlaceholder = NSAttributedString(string: "Password", attributes: [NSForegroundColorAttributeName : UIColor.whiteColor()])
        
        //Set delegates
        txtUsername.delegate = self
        txtPassword.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        SPSession.sharedSession().delegate = self
        btLogin.alpha = 0.5
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        SPSession.sharedSession().delegate = nil
        
        txtUsername.resignFirstResponder()
        txtPassword.resignFirstResponder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func shouldAutorotate() -> Bool {
        return false
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    func login() {
        txtUsername.resignFirstResponder()
        txtPassword.resignFirstResponder()
        
        //Show loading HUD
        let hud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        hud.labelText = "Logging In...";
        
        SPSession.sharedSession().attemptLoginWithUserName(txtUsername.text, password: txtPassword.text)
    }
    
    @IBAction func loginButtonClicked(sender : UIButton){
        self.login()
    }
    
    @IBAction func textValueChanged(send : UITextField)
    {
        if !txtUsername.text.isEmpty && !txtPassword.text.isEmpty {
            btLogin.alpha = 1
            btLogin.enabled = true
        }
        else {
            btLogin.alpha = 0.5
            btLogin.enabled = false
        }
    }

    // MARK: - SPSession delegate
    func session(aSession: SPSession!, didGenerateLoginCredentials credential: String!, forUserName userName: String!) {
        NSUserDefaults.standardUserDefaults().setObject(userName, forKey: "SpotifyUsername")
        NSUserDefaults.standardUserDefaults().setObject(credential, forKey: "SpotifyPassword")
        
        MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func session(aSession: SPSession!, didFailToLoginWithError error: NSError!) {
        MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
        
        let errorDescriptions = [Int(SP_ERROR_BAD_USERNAME_OR_PASSWORD.value): "Your username and/or password was not accepted for login.",
            Int(SP_ERROR_USER_NEEDS_PREMIUM.value): "Your Spotify account needs to be Premium.",
            Int(SP_ERROR_USER_BANNED.value): "The specified Spotify account is banned.",
            Int(SP_ERROR_OTHER_PERMANENT.value): "Could not login. Is your internet connection still active?"]
        
        
        let errorDescription = errorDescriptions[error.code] ?? error.localizedDescription
        let alert = UIAlertView(title: "Spotify Login Failed", message: errorDescription, delegate: self, cancelButtonTitle: "Oke")
        
        alert.show()
    }
    
    func session(aSession: SPSession!, didEncounterNetworkError error: NSError!) {
        MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
        
        let alert = UIAlertView(title: "Spotify Login Failed", message: "Could not check your credential due to a network error. Is your internet connection active?", delegate: self, cancelButtonTitle: "Oke")
        
        alert.show()
    }

    // MARK: - Textfield delegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == txtUsername {
            txtPassword.becomeFirstResponder()
        }
        else if textField == txtPassword {
            if !txtUsername.text.isEmpty && !txtPassword.text.isEmpty {
                self.login()
            }
            else {
                txtUsername.becomeFirstResponder()
            }
        }
        
        return true
    }
    
    
    // MARK: - Table view delegate
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.backgroundColor = UIColor.clearColor()
    }
}
