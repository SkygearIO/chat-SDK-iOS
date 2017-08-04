//
//  UserAuthenticationViewController.swift
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

class UserAuthenticationViewController: UITableViewController {

    let actionSectionIndex = 0
    let statusSectionIndex = 1

    var lastUsername: String? {
        get {
            return UserDefaults.standard.string(forKey: "LastUsername")
        }
        set(value) {
            UserDefaults.standard.set(value, forKey: "LastUsername")
            UserDefaults.standard.synchronize()
            self.loginStatusDidChange()
        }
    }

    internal var isLoggedIn: Bool {
        get {
            return SKYContainer.default().auth.currentUserRecordID != nil
        }
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(
            forName: NSNotification.Name.SKYContainerDidChangeCurrentUser,
            object: nil,
            queue: OperationQueue.main
        ) { _ in self.loginStatusDidChange() }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Actions

    func showAuthenticationError(_ user: SKYRecord?, error: Error, completion: (() -> Void)?) {
        let alert = UIAlertController(title: "Unable to Authenticate", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            if let c = completion {
                c()
            }
        }))
        self.present(alert, animated: true, completion: completion)
    }

    func loginStatusDidChange() {
        self.tableView.reloadData()
    }

    func login(_ username: String?) {
        let alert = UIAlertController(title: "Login", message: "Please enter your username and password.", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "Username"
            textField.text = username
        }
        alert.addTextField { (textField) in
            textField.placeholder = "Password"
            textField.isSecureTextEntry = true
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "Login", style: .default, handler: { (action) in
            let username = alert.textFields?.first?.text
            let password = alert.textFields?.last?.text

            if (username ?? "").isEmpty || (password ?? "").isEmpty {
                return
            }

            SKYContainer.default().auth.login(withUsername: username, password: password) { (user, error) in
                if let err = error {
                    self.showAuthenticationError(user, error: err, completion: {
                        self.login(username)
                    })
                    return
                }

                self.lastUsername = username
            }
        }))
        alert.preferredAction = alert.actions.last
        self.present(alert, animated: true, completion: nil)
    }

    func signup(_ username: String?) {
        let alert = UIAlertController(title: "Signup", message: "Please enter your username and password.", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "Username"
        }
        alert.addTextField { (textField) in
            textField.placeholder = "Password"
            textField.isSecureTextEntry = true
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "Signup", style: .default, handler: { (action) in
            let username = alert.textFields?.first?.text
            let password = alert.textFields?.last?.text

            if (username ?? "").isEmpty || (password ?? "").isEmpty {
                return
            }

            SKYContainer.default().auth.signup(withUsername: username, password: password) { (user, error) in
                if let err = error {
                    self.showAuthenticationError(user, error: err, completion: {
                        self.signup(username)
                    })
                    return
                }

                self.updateUserRecord(by: user!)
                self.lastUsername = username
            }
        }))
        alert.preferredAction = alert.actions.last
        self.present(alert, animated: true, completion: nil)
    }

    func logout() {
        if !self.isLoggedIn {
            return
        }

        SKYContainer.default().auth.logout { (user, error) in
            if let err = error {
                self.showAuthenticationError(user, error: err, completion: nil)
                return
            }

            let alert = UIAlertController(title: "Logged out", message: "You have successfully logged out.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }

    func updateUserRecord(by user: SKYRecord) {
        let skygear = SKYContainer.default()
        let userQuery = SKYQuery(recordType: "user",
                                 predicate: NSPredicate(format: "_id = %@",
                                                        argumentArray:[user.recordID.recordName!]))
        skygear.publicCloudDatabase.perform(
            userQuery, completionHandler: { (results, queryError) in
                guard queryError == nil else {
                    print("Failed to get the user record: \(queryError?.localizedDescription)")
                    return
                }

                if let userRecords = results as? [SKYRecord] {
                    guard userRecords.count > 0 else {
                        print("Cannot get any user records")
                        return
                    }

                    let theUser = userRecords[0]
                    theUser.setValue(user["username"], forKey: "name")

                    skygear.publicCloudDatabase.save(theUser, completion: { (savedRecord, saveError) in
                        guard saveError == nil else {
                            print("Failed to save the user record: \(saveError?.localizedDescription)")
                            return
                        }

                        print("Name of the user record updated.")
                    })
                }
        })

    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        if self.isLoggedIn {
            return 2
        } else {
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case self.actionSectionIndex:
            return self.isLoggedIn ? 3 : 2
        case self.statusSectionIndex:
            return 3
        default:
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case self.actionSectionIndex:
            return "Actions"
        case self.statusSectionIndex:
            return "Login Status"
        default:
            return ""
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case self.actionSectionIndex:
            let cell = tableView.dequeueReusableCell(withIdentifier: "action", for: indexPath)
            if indexPath.row == 0 {
                cell.textLabel?.text = "Login"
            } else if indexPath.row == 1 {
                cell.textLabel?.text = "Signup"
            } else if indexPath.row == 2 {
                cell.textLabel?.text = "Logout"
            }
            return cell
        case self.statusSectionIndex:
            let cell = tableView.dequeueReusableCell(withIdentifier: "plain", for: indexPath)
            if indexPath.row == 0 {
                cell.textLabel?.text = "Username"
                cell.detailTextLabel?.text = self.lastUsername
            } else if indexPath.row == 1 {
                cell.textLabel?.text = "User Record ID"
                cell.detailTextLabel?.text = SKYContainer.default().auth.currentUserRecordID
            } else if indexPath.row == 2 {
                cell.textLabel?.text = "Access Token"
                cell.detailTextLabel?.text = SKYContainer.default().auth.currentAccessToken.tokenString
            }
            return cell
        default:
            return UITableViewCell()
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case self.actionSectionIndex:
            if indexPath.row == 0 {
                self.login(self.lastUsername)
            } else if indexPath.row == 1 {
                self.signup(nil)
            } else if indexPath.row == 2 {
                self.logout()
            }
        default:
            break
        }
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
}
