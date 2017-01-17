//
//  ViewController.swift
//  chat-demo
//
//  Created by Joey on 8/25/16.
//  Copyright © 2016 Oursky Ltd. All rights reserved.
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
        if let recordName = user.recordID.recordName {
            print("User \(recordName) is selected.")
        }

    }
}
