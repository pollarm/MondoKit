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
                
                let currencyFormatter = NSNumberFormatter()
                currencyFormatter.numberStyle = NSNumberFormatterStyle.CurrencyAccountingStyle
                let locale = NSLocale.currentLocale()
                let symbol = locale.displayNameForKey(NSLocaleCurrencySymbol, value: balance.currency)
                currencyFormatter.currencySymbol = symbol
                
                let currency = CurrencyFormatter(isoCode: balance.currency)
                
                balanceLabel?.text = currency.stringFromMinorUnitsValue(balance.balance)
                spentLabel?.text = currency.stringFromMinorUnitsValue(balance.spendToday)
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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        amountLabel.font = UIFont.monospacedDigitSystemFontOfSize(amountLabel.font.pointSize, weight: UIFontWeightRegular)
    }
}

class AccountTransactionsViewController : UIViewController {
    
    @IBOutlet private var tableView : UITableView!
    
    var account : MondoAccount!
    
    var selectionHandler : ((selected: MondoTransaction) -> Void)?
    var selectedTransaction : MondoTransaction? {
        if let dataSourceWithTransactions = tableView.dataSource as? DataSourceWithTransactions,
            indexPath = tableView.indexPathForSelectedRow,
            transaction = dataSourceWithTransactions.transactionAtIndexPath(indexPath) {
                
                return transaction
        }
        else {
            return nil
        }
    }
    
    private let transactionsDataSource = TransactionsDataSource()
    private let feedDataSource = FeedDataSource()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = transactionsDataSource
        tableView.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        transactionsDataSource.loadTransactionsForAccount(account) { [weak self] _ in
            self?.tableView.reloadData()
        }
    }
    
    @IBAction func segmentedValueChanged(segmentedControl: UISegmentedControl) {
    
        if segmentedControl.selectedSegmentIndex == 0 {
            tableView.dataSource = transactionsDataSource
            transactionsDataSource.loadTransactionsForAccount(account) { [weak self] _ in
                self?.tableView.reloadData()
            }
        }
        else {
            tableView.dataSource = feedDataSource
            feedDataSource.loadFeedForAccount(account) { [weak self] _ in
                self?.tableView.reloadData()
            }
        }
    }
}

protocol DataSourceWithTransactions {
 
    func transactionAtIndexPath(indexPath : NSIndexPath) -> MondoTransaction?
}

private class FeedDataSource : NSObject, UITableViewDataSource, DataSourceWithTransactions {

    private static let FeedCellIdentifier = "TransactionCell2"
    
    private var feedItems : [MondoFeedItem]?
    
    private func loadFeedForAccount(account: MondoAccount, completion: ()->Void) {
        
        MondoAPI.instance.listFeedForAccount(account) { [weak self] (items, error) in
            
            if let items = items {
                self?.feedItems = items
            }
            completion()
        }
    }
    
    private func transactionAtIndexPath(indexPath : NSIndexPath) -> MondoTransaction? {
        
        return feedItems?[indexPath.row].transaction
    }
    
    @objc func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    @objc func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return feedItems?.count ?? 0
    }
    
    @objc func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier(FeedDataSource.FeedCellIdentifier, forIndexPath: indexPath) as! TransactionCell
        
        if let feedItem = feedItems?[indexPath.row] {
            
            if let transaction = feedItem.transaction {
                
                if let m = transaction.merchant, case .Expanded(let merchant) = m {
                    cell.descriptionLabel.text = merchant.name
                }
                else {
                    cell.descriptionLabel.text = transaction.description
                }
                cell.categoryLabel.text = transaction.category.rawValue
                let currency = CurrencyFormatter(isoCode: transaction.currency)
                cell.amountLabel.text = currency.stringFromMinorUnitsValue(transaction.amount)
            }
            else {
                cell.descriptionLabel.text = ""
                cell.categoryLabel.text = feedItem.type.rawValue
                cell.amountLabel.text = ""
            }
        }
        return cell
    }
}

private class TransactionsDataSource : NSObject, UITableViewDataSource, DataSourceWithTransactions {

    private static let TransactionCellIdentifier = "TransactionCell2"
    
    private var transactions : [MondoTransaction]?
    
    private func loadTransactionsForAccount(account: MondoAccount, completion: ()->Void) {
        
        MondoAPI.instance.listTransactionsForAccount(account, expand: "merchant") { [weak self] (transactions, error) in
            
            if let transactions = transactions {
                self?.transactions = transactions
            }
            completion()
        }
    }
    
    private func transactionAtIndexPath(indexPath : NSIndexPath) -> MondoTransaction? {
        
        return transactions?[indexPath.row]
    }
    
    @objc func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    @objc func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transactions?.count ?? 0
    }
    
    @objc func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier(TransactionsDataSource.TransactionCellIdentifier, forIndexPath: indexPath) as! TransactionCell
        
        if let transaction = transactions?[indexPath.row] {
            
            
            if let m = transaction.merchant, case .Expanded(let merchant) = m {
                cell.descriptionLabel.text = merchant.name
            }
            else {
                cell.descriptionLabel.text = transaction.description
            }
            cell.categoryLabel.text = transaction.category.rawValue
            let currency = CurrencyFormatter(isoCode: transaction.currency)
            cell.amountLabel.text = currency.stringFromMinorUnitsValue(transaction.amount)
        }
        return cell
    }
}

extension AccountTransactionsViewController : UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if let dataSourceWithTransactions = tableView.dataSource as? DataSourceWithTransactions,
            transaction = dataSourceWithTransactions.transactionAtIndexPath(indexPath) {
                
                selectionHandler?(selected: transaction)
        }
    }
}
