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
    var requesting = false
    var allLoaded = false
    var currentPage = 1
    let pageSize = 50
    let loadMoreOffset = 5

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        self.fetchConversations()
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
        if indexPath.row >= conversations.count - loadMoreOffset {
            self.fetchConversations()
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        let conversation = conversations[indexPath.row]
        cell.textLabel?.text = conversation.title
        cell.detailTextLabel?.text = conversation.recordID().canonicalString

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "conversation_room", sender: conversations[indexPath.row])
    }

    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: UITableViewRowActionStyle.normal, title: "Delete") { (action, indexPath) in
            let conversation = self.conversations[indexPath.row]
            SKYContainer.default().chatExtension?.deleteConversation(conversation) { (result, error) in
                if let err = error {
                    let alert = UIAlertController(title: "Unable to delete conversation", message: err.localizedDescription,preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    tableView.reloadData()
                    return
                }
                self.conversations.remove(at: indexPath.row)
                tableView.reloadData()
            }
        }
        
        deleteAction.backgroundColor = UIColor.red
        
        return [deleteAction]
    }

    // MARK: - Table view data source

    func fetchConversations() {
        if (requesting || allLoaded) {
            return;
        }
        requesting = true
        SKYContainer
            .default()
            .chatExtension?
            .fetchConversations(page: self.currentPage,
                                pageSize: self.pageSize,
                                fetchLastMessage: false,
                                completion: { (conversations, error) in
                                    self.requesting = false
                                    self.currentPage += 1
                                    if let err = error {
                                        let alert = UIAlertController(title: "Unable to fetch conversations", message: err.localizedDescription, preferredStyle: .alert)
                                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                                        self.present(alert, animated: true, completion: nil)
                                        return
                                    }

                                    if let cons = conversations {
                                        if cons.count < self.pageSize {
                                            self.allLoaded = true
                                        }
                                        self.conversations = self.conversations + cons
                                        // deduplicate
                                        var cIDs = Set<String>()
                                        self.conversations = self.conversations.filter({ (con) -> Bool in
                                            if cIDs.contains(con.recordName()) {
                                                return false
                                            }
                                            cIDs.insert(con.recordName())
                                            return true
                                        })
                                        self.tableView.reloadData()
                                    }
            })
    }
}
