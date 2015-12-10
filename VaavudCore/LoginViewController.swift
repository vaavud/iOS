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
    
    // MARK: Lifetime

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupField(emailField)
        setupField(passwordField)
        refreshLoginButton()
    }
    
    // MARK: User Actions
    
    @IBAction func tappedLogin() {
        if let email = emailField.text, password = passwordField.text {
            AuthorizationController.shared.login(email, password: password, delegate: self)
        }
        else {
            showError(.Unknown)
        }
    }
    
    // MARK: Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ForgotPassword", let vc = segue.destinationViewController as? PasswordViewController {
            vc.email = emailField.text
        }
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
        showError(error)
    }
    
    // MARK: Textfield Delegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == emailField {
            passwordField.becomeFirstResponder()
        }
        else {
            guard validInput() else {
                return false
            }
            
            tappedLogin()
        }
        
        return true
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        refreshLoginButton()
        return true
    }
    
    // MARK: Convenience
    
    private func showError(error: LoginError) {
        dispatch_async(dispatch_get_main_queue()) {
            VaavudInteractions().showLocalAlert("LOGIN_ERROR_TITLE", messageKey: error.rawValue, otherKey: "BUTTON_OK", action: {}, on: self)
        }
    }

    private func refreshLoginButton() {
        loginButton.enabled = validInput()
    }
    
    private func validInput() -> Bool {
        return (emailField.text?.containsString("@") ?? false) && !passwordField.text!.isEmpty
    }
    
    private func setupField(field: UITextField) {
        let attributes = [NSForegroundColorAttributeName : UIColor.vaavudRedColor().colorWithAlphaComponent(0.3)]
        field.attributedPlaceholder = NSAttributedString(string: field.placeholder ?? "", attributes: attributes)
    }
}

class PasswordViewController: UIViewController, UITextFieldDelegate {
    var email: String?
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    
    // MARK: Lifetime

    override func viewDidLoad() {
        emailField.text = email
        refreshSendButton()
    }

    // MARK: User Actions

    @IBAction func tappedSend() {
        // fixme: add action
        navigationController?.popViewControllerAnimated(true)
    }
    
    // MARK: Textfield Delegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        guard validInput() else {
            return false
        }
        
        tappedSend()
        
        return true
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        refreshSendButton()
        return true
    }

    // MARK: Convenience

    private func refreshSendButton() {
        sendButton.enabled = validInput()
    }
    
    private func validInput() -> Bool {
        return emailField.text?.containsString("@") ?? false
    }
}






