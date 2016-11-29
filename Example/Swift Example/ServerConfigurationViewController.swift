//
//  ServerConfigurationViewController.swift
//  chat-demo
//
//  Created by Joey on 8/26/16.
//  Copyright © 2016 Oursky Ltd. All rights reserved.
//

import UIKit
import SKYKit

class ServerConfigurationViewController: UITableViewController {
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "plainTableViewCell", for: indexPath)
        
        if indexPath.row == 0 {
            cell.textLabel?.text = "Endpoint"
            cell.detailTextLabel?.text = UserDefaults.standard.string(forKey: "SkygearEndpoint")
        } else if indexPath.row == 1 {
            cell.textLabel?.text = "API Key"
            cell.detailTextLabel?.text = UserDefaults.standard.string(forKey: "SkygearApiKey")
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            let alert = UIAlertController(title: "Endpoint", message: "Enter the Skygear Endpoint (you can obtained this from portal)", preferredStyle: .alert)
            alert.addTextField { (textField) in
                textField.placeholder = "https://myapp.skygeario.com/"
                textField.text = UserDefaults.standard.string(forKey: "SkygearEndpoint")
            }
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:nil))
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                let textField = alert.textFields?.first
                UserDefaults.standard.set(textField?.text, forKey: "SkygearEndpoint")
                UserDefaults.standard.synchronize()
                SKYContainer.default().configAddress(textField?.text)
                self.tableView.reloadRows(at: [indexPath], with: .automatic)
            }))
            alert.preferredAction = alert.actions.last
            self.present(alert, animated: true, completion: nil)
        } else if indexPath.row == 1 {
            let alert = UIAlertController(title: "API Key", message: "Enter the Skygear API Key (you can obtained this from portal)", preferredStyle: .alert)
            alert.addTextField { (textField) in
                textField.placeholder = "dc0903fa85924776baa77df813901efc"
                textField.text = UserDefaults.standard.string(forKey: "SkygearApiKey")
            }
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:nil))
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                let textField = alert.textFields?.first
                UserDefaults.standard.set(textField?.text, forKey: "SkygearApiKey")
                UserDefaults.standard.synchronize()
                SKYContainer.default().configure(withAPIKey: textField?.text)
                self.tableView.reloadRows(at: [indexPath], with: .automatic)
            }))
            alert.preferredAction = alert.actions.last
            self.present(alert, animated: true, completion: nil)
        }
    }
}

