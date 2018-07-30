//
//  Message.swift
//  SnipsVoiceCommerceDemo
//
//  Created by Fabrice Dewasmes on 19/07/2018.
//  Copyright © 2018 Fabrice Dewasmes. All rights reserved.
//

import Foundation

class Message {
    let lang : String
    var messages : Dictionary<String,Any>
    
    convenience init(){
        self.init(lang:"fr",messages:[:])
    }
    
    init(lang:String, messages:Dictionary<String,Any>) {
        self.lang = lang
        self.messages = messages
    }
    
    func getMessage(name:String) -> String{
        if let message = self.messages[name]{
            switch message {
            case let someString as String:
                return someString
            case let movie as [String]:
                return movie[0]
            
            default:
                return("")
            }
        } else {
            return ""
        }
    }
}
