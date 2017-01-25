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

open class SKYChatConversationViewController: JSQMessagesViewController {
    public var skygear: SKYContainer = SKYContainer.default()
    public var conversation: SKYConversation?
    public var participants: [String: SKYRecord] = [:]
    public var messages: [SKYMessage] = []
    public var messagesFetchLimit: UInt = 25

    public var bubbleFactory: JSQMessagesBubbleImageFactory? = JSQMessagesBubbleImageFactory()
    public var incomingMessageBubble: JSQMessagesBubbleImage?
    public var outgoingMessageBubble: JSQMessagesBubbleImage?

    public var incomingMessageBubbleColor: UIColor? {
        didSet {
            self.incomingMessageBubble = self.bubbleFactory?
                .incomingMessagesBubbleImage(with: self.incomingMessageBubbleColor)
        }
    }

    public var outgoingMessageBubbleColor: UIColor? {
        didSet {
            self.outgoingMessageBubble = self.bubbleFactory?
                .outgoingMessagesBubbleImage(with: self.outgoingMessageBubbleColor)
        }
    }

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

    override open func viewDidLoad() {
        super.viewDidLoad()

        self.senderId = self.skygear.currentUserRecordID

        // update the display name after fetching participants
        self.senderDisplayName = "me"

        self.incomingMessageBubbleColor = UIColor.lightGray
        self.outgoingMessageBubbleColor = UIColor.jsq_messageBubbleBlue()
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard self.conversation != nil else {
            print("Error: Conversation is not set")
            self.dismiss(animated: animated)
            return
        }

        if let title = self.conversation?.title {
            self.navigationItem.title = title
        }

        self.fetchParticipants(completion: nil)
        self.fetchMessages(before: nil, completion: nil)
    }

