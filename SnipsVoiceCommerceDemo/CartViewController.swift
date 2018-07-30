//
//  CartViewController.swift
//  SnipsVoiceCommerceDemo
//
//  Created by Fabrice Dewasmes on 26/07/2018.
//  Copyright © 2018 Fabrice Dewasmes. All rights reserved.
//

import Foundation
import UIKit

class CartViewController: UIViewController,UITableViewDelegate, UITableViewDataSource{
    @IBOutlet weak var tableView: UITableView!
    var magentoClient : MagentoClient? = nil
    private var items:[Item]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.refreshCart()
    }
    
    func refreshCart() {
        self.magentoClient?.getCartItems(completionHandler: {items in
            self.items = items
            self.tableView.reloadData()
        })
    }
    
    func emptyCart() {
        var indexpaths : [IndexPath]=[IndexPath]()
        if let items = self.items{
            for i in 0...items.count-1 {
                indexpaths.append(IndexPath(row: i, section: 0))
            }
            self.items?.removeAll()
            self.tableView.performBatchUpdates ({self.tableView.deleteRows(at: indexpaths, with: .automatic)},completion: nil)
        }
    }
    
    // MARK: - table management
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let count = self.items?.count{
            return count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath) as! ItemCell
        if let item = self.items?[indexPath.row]{
            cell.name.text = item.name
            cell.quantity.text = "\(item.quantity)"
        }
        
        return cell
    }
}
