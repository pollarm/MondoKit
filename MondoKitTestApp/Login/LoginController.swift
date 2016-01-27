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

}

extension LoginController {
    
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
}

extension NSError : ErrorWithLocalizedDescription {
    
    public func getLocalizedDescription() -> String? {
        
        return self.localizedDescription
    }
}