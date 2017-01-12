//
//  UserQueryViewController.swift
//  SKYKitChat
//
//  Created by Ben Lei on 12/1/2017.
//  Copyright © 2017 Kwok-kuen Cheung. All rights reserved.
//

import Foundation
import SKYKitChat

class UserQueryViewController: SKYChatParticipantListViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.skygear = SKYContainer.default()
        self.queryMethod = .ByUsername
    }
}
