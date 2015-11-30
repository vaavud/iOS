//
//  SignupViewController.swift
//  Vaavud
//
//  Created by Diego R on 11/20/15.
//  Copyright © 2015 Andreas Okholm. All rights reserved.
//

import UIKit

class SignupViewController: UIViewController, UITextFieldDelegate,LoginCoreDelegate{

    @IBOutlet weak var firstNameField: UITextField!
    @IBOutlet weak var lastNameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var createButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        validateTextFields()
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == firstNameField {
            firstNameField.becomeFirstResponder()
        }
        else if textField == lastNameField{
            lastNameField.becomeFirstResponder()
        }
        else if textField == emailField {
            emailField.becomeFirstResponder()
        }
        else{
            passwordField.becomeFirstResponder()
        }
        
        return true
    }
    
    @IBAction func fieldChanged(sender: UITextField) {
        validateTextFields()
    }
    
    @IBAction func createPushed() {
        
        let firstName = firstNameField.text!
        let lastName = lastNameField.text!
        let email = emailField.text!
        let password = passwordField.text!
        
        AuthorizationController.shared.signup(firstName,lastName: lastName,email: email,password: password,delegate: self)
    }
    
    
    private func validateTextFields(){
    
        createButton.enabled = !firstNameField.text!.isEmpty && !lastNameField.text!.isEmpty && !emailField.text!.isEmpty && !passwordField.text!.isEmpty
    }
    
    func onSuccess() {
        //TODO
    }
    
    func onError(title: String, message: String) {
        showAlert(title,message: message,callback: nil)
    }
    
    func missingActivity() {
        let vc = self.storyboard?.instantiateViewControllerWithIdentifier("activityVC") as! ActivityViewController
        navigationController?.pushViewController(vc, animated: true)
    }
    
    
    private func showAlert(title: String, message: String , callback: ((UIAlertAction) -> Void)? ){
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("BUTTON_OK", comment: ""), style: .Default, handler: callback))
        
        dispatch_async(dispatch_get_main_queue(),{
            self.presentViewController(alertController, animated: true, completion: nil)
        })
    }
    
    
}
