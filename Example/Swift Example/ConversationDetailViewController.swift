//
//  ConversationDetailViewController.swift
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

class ConversationDetailViewController: UITableViewController, UITextFieldDelegate {

    @IBOutlet var participantTextField: UITextField!

    let unreadMessageCount = 0
    let participantIdsSection = 1
    let adminIdsSection = 2

    var userCon: SKYUserConversation!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        refreshConversation()
    }

    // MARK: - Action
    @IBAction func addParticipant(_ sender: AnyObject) {
        if let id = participantTextField.text, !id.isEmpty {
            SKYContainer.default().chatExtension?.addParticipants(
                withUserIDs: [id],
                to: userCon.conversation
            ) { (conversation, error) in
                if let err = error {
                    let alert = UIAlertController(title: "Unable to add user to participant.", message: err.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    return
                }

                self.refreshConversation()
            }
        }
    }

    @IBAction func removeParticipant(_ sender: AnyObject) {
        if let id = participantTextField.text, !id.isEmpty {
            SKYContainer.default().chatExtension?.removeParticipants(
                withUserIDs: [id],
                from: userCon.conversation
            ) { (conversation, error) in
                if let err = error {
                    let alert = UIAlertController(title: "Unable to remove user from participant.", message: err.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    return
                }

                self.refreshConversation()
            }
        }
    }

    func refreshConversation() {
        SKYContainer.default().chatExtension?.fetchUserConversation(
            withConversationID: self.userCon.conversation.recordID.recordName,
            fetchLastMessage:false,
            completion: { (conversation, error) in
                self.userCon = conversation
                self.tableView.reloadData()
            }
        )
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case unreadMessageCount:
            return 1
        case participantIdsSection:
            return userCon.conversation.participantIds.count
        case adminIdsSection:
            return userCon.conversation.adminIds.count
        default:
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case unreadMessageCount:
            return "Unread Count"
        case participantIdsSection:
            return "ParticipantIds"
        case adminIdsSection:
            return "AdminIds"
        default:
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case unreadMessageCount:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            cell.textLabel?.text = "\(userCon.unreadCount)"
            return cell
        case participantIdsSection:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            cell.textLabel?.text = userCon.conversation.participantIds[indexPath.row]
            return cell
        case adminIdsSection:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            cell.textLabel?.text = userCon.conversation.adminIds[indexPath.row]
            return cell
        default:
            return UITableViewCell()
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case participantIdsSection:
            self.performSegue(withIdentifier: "showDetail", sender: userCon.conversation.participantIds[indexPath.row])
        case adminIdsSection:
            self.performSegue(withIdentifier: "showDetail", sender: userCon.conversation.adminIds[indexPath.row])
        default: break
        }
    }

    // MARK: - Text Field delegate

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            let controller = segue.destination as! DetailViewController
            controller.detailText = sender as! String
        }
    }
}
