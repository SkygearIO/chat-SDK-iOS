//
//  CreateDirectConversation.swift
//  chat-demo
//
//  Created by Joey on 8/26/16.
//  Copyright © 2016 Oursky Ltd. All rights reserved.
//

import UIKit
import SKYKit

class CreateDirectConversationViewController: UIViewController {
    
    @IBOutlet var userIdTextField: UITextField!
    @IBOutlet var createdConversationTextView: UITextView!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    // MARK: - Actions
    
    @IBAction func createConversation(_ sneder: AnyObject!) {
        if var id = userIdTextField.text, !id.isEmpty {
            
            if id.hasPrefix("user/") {
                id = id.substring(from: "user/".endIndex)
            }
            SKYContainer.default().chatExtension().createDirectConversation(userID: id, title: nil, metadata: nil) { (conversation, error) in
                if let err = error {
                    let alert = UIAlertController(title: "Unable to create direct conversation", message: err.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    return
                }

                self.createdConversationTextView.text = conversation?.recordID.canonicalString
            }
        }
    }
}
