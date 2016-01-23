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
        
        let oauthViewController = MondoAPI.instance.newAuthViewController() { [unowned self] (success, error) in
            
            if success {
                
                MondoAPI.instance.listAccounts() { _ in }
                
                self.dismissViewControllerAnimated(true) {
                    self.performSegueWithIdentifier("loginSuccess", sender: self)
                }
            }
            else  {
                debugPrint(error!.getLocalizedFailureReason())
            }
        }

        presentViewController(oauthViewController, animated: true, completion: nil)
    }
}
