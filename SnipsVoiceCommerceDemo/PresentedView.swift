//
//  PresentedView.swift
//  SnipsVoiceCommerceDemo
//
//  Created by Fabrice Dewasmes on 26/07/2018.
//  Copyright © 2018 Fabrice Dewasmes. All rights reserved.
//

import Foundation
import UIKit

class PresentedView: UIScrollView {
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var dismissButton: UIButton!
    @IBOutlet weak var dividerView: UIView!
    
}

extension PresentedView {
    func prepareCollapsedToPartiallyExpanded() {
        textView.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
        dismissButton.alpha = 0
    }
    
    func animateAlongCollapsedToPartiallyExpanded() {
        textView.transform = .identity
        dismissButton.alpha = 1
    }
    
    func cleanupCollapsedToPartiallyExpanded() {
        animateAlongCollapsedToPartiallyExpanded()
    }
    
    func preparePartiallyExpandedToCollapsed() {
        animateAlongCollapsedToPartiallyExpanded()
    }
    
    func animateAlongPartiallyExpandedToCollapsed() {
        prepareCollapsedToPartiallyExpanded()
    }
    
    func cleanupPartiallyExpandedToCollapsed() {
        prepareCollapsedToPartiallyExpanded()
    }
}

extension PresentedView {
    func preparePartiallyExpandedToFullyExpanded() {
        textView.transform = .identity
    }
    
    func animateAlongPartiallyExpandedToFullyExpanded() {
        textView.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
    }
    
    func cleanupPartiallyExpandedToFullyExpanded() {
        animateAlongPartiallyExpandedToFullyExpanded()
    }
    
    func prepareFullyExpandedToPartiallyExpanded() {
        animateAlongPartiallyExpandedToFullyExpanded()
    }
    
    func animateAlongFullyExpandedToPartiallyExpanded() {
        preparePartiallyExpandedToFullyExpanded()
    }
    
    func cleanupFullyExpandedToPartiallyExpanded() {
        preparePartiallyExpandedToFullyExpanded()
    }
}

extension PresentedView {
    func prepareCollapsedToFullyExpanded() {
        textView.transform = .identity
    }
    
    func animateAlongCollapsedToFullyExpanded() {
        textView.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
    }
    
    func cleanupCollapsedToFullyExpanded() {
        animateAlongCollapsedToFullyExpanded()
    }
    
    func prepareFullyExpandedToCollapsed() {
        animateAlongCollapsedToFullyExpanded()
    }
    
    func animateAlongFullyExpandedToCollapsed() {
        prepareCollapsedToFullyExpanded()
    }
    
    func cleanupFullyExpandedToCollapsed() {
        prepareCollapsedToFullyExpanded()
    }
}
