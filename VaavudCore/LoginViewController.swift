//
//  LoginViewController.swift
//  Vaavud
//
//  Created by Diego R on 11/20/15.
//  Copyright © 2015 Andreas Okholm. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController, LoginCoreDelegate {

    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var loginButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupField(emailField)
        setupField(passwordField)
        validateInformation()
    }
    
    func setupField(field: UITextField) {
        let attributes = [NSForegroundColorAttributeName : UIColor.vaavudRedColor().colorWithAlphaComponent(0.3)]
        field.attributedPlaceholder = NSAttributedString(string: field.placeholder ?? "", attributes: attributes)
    }

    @IBAction func textChanged(sender: UITextField) {
        validateInformation()
    }
    
    
    private func validateInformation(){
        loginButton.enabled = !emailField.text!.isEmpty && !passwordField.text!.isEmpty
    }
    
    @IBAction func loginPushed() {
        AuthorizationController.shared.login(emailField.text!, password: passwordField.text!,delegate: self)
    }
    
    func onSuccess() {
        let storyboard = UIStoryboard(name: "MainStoryboard", bundle: nil)
        let vc = storyboard.instantiateViewControllerWithIdentifier("TabBarController")
        self.presentViewController(vc, animated: true, completion: nil)
    }
    
    func onError(title: String, message: String) {
        self.showAlert(title,message: message,callback: nil)
    }
    
    func missingActivity() {
        if let vc = self.storyboard?.instantiateViewControllerWithIdentifier("activityVC") as? ActivityViewController{
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    
    private func showAlert(title: String, message: String , callback: ((UIAlertAction) -> Void)? ){
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("BUTTON_OK", comment: ""), style: .Default, handler: callback))
        
        dispatch_async(dispatch_get_main_queue(),{
            self.presentViewController(alertController, animated: true, completion: nil)
        })
    }
    
}
