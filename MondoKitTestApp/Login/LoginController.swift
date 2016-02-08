//
//  LoginController.swift
//  MondoKit
//
//  Created by Mike Pollard on 21/01/2016.
//  Copyright © 2016 Mike Pollard. All rights reserved.
//

import UIKit
import MondoKit
import Alamofire

class LoginController: UIViewController {

    @IBOutlet private var usernameField : UITextField!
    @IBOutlet private var passwordField : UITextField!
    @IBOutlet private var continueSessionView : UIView!
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        passwordField.text = nil
        continueSessionView.hidden =  !MondoAPI.instance.isAuthorized
    }
}

extension LoginController {
    
    @IBAction func loginWithPassword(sender : UIButton) {
    
        if let username = usernameField.text,
            password = passwordField.text
            where username.characters.count > 0 && password.characters.count > 0 {
            
                MondoAPI.instance.authorizeFromUsername(username, andPassword: password) { (success, error) in
                    
                    if success {
                        
                        self.performSegueWithIdentifier("loginSuccess", sender: self)
                    }
                    else {
                        
                        var errorDescription = "An error occurred."
                        if let errorWithReason = error as? ErrorWithLocalizedDescription,
                            localizedErrorDescription = errorWithReason.getLocalizedDescription() {
                                errorDescription = localizedErrorDescription
                        }
                        let alert = UIAlertController(title: nil, message: errorDescription, preferredStyle: .Alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .Default) { _ in })
                        self.presentViewController(alert, animated: true, completion: nil)
                    }
                }
        }
    }
    
    @IBAction func loginPressed(sender : UIButton) {
        
        if MondoAPI.instance.isAuthorized {
            self.performSegueWithIdentifier("loginSuccess", sender: self)
        }
        else {
            let oauthViewController = MondoAPI.instance.newAuthViewController() { (success, error) in
                
                if success {
                    
                    self.dismissViewControllerAnimated(true) {
                        self.performSegueWithIdentifier("loginSuccess", sender: self)
                    }
                }
                else {
                    
                    var errorDescription = "An error occurred."
                    if let errorWithReason = error as? ErrorWithLocalizedDescription,
                        localizedErrorDescription = errorWithReason.getLocalizedDescription() {
                            errorDescription = localizedErrorDescription
                    }
                    self.dismissViewControllerAnimated(true) {
                        
                        let alert = UIAlertController(title: nil, message: errorDescription, preferredStyle: .Alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .Default) { _ in })
                        self.presentViewController(alert, animated: true, completion: nil)
                    }
                }
                
            }
            
            presentViewController(oauthViewController, animated: true, completion: nil)
        }
    }
    
    @IBAction func continueSession(sender : UIButton) {
        if MondoAPI.instance.isAuthorized {
            self.performSegueWithIdentifier("loginSuccess", sender: self)
        }
        else {
            continueSessionView.hidden = true
        }
    }
    
    @IBAction func signOut(unwindSegue: UIStoryboardSegue) {
        MondoAPI.instance.signOut()
    }
}

extension NSError : ErrorWithLocalizedDescription {
    
    public func getLocalizedDescription() -> String? {
        
        return self.localizedDescription
    }
}