//
//  Item.swift
//  SnipsVoiceCommerceDemo
//
//  Created by Fabrice Dewasmes on 14/07/2018.
//  Copyright © 2018 Fabrice Dewasmes. All rights reserved.
//

import Foundation
import SwiftyJSON

class Item {
    let name: String
    let quantity: Int
    let sku: String
    let price: Float
    let id: Int
    
    convenience init(name:String, quantity:Int, sku:String) {
        self.init(name: name, quantity: quantity, sku: sku, price:0.0, id:0)
    }
    init(name:String, quantity:Int, sku: String, price: Float, id: Int) {
        self.name = name
        self.quantity = quantity
        self.sku = sku
        self.price = price
        self.id = id
    }
    class func build(json:JSON) -> Item{
        if
            let name = json["name"].string,
            let quantity = json["qty"].int,
            let sku = json["sku"].string,
            let price = json["price"].float,
            let id = json["item_id"].int{
            return Item(
                name: name,
                quantity: quantity,
                sku: sku,
                price: price,
                id: id
                )
        } else {
            print("bad json \(json)")
            return Item(name: "", quantity: 0, sku: "", price: 0.0, id: 0)
        }
    }
}
