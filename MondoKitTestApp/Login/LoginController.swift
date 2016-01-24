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
        
        let oauthViewController = MondoAPI.instance.newAuthViewController() { (success, error) in
            
            if success {
                
                self.dismissViewControllerAnimated(true) {
                    self.performSegueWithIdentifier("loginSuccess", sender: self)
                }
            }
            else if let errorWithReason = error as? ErrorWithLocalizedFailureReason {
                debugPrint(errorWithReason.getLocalizedFailureReason())
            }
            else  {
                debugPrint(error)
            }
        }

        presentViewController(oauthViewController, animated: true, completion: nil)
    }
}

extension NSError : ErrorWithLocalizedFailureReason {
    
    public func getLocalizedFailureReason() -> String? {
        
        return localizedFailureReason
    }
}