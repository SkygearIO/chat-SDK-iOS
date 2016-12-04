//
//  ConversationsViewController.swift
//  chat-demo
//
//  Created by Joey on 9/1/16.
//  Copyright © 2016 Oursky Ltd. All rights reserved.
//

import UIKit
import SKYKit
import SKYKitChat

class ConversationsViewController: UITableViewController {
    
    var userCons = [SKYUserConversation]()
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        SKYContainer.default().chatExtension?.fetchUserConversations { (userCons, error) in
            if let err = error {
                let alert = UIAlertController(title: "Unable to fetch conversations", message: err.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }

            if let cons = userCons {
                self.userCons = cons.reversed()
                self.tableView.reloadData()
            }
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "conversation_room" {
            let controller = segue.destination as! ConversationRoomViewController
            controller.userCon = sender as! SKYUserConversation
        }
    }


    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userCons.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        let conversation = userCons[indexPath.row].conversation
        cell.textLabel?.text = conversation.title
        cell.detailTextLabel?.text = conversation.recordID.canonicalString

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "conversation_room", sender: userCons[indexPath.row])
    }

}
