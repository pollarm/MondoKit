//
//  AccountDetailsViewController.swift
//  MondoKit
//
//  Created by Mike Pollard on 24/01/2016.
//  Copyright © 2016 Mike Pollard. All rights reserved.
//

import UIKit
import MondoKit

class AccountDetailsViewController: UIViewController {

    @IBOutlet private var balanceLabel : UILabel!
    @IBOutlet private var spentLabel : UILabel!
    
    var account : MondoAccount?
    private var balance : MondoAccountBalance? {
        didSet {
            if let balance = balance {
                balanceLabel?.text = String(balance.balance)
                spentLabel?.text = String(balance.spendToday)
            }
            else {
                balanceLabel?.text = ""
                spentLabel?.text = ""
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let account = account {
            
            title = account.description
            
            MondoAPI.instance.getBalanceForAccount(account) { [weak self] (balance, error) in
            
                self?.balance = balance
            }
        }
    }

}