    override open func viewDidDisappear(_ animated: Bool) {
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

// MARK: - Rendering

extension SKYChatConversationViewController {

    open func reloadViews() {
        self.collectionView?.reloadData()
        self.collectionView?.layoutIfNeeded()
    }

    open override func collectionView(_ collectionView: UICollectionView,
                                      numberOfItemsInSection section: Int) -> Int {
        return self.messages.count
    }

    open override func collectionView(_ collectionView: JSQMessagesCollectionView!,
                                      messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        let msg = self.messages[indexPath.row]

        var msgSenderName: String = ""
        if let sender = self.getSender(forMessage: msg),
            let senderName = sender.object(forKey: "name") as? String {

            msgSenderName = senderName
        }

        return JSQMessage(senderId: msg.creatorUserRecordID,
                          senderDisplayName: msgSenderName,
                          date: msg.creationDate,
                          text: msg.body)
    }

    open override func collectionView(
        _ collectionView: JSQMessagesCollectionView!,
        messageBubbleImageDataForItemAt indexPath: IndexPath!
    ) -> JSQMessageBubbleImageDataSource! {

        let msg = self.messages[indexPath.row]
        if msg.creatorUserRecordID == self.senderId {
            return self.outgoingMessageBubble
        }

        return self.incomingMessageBubble
    }

    open override func collectionView(
        _ collectionView: JSQMessagesCollectionView!,
        attributedTextForCellBottomLabelAt indexPath: IndexPath!
    ) -> NSAttributedString! {

        let msg = self.messages[indexPath.row]

        if msg.creatorUserRecordID != self.senderId {
            return nil
        }

        switch msg.conversationStatus {
        case .allRead:
            return NSAttributedString(string: "All read")
        case .someRead:
            return NSAttributedString(string: "Some read")
        case .delivered:
            return NSAttributedString(string: "Delivered")
        case .delivering:
            return NSAttributedString(string: "Delivering")
        }
    }

    open override func collectionView(
        _ collectionView: JSQMessagesCollectionView!,
        layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!,
        heightForCellBottomLabelAt indexPath: IndexPath!
    ) -> CGFloat {
        return CGFloat(14)
    }

    open override func collectionView(
        _ collectionView: JSQMessagesCollectionView!,
        avatarImageDataForItemAt indexPath: IndexPath!
    ) -> JSQMessageAvatarImageDataSource! {

        let msg = self.messages[indexPath.row]
        var senderName: String = ""
        if let user = self.getSender(forMessage: msg),
            let userName = user.object(forKey: "name") as? String {

            senderName = userName
        }

        if let avatarImage = UIImage.avatarImage(forInitialsOfName: senderName),
            let roundedImage = UIImage.circleImage(fromImage: avatarImage) {

            return JSQMessagesAvatarImage.avatar(with: roundedImage)
        }

        print("Error: Cannot generate avatar image")
        return nil
    }
}

// MARK: - Actions

extension SKYChatConversationViewController {
    open override func textViewDidChange(_ textView: UITextView) {
        super.textViewDidChange(textView)

        // TODO: trigger start typing event
    }

    open override func textViewDidEndEditing(_ textView: UITextView) {
        super.textViewDidEndEditing(textView)

        // TODO: trigger pause typing event
    }

    open override func didPressAccessoryButton(_ sender: UIButton!) {
        // TODO: handle press event of accessory button
    }

    open override func didPressSend(
        _ button: UIButton!,
        withMessageText text: String!,
        senderId: String!,
        senderDisplayName: String!,
        date: Date!
    ) {
        // TODO: error handling

        guard let msg = SKYMessage() else {
            print("Error: Failed to create new message")
            return
        }

        guard let conv = self.conversation else {
            print("Error: Cannot send message to nil conversation")
            return
        }

        msg.body = text
        msg.creatorUserRecordID = self.senderId
        msg.creationDate = date

        self.skygear.chatExtension?.addMessage(
            msg,
            to: conv,
            completion: { (result, error) in
                guard error == nil else {
                    print("Failed to sent message: \(error?.localizedDescription)")
                    return
                }

                guard let sentMsg = result else {
                    print("Error: Got nil sent message")
                    return
                }

                // find the index for the "sending" message
                guard let idx = self.messages.index(of: msg) else {
                    return
                }

                self.messages[idx] = sentMsg
                self.collectionView?.reloadData()
            }
        )

        self.messages.append(msg)
        self.finishSendingMessage(animated: true)

        // TODO: trigger finish typing event
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

                if let senderRecord = self.participants[self.senderId],
                    let senderName = senderRecord.object(forKey: "name") as? String {

                    self.senderDisplayName = senderName
                }

                completion?(participants, nil)

                self.reloadViews()

            }, perRecordErrorHandler: nil)
    }

    open func fetchMessages(before: Date?, completion: (([SKYMessage]?, Error?) -> Void)?) {
        guard self.conversation != nil else {
            print("Cannot fetch messages with nil conversation")
            return
        }

        self.skygear.chatExtension?.fetchMessages(
            conversation: self.conversation!,
            limit: Int(self.messagesFetchLimit),
            beforeTime: before,
            completion: { (msgs, error) in
                guard error == nil else {
                    print("Failed to fetch messages: \(error?.localizedDescription)")
                    completion?(nil, error)
                    return
                }

                guard msgs != nil else {
                    print("Failed to get any messages")
                    let err = self.errorCreator.error(with: SKYErrorBadResponse,
                                                      message: "Failed to get any messages")
                    completion?(nil, err)
                    return
                }

                let reversed = Array(msgs!.reversed())
                self.messages.append(contentsOf: reversed)

                completion?(reversed, nil)

                self.reloadViews()
                self.scrollToBottom(animated: true)
        })
    }

    open func getSender(forMessage message: SKYMessage) -> SKYRecord? {
        guard self.participants.count > 0 else {
            print("Warning: No participants are fetched")
            return nil
        }

        return self.participants[message.creatorUserRecordID]
    }
}
