//
//  ConversationListDemoViewController.swift
//  Swift-Example
//
//  Copyright 2016 Oursky Ltd.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import SKYKitChat

class ConversationListDemoViewController: SKYChatConversationListViewController {
    let showConversationSegueIdentifier: String = "ShowConversationSegue"

    var selectedConversation: SKYConversation?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.delegate = self
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let segueID = segue.identifier else {
            return
        }

        switch segueID {
        case showConversationSegueIdentifier:
            if let dest = segue.destination as? ConversationDemoViewController {
                dest.conversation = self.selectedConversation
            }
        default:
            break
        }
    }
}

extension ConversationListDemoViewController: SKYChatConversationListViewControllerDelegate {
    func listViewController(_ controller: SKYChatConversationListViewController,
                            didSelectConversation conversation: SKYConversation)
    {
        print("Conversation \(conversation.recordID.recordName!) is selected")

        self.selectedConversation = conversation
        self.performSegue(withIdentifier: showConversationSegueIdentifier, sender: self)
    }
}
