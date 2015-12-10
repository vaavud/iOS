//
//  LoginViewController.swift
//  Vaavud
//
//  Created by Diego R on 11/20/15.
//  Copyright © 2015 Andreas Okholm. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController, LoginDelegate {
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var loginButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupField(emailField)
        setupField(passwordField)
        refreshLoginButton()
    }
    
    func setupField(field: UITextField) {
        let attributes = [NSForegroundColorAttributeName : UIColor.vaavudRedColor().colorWithAlphaComponent(0.3)]
        field.attributedPlaceholder = NSAttributedString(string: field.placeholder ?? "", attributes: attributes)
    }

    @IBAction func textChanged(sender: UITextField) {
        refreshLoginButton()
    }
    
    private func refreshLoginButton() {
        loginButton.enabled = !emailField.text!.isEmpty && !passwordField.text!.isEmpty
    }
    
    @IBAction func loginPushed() {
        AuthorizationController.shared.login(emailField.text!, password: passwordField.text!, delegate: self)
    }
    
    // MARK: Login Delegate
    
    func onSuccess(showActivitySelector: Bool) {
        if showActivitySelector {
            if let vc = self.storyboard?.instantiateViewControllerWithIdentifier("activityVC") {
                navigationController?.pushViewController(vc, animated: true)
            }
        }
        else {
            let storyboard = UIStoryboard(name: "MainStoryboard", bundle: nil)
            let vc = storyboard.instantiateViewControllerWithIdentifier("TabBarController")
            presentViewController(vc, animated: true, completion: nil)
        }
    }

    func onError(error: LoginError) {
//        showAlert(title,message: message, callback: nil)
    }
    
    // MARK: Convenience
    
    private func showAlert(title: String, message: String , callback: (UIAlertAction -> Void)? ){
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("BUTTON_OK", comment: ""), style: .Default, handler: callback))
        
        dispatch_async(dispatch_get_main_queue(),{
            self.presentViewController(alertController, animated: true, completion: nil)
        })
    }
}
