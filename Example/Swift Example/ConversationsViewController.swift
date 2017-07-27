//
//  ConversationsViewController.swift
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

import UIKit
import SKYKit
import SKYKitChat

class ConversationsViewController: UITableViewController {

    var conversations = [SKYConversation]()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        SKYContainer.default().chatExtension?.fetchConversations(fetchLastMessage:false) { (conversations, error) in
            if let err = error {
                let alert = UIAlertController(title: "Unable to fetch conversations", message: err.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }

            if let cons = conversations {
                self.conversations = cons.reversed()
                self.tableView.reloadData()
            }
        }
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "conversation_room" {
            let controller = segue.destination as! ConversationRoomViewController
            controller.conversation = sender as! SKYConversation
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        let conversation = conversations[indexPath.row]
        cell.textLabel?.text = conversation.title
        cell.detailTextLabel?.text = conversation.recordID().canonicalString

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "conversation_room", sender: conversations[indexPath.row])
    }

}
