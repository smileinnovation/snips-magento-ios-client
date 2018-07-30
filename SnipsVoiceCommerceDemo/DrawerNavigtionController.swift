//
//  DrawerNavigtionController.swift
//  SnipsVoiceCommerceDemo
//
//  Created by Fabrice Dewasmes on 26/07/2018.
//  Copyright © 2018 Fabrice Dewasmes. All rights reserved.
//

import Foundation
import UIKit
import DrawerKit

class DrawerNavigationController:UINavigationController{
    override func viewDidLoad() {
        super.viewDidLoad()
        
        delegate = self
    }
}

extension DrawerNavigationController: DrawerAnimationParticipant {
    var drawerAnimationActions: DrawerAnimationActions {
        return (topViewController as? DrawerAnimationParticipant)?.drawerAnimationActions
            ?? DrawerAnimationActions()
    }
}

extension DrawerNavigationController: DrawerPresentable {
    var heightOfPartiallyExpandedDrawer: CGFloat {
        return (topViewController as? DrawerPresentable)?.heightOfPartiallyExpandedDrawer ?? 0.0
    }
}

extension DrawerNavigationController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if let viewController = viewController as? LoggingViewController {
            drawerPresentationController?.scrollViewForPullToDismiss = viewController.presentedView
        }
    }
}
