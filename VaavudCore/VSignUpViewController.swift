//
//  VSignUpViewController.swift
//  Vaavud
//
//  Created by Diego R on 11/17/15.
//  Copyright © 2015 Andreas Okholm. All rights reserved.
//

import UIKit

class VSignUpViewController: UIViewController,UITextFieldDelegate {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var andLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var basicInputView: UIView!
    @IBOutlet weak var facebookButton: UIButton!
    @IBOutlet weak var orLabel: UILabel!
    @IBOutlet weak var disclaimerLabel: UILabel!
    
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var termsPrivacyView: UIView!
    @IBOutlet weak var termsButton: UIButton!
    @IBOutlet weak var privacyButton: UIButton!
    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var orLabelTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var disclaimerLabelTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var termsPrivacyViewWidthConstraint: NSLayoutConstraint!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        self.firstNameTextField.delegate = self
        self.lastNameTextField.delegate = self
        self.emailTextField.delegate = self
        self.passwordTextField.delegate = self
        
        
        self.basicInputView.layer.masksToBounds = true;
        
        self.facebookButton.layer.masksToBounds = true;
        
        
        
        refreshSignupButton()
    
    }
    
    @IBAction func textFieldDidChange(sender: UITextField) {
        refreshSignupButton()
    }
    
    func refreshSignupButton(){
        self.navigationItem.rightBarButtonItem?.enabled = !self.firstNameTextField.text!.isEmpty && !self.emailTextField.text!.isEmpty && !self.passwordTextField.text!.isEmpty
    }
    
    
    @IBAction func done(sender: UIBarButtonItem) {
        
        //User.sharedInstance.name = firstNameTextField.text!
        //User.sharedInstance.lastName = lastNameTextField.text!
        //User.sharedInstance.password = passwordTextField.text!
        //User.sharedInstance.email = emailTextField.text!
        
        
        let activityIndicator = UIActivityIndicatorView(frame: CGRectMake(0, 0, 20, 20))
        activityIndicator.activityIndicatorViewStyle = .Gray;
        
        
        let oldBarButtonItem = navigationItem.rightBarButtonItem;
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator);
        activityIndicator.startAnimating()
        
        
        let callback = ({(success : Bool, uid : String) in
            if success{
                
                let callbackLogin = ({(success : Bool, uid : String) in
                    if success {
                        
                        //User.sharedInstance.uid = uid
                        //User.sharedInstance.password = ""
                        
                        
                        let userModel : [String:AnyObject] = [
                            "created"  : 1447405235188,
                            "email" : "ASDAS",//User.sharedInstance.email!,
                            "country" : "US",
                            "firstName" : "",// User.sharedInstance.name!,
                            "language" : "EN",
                            "lastName" : "asdasd" //User.sharedInstance.lastName!
                        ]
                        
                        FirebaseService.sharedInstance.pushItemByKey("user", key: uid, items: userModel)
                        
                        let deviceModel : [String:AnyObject] = [
                            "appVersion" : "0.0.0.02",
                            "model" : "IPhone 3gs",
                            "vendor" : "Iphone",
                            "osVersion" : "0.0.02",
                            "uid" : "asdasd"//User.sharedInstance.uid!
                        ]
                        
                        let deviceId = FirebaseService.sharedInstance.pushItem("device", items: deviceModel)
                        //User.sharedInstance.deviceId = deviceId
                        
                        print(uid)
                        print(deviceId)
                    }
                    else{
                        //TODO
                    }
                });
                
                //FirebaseService.sharedInstance.login(User.sharedInstance.email!, password: User.sharedInstance.password!, callback: callbackLogin)
                
            }
            else{
            self.showMessage(NSLocalizedString("REGISTER_FEEDBACK_ACCOUNT_EXISTS_MESSAGE", comment: ""), title: NSLocalizedString("REGISTER_FEEDBACK_ACCOUNT_EXISTS_TITLE",comment : ""))
                self.navigationItem.rightBarButtonItem = oldBarButtonItem
            }
        });
        
        
        //FirebaseService.sharedInstance.createUser(User.sharedInstance.email!, password: User.sharedInstance.password!, callback: callback)
        
    }
    
    
    func showMessage(text : String, title : String){
        let alertController = UIAlertController(title: title, message: text, preferredStyle: UIAlertControllerStyle.Alert)
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("BUTTON_OK", comment: ""), style: UIAlertActionStyle.Default, handler: nil))
        
        self.presentViewController(alertController, animated: true, completion: nil)
        
    }
    
    
    func facebookButtonPushed(){
        self.activityIndicator.startAnimating()
        self.facebookButton.titleLabel!.hidden = true
    }
    
    
    
    
    
    
    
    
}
