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

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if let transactionController = segue.destinationViewController as? AccountTransactionsViewController {
            transactionController.account = account
        }
    }
}

class AccountTransactionsViewController : UIViewController {
    
    private static let TransactionCellIdentifier = "TransactionCell"
    
    @IBOutlet private var tableView : UITableView!
    
    var account : MondoAccount!
    private var transactions : [MondoTransaction]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        MondoAPI.instance.listTransactionsForAccount(account) { [weak self] (transactions, error) in
            
            if let transactions = transactions {
                self?.transactions = transactions
                self?.tableView.reloadData()
            }
        }
    }
}

extension AccountTransactionsViewController : UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transactions?.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier(AccountTransactionsViewController.TransactionCellIdentifier, forIndexPath: indexPath)
        
        if let transaction = transactions?[indexPath.row] {
        
            cell.textLabel?.text = transaction.description
            cell.detailTextLabel?.text = String(transaction.amount)
        }
        return cell
    }
}
