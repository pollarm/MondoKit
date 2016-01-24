//
//  AccountsListViewController.swift
//  MondoKit
//
//  Created by Mike Pollard on 24/01/2016.
//  Copyright © 2016 Mike Pollard. All rights reserved.
//

import UIKit
import MondoKit

class AccountsListViewController: UIViewController {

    private static let AccountCellIdentifier = "AccountCell"
    
    @IBOutlet private var tableView : UITableView!
    
    private var accounts : [MondoAccount] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        MondoAPI.instance.listAccounts() { [weak self] (accounts, error) in
        
            if let accounts = accounts {
                self?.accounts = accounts
                self?.tableView.reloadData()
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if let detailsController = segue.destinationViewController as? AccountDetailsViewController,
            indexPath = tableView.indexPathForSelectedRow {
            
                detailsController.account = accounts[indexPath.row]
        }
    }

}

extension AccountsListViewController : UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return accounts.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier(AccountsListViewController.AccountCellIdentifier, forIndexPath: indexPath)
        
        let account = accounts[indexPath.row]
        
        cell.textLabel?.text = account.description
        cell.detailTextLabel?.text = account.accountNumber
        
        return cell
    }
}
