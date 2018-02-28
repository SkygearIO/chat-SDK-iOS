//
//  CreateDirectConversation.swift
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
            SKYContainer.default().chatExtension?.createDirectConversation(participantID: id, title: nil, metadata: nil) { (conversation, error) in
                if let err = error {
                    let alert = UIAlertController(title: "Unable to create direct conversation", message: err.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    return
                }

                self.createdConversationTextView.text = conversation?.recordID().canonicalString
            }
        }
    }
}
