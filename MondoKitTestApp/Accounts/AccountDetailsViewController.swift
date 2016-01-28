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
    private var transactionsController : AccountTransactionsViewController!
    
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
        
        if let transactionsController = segue.destinationViewController as? AccountTransactionsViewController {
            transactionsController.account = account
            self.transactionsController = transactionsController
            transactionsController.selectionHandler = { _ in
                self.performSegueWithIdentifier("showDetails", sender: nil)
            }
        }
        
        if let detailsController = segue.destinationViewController as? TransactionDetailController,
            transaction = transactionsController.selectedTransaction {
                detailsController.transaction = transaction
        }
    }
    
}

class TransactionCell : UITableViewCell {
    
    @IBOutlet private var descriptionLabel : UILabel!
    @IBOutlet private var categoryLabel : UILabel!
    @IBOutlet private var amountLabel : UILabel!
}

class AccountTransactionsViewController : UIViewController {
    
    private static let TransactionCellIdentifier = "TransactionCell2"
    
    @IBOutlet private var tableView : UITableView!
    
    var account : MondoAccount!
    
    var selectionHandler : ((selected: MondoTransaction) -> Void)?
    var selectedTransaction : MondoTransaction? {
        if let indexPath = tableView.indexPathForSelectedRow,
            transaction = transactions?[indexPath.row] {
                return transaction
        }
        else {
            return nil
        }
    }
    
    private var transactions : [MondoTransaction]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        MondoAPI.instance.listTransactionsForAccount(account, expand: "merchant") { [weak self] (transactions, error) in
            
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
        
        let cell = tableView.dequeueReusableCellWithIdentifier(AccountTransactionsViewController.TransactionCellIdentifier, forIndexPath: indexPath) as! TransactionCell
        
        if let transaction = transactions?[indexPath.row] {
        
            
            if let m = transaction.merchant, case .Expanded(let merchant) = m {
                cell.descriptionLabel.text = merchant.name
            }
            else {
                cell.descriptionLabel.text = transaction.description
            }
            cell.categoryLabel.text = transaction.category.rawValue
            cell.amountLabel.text = String(transaction.amount)
        }
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if let transaction = transactions?[indexPath.row] {
            selectionHandler?(selected: transaction)
            MondoAPI.instance.annotateTransaction(transaction, withKey: "test", value: "hello") { (transaction, error) in
            
                debugPrint(transaction)
            }
        }
    }
}
