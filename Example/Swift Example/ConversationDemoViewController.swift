//
//  ConversationDemoViewController.swift
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

import SKYKitChat

let assetCache: SKYAssetCache = SKYAssetMemoryCache(maxSize: 20)

class ConversationDemoViewController: SKYChatConversationViewController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.messageMediaDataFactory = JSQMessageMediaDataFactory(with: assetCache)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.delegate = self
    }
}

extension ConversationDemoViewController: SKYChatConversationViewControllerDelegate {
    func backgroundColorForConversationViewController(_ controller: SKYChatConversationViewController) -> UIColor
    {
        return UIColor(white: 0.95, alpha: 1.0)
    }

    func incomingMessageColorForConversationViewController(
        _ controller: SKYChatConversationViewController) -> UIColor
    {
        return UIColor.lightGray
    }

    func accessoryButtonShouldShowInConversationViewController(
        _ controller: SKYChatConversationViewController) -> Bool
    {
        return true
    }

    func conversationViewController(
        _ controller: SKYChatConversationViewController,
        alertControllerForAccessoryButton button: UIButton) -> UIAlertController
    {
        let alert = UIAlertController(title: "Accessory Button Action",
                                      message: nil,
                                      preferredStyle: .actionSheet)

        alert.addAction(
            UIAlertAction(title: "Info.", style: .default, handler: { _ in
                let newAlert =
                    UIAlertController(title: "Info.",
                                      message: "Custom action can be added to the Accessory Button",
                                      preferredStyle: .alert)
                newAlert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
                self.present(newAlert, animated: true, completion: nil)
            })
        )

        alert.addAction(
            UIAlertAction(title: "Photo", style: .default, handler: self.defaultPhotoPickerActionHandler())
        )

        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))

        return alert
    }
}
