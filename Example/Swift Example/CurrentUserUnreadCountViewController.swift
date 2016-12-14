//
//  CurrentUserUnreadCountViewController.swift
//  chat-demo
//
//  Created by Joey on 8/26/16.
//  Copyright © 2016 Oursky Ltd. All rights reserved.
//

import UIKit
import SKYKit
import SKYKitChat

class CurrentUserUnreadCountViewController: UITableViewController {

    let unreadConversationCountRowIndex = 0
    let unreadMessageCountRowIndex = 1

    var unreadConversationCount: Int?
    var unreadMessageCount: Int?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // SDK should implement get total unread
        SKYContainer.default().chatExtension?.fetchTotalUnreadCount { (response, error) in
            if let err = error {
                let alert = UIAlertController(title: "Unable to get unread count", message: err.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }

            if let resp = response {
                self.unreadConversationCount = resp[SKYChatConversationUnreadCountKey] as? Int
                self.unreadMessageCount = resp[SKYChatMessageUnreadCountKey] as? Int

                self.tableView.reloadData()
            }

        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "plain", for: indexPath)
        switch indexPath.row {
        case self.unreadConversationCountRowIndex:
            cell.textLabel?.text = "Conversation"
            if let count = self.unreadConversationCount {
                cell.detailTextLabel?.text = String(count)
            }
            return cell
        case self.unreadMessageCountRowIndex:
            cell.textLabel?.text = "Message"
            if let count = self.unreadMessageCount {
                cell.detailTextLabel?.text = String(count)
            }
            return cell
        default:
            return UITableViewCell()
        }
    }
}
