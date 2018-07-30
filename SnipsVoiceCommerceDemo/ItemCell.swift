//
//  ItemCell.swift
//  SnipsVoiceCommerceDemo
//
//  Created by Fabrice Dewasmes on 16/07/2018.
//  Copyright © 2018 Fabrice Dewasmes. All rights reserved.
//

import Foundation
import UIKit

class ItemCell: UITableViewCell{
    
    @IBOutlet weak var pic: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var quantity: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        // do nothing for now
    }
}
