//
//  ViewController.swift
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
import SKYKitChat

class MainViewController: UITableViewController {

    var hasPromptedForConfiguration: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "HasPromptedForConfiguration")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "HasPromptedForConfiguration")
            UserDefaults.standard.synchronize()
        }
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        if !self.hasPromptedForConfiguration {
            let alert = UIAlertController(title: "Configuration Required",
                                          message: "The app does not know how to connect to your Skygear Server. Configure the app now?",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ignore", style: .cancel, handler: { (action) in
                self.hasPromptedForConfiguration = true
            }))
            alert.addAction(UIAlertAction(title: "Configure", style: .default, handler: { (action) in
                self.hasPromptedForConfiguration = true
                self.performSegue(withIdentifier: "server_configuration", sender: self)
            }))
            alert.preferredAction = alert.actions.last
            self.present(alert, animated: true, completion: nil)
        }

    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if let segueID = segue.identifier {
            switch segueID {
            case "ShowUserQueryVew":
                if let dest = segue.destination as? SKYChatParticipantListViewController {
                    dest.delegate = self
                } else {
                    print("Warning: Destination View Controller is in wrong type")
                }
            default:
                break
            }
        }
    }

}

extension MainViewController: SKYChatParticipantListViewControllerDelegate {
    public func listViewController(_ controller: SKYChatParticipantListViewController,
                                   didSelectParticipant user: SKYRecord) {
        let _ = self.navigationController?.popViewController(animated: true)
        let recordName = user.recordID.recordName
        print("User \(recordName) is selected.")

    }
}
