//
//  TransactionDetailController.swift
//  MondoKit
//
//  Created by Mike Pollard on 28/01/2016.
//  Copyright © 2016 Mike Pollard. All rights reserved.
//

import UIKit
import MondoKit

class TransactionDetailController: UITableViewController {

    @IBOutlet private var idLabel : UILabel!
    @IBOutlet private var amountLabel : UILabel!
    @IBOutlet private var createdLabel : UILabel!
    @IBOutlet private var descriptionLabel : UILabel!
    
    var transaction : MondoTransaction!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        idLabel.text = transaction.id
        amountLabel.text = String(transaction.amount)
        createdLabel.text = transaction.created.description
        descriptionLabel.text = transaction.description
    }
}
