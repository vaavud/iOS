//
//  SignupViewController.swift
//  Vaavud
//
//  Created by Diego R on 11/20/15.
//  Copyright © 2015 Andreas Okholm. All rights reserved.
//

import UIKit

class SignupViewController: UIViewController, UITextFieldDelegate, LoginDelegate {
    @IBOutlet weak var firstNameField: UITextField!
    @IBOutlet weak var lastNameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var createButton: UIBarButtonItem!
    var oldButtonBar: UIBarButtonItem!
    
    // MARK: Lifetime
    
    override func viewDidLoad() {
        super.viewDidLoad()
        refreshSignupButton()
        
        setupField(firstNameField)
        setupField(lastNameField)
        setupField(emailField)
        setupField(passwordField)
        
        
    }
    
    // MARK: User Actions

    @IBAction func tappedCreate() {
        if let firstName = firstNameField.text, lastName = lastNameField.text, email = emailField.text, password = passwordField.text {
            
            let activityIndicator = UIActivityIndicatorView(frame: CGRectMake(0, 0, 20, 20))
            activityIndicator.activityIndicatorViewStyle = .Gray
            
            oldButtonBar = navigationItem.rightBarButtonItem
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)
            activityIndicator.startAnimating()
            
            self.view.endEditing(true)
            
            AuthorizationController.shared.signup(firstName, lastName: lastName, email: email, password: password, delegate: self)
        }
        else {
            showError(.Unknown)
        }
    }
    
    // MARK: Login Delegate
    func onSuccess(showActivitySelector: Bool) {
        if showActivitySelector {
            if let vc = storyboard?.instantiateViewControllerWithIdentifier("activityVC") {
                navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
    
    func onError(error: LoginError) {
        navigationItem.rightBarButtonItem = oldButtonBar
        showError(error)
    }

    // MARK: Textfield Delegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == firstNameField {
            lastNameField.becomeFirstResponder()
        }
        else if textField == lastNameField{
            emailField.becomeFirstResponder()
        }
        else if textField == emailField {
            passwordField.becomeFirstResponder()
        }
        else {
            guard validInput() else {
                return false
            }

            tappedCreate()
        }
        
        return true
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        refreshSignupButton()
        return true
    }

    // MARK: Convenience
    
    private func showError(error: LoginError) { // fixme: no action??
        dispatch_async(dispatch_get_main_queue()) {
            VaavudInteractions().showLocalAlert("LOGIN_ERROR_TITLE", messageKey: error.rawValue, otherKey: "BUTTON_OK", action: {
                }, on: self)
        }
    }
    
    private func setupField(field: UITextField) {
        let attributes = [NSForegroundColorAttributeName : UIColor.vaavudRedColor().colorWithAlphaComponent(0.3)]
        field.attributedPlaceholder = NSAttributedString(string: field.placeholder ?? "", attributes: attributes)
    }
    
    private func refreshSignupButton() {
        createButton.enabled = validInput()
    }
    
    private func validInput() -> Bool {
        return !firstNameField.text!.isEmpty && !lastNameField.text!.isEmpty && (emailField.text?.containsString("@") ?? false) && !passwordField.text!.isEmpty
    }

}
