//
//  SKYChatConversationViewController.swift
//  SKYKitChat
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

import JSQMessagesViewController

class SKYChatConversationViewController: JSQMessagesViewController {
    public var skygear: SKYContainer = SKYContainer.default()
    public var conversation: SKYConversation?
    public var participants: [String: SKYRecord] = [:]
    public var messages: [SKYMessage] = []

    static let errorDomain: String = "SKYChatConversationViewControllerErrorDomain"
    var errorCreator: SKYErrorCreator {
        return SKYErrorCreator(defaultErrorDomain: SKYChatConversationViewController.errorDomain)
    }
}

// MARK: - Initializing

extension SKYChatConversationViewController {

    public class func create() -> SKYChatConversationViewController {
        return SKYChatConversationViewController(nibName: "JSQMessagesViewController",
                                                 bundle: Bundle(for: JSQMessagesViewController.self))
    }
}

// MARK: - Lifecycle

extension SKYChatConversationViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        SKYChatConversationViewController.nib().instantiate(withOwner: self, options: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard self.conversation != nil else {
            print("Conversation is not set")
            self.dismiss(animated: animated)
            return
        }

        self.fetchParticipants(completion: nil)
        self.fetchMessages(before: nil, completion: nil)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

    }

    func dismiss(animated: Bool) {
        if let nc = self.navigationController, let topVC = nc.topViewController {
            guard self == topVC else {
                // I am not the top view controller
                return
            }

            nc.popViewController(animated: animated)
        } else {
            self.dismiss(animated: animated, completion: nil)
        }
    }
}

// MARK: - Utility Methods

extension SKYChatConversationViewController {

    open func fetchParticipants(completion: (([SKYRecord]?, Error?) -> Void)?) {
        guard self.conversation != nil else {
            print("Cannot fetch participants with nil conversation")
            return
        }

        let participantIDs = self.conversation!.participantIds
            .map { (eachParticipantID) -> SKYRecordID in
                return SKYRecordID(recordType: "user", name: eachParticipantID)
            }

        self.skygear.publicCloudDatabase?
            .fetchRecords(withIDs: participantIDs, completionHandler: { (result, error) in
                guard error == nil else {
                    print("Failed to fetch participants: \(error?.localizedDescription)")
                    completion?(nil, error)
                    return
                }

                guard let participantMap = result as? [SKYRecordID: SKYRecord] else {
                    print("Fetched participants are in wrong format")
                    let err = self.errorCreator.error(with: SKYErrorBadResponse,
                                                      message: "Fetched participants are in wrong format")
                    completion?(nil, err)
                    return
                }

                var participants: [SKYRecord] = []
                for (k, v) in participantMap {
                    self.participants[k.recordName] = v
                    participants.append(v)
                }

                // TODO: need a reload here
                completion?(participants, nil)

            }, perRecordErrorHandler: nil)
    }

    open func fetchMessages(before: Date?, completion: (([SKYMessage]?, Error?) -> Void)?) {
        guard self.conversation != nil else {
            print("Cannot fetch messages with nil conversation")
            return
        }

        self.skygear.chatExtension?.fetchMessages(
            conversation: self.conversation!,
            limit: 100,
            beforeTime: before,
            completion: { (messages, error) in
                guard error == nil else {
                    print("Failed to fetch messages: \(error?.localizedDescription)")
                    completion?(nil, error)
                    return
                }

                guard messages != nil else {
                    print("Failed to get any messages")
                    let err = self.errorCreator.error(with: SKYErrorBadResponse,
                                                      message: "Failed to get any messages")
                    completion?(nil, err)
                    return
                }

                self.messages.append(contentsOf: messages!)

                // TODO: need a reload here
                completion?(messages!, nil)
        })
    }
}
