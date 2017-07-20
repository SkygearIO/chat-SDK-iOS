//
//  CreateGroupConversationViewController.swift
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

class CreateGroupConversationViewController: UIViewController,
    UITableViewDelegate,
    UITableViewDataSource,
    UITextFieldDelegate {

    @IBOutlet var titleTextField: UITextField!
    @IBOutlet var userIdTableView: UITableView!
    @IBOutlet var createdConversationTextView: UITextView!

    var userIds = [String]()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Actions

    @IBAction func addUserId(_ sender: AnyObject) {
        let alert = UIAlertController(title: "Add User", message: "Please enter a user ID.", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "UserID"
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "Add", style: .default, handler: { (action) in
            if var id = alert.textFields?.first?.text, !id.isEmpty {
                if id.hasPrefix("user/") {
                    id = id.substring(from: "user/".endIndex)
                }

                self.userIds.append(id)
                let indexPath = IndexPath(row: self.userIds.count-1, section: 0)
                self.userIdTableView.insertRows(at: [indexPath], with: .automatic)
            }
        }))
        alert.preferredAction = alert.actions.last
        self.present(alert, animated: true, completion: nil)
    }

    @IBAction func createConversation(_ sneder: AnyObject!) {

        var userIds = self.userIds

        if !userIds.contains(SKYContainer.default().auth.currentUserRecordID) {
            userIds.append(SKYContainer.default().auth.currentUserRecordID)
        }

        // let ids be unique
        userIds = Array(Set(userIds))

        SKYContainer.default().chatExtension?.createConversation(participantIDs: userIds, title: titleTextField.text, metadata: nil) { (conversation, error) in
            if let err = error {
                let alert = UIAlertController(title: "Unable to create group conversation", message: err.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }

            self.createdConversationTextView.text = conversation?.recordID().canonicalString
        }
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userIds.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = userIds[indexPath.row]
        return cell
    }

    // MARK: - Text view data source

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
