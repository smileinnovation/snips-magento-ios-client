//
//  RecordButton.swift
//  SnipsVoiceCommerceDemo
//
//  Created by Fabrice Dewasmes on 27/07/2018.
//  Copyright © 2018 Fabrice Dewasmes. All rights reserved.
//

import Foundation
import UIKit

enum ButtonState : Int{
    case disabled=0xAAAAAA, recording=0xFF0000, stalled=0x007AFF
}

class RecordButton: UIButton {
    var currentState:ButtonState = .disabled
    
    func change(state:ButtonState){
        self.backgroundColor = UIColor(rgb:state.rawValue)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageEdgeInsets = UIEdgeInsets(top: -20.0, left: 0, bottom: 0, right: 0)
    }
}
