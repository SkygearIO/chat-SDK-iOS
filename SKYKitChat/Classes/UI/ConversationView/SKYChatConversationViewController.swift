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

@objc public protocol SKYChatConversationViewControllerDelegate: class {

    /**
     * For customizing the views
     */

    @objc optional func incomingMessageColorForConversationViewController(
        _ controller: SKYChatConversationViewController) -> UIColor

    @objc optional func outgoingMessageColorForConversationViewController(
        _ controller: SKYChatConversationViewController) -> UIColor

    @objc optional func accessoryButtonShouldShowInConversationViewController(
        _ controller: SKYChatConversationViewController) -> Bool

    @objc optional func conversationViewController(
        _ controller: SKYChatConversationViewController,
        alertControllerForAccessoryButton button: UIButton) -> UIAlertController

    /**
     * Hooks on send message flow
     */

    @objc optional func conversationViewController(_ controller: SKYChatConversationViewController,
                                                   readyToSendMessage message: SKYMessage)

    @objc optional func conversationViewController(_ controller: SKYChatConversationViewController,
                                                   finishSendingMessage message: SKYMessage)

    @objc optional func conversationViewController(_ controller: SKYChatConversationViewController,
                                                   failedToSendMessageText text: String,
                                                   date: Date,
                                                   error: Error)

    /**
     * Hooks on fetching participants / fetch message flow
     */

    @objc optional func conversationViewController(_ controller: SKYChatConversationViewController,
                                                   didFetchedParticipants participants: [SKYRecord])

    @objc optional func conversationViewController(
        _ controller: SKYChatConversationViewController,
        failedFetchingParticipantWithError error: Error)
    
    @objc optional func startFetchingMessages(_ controller: SKYChatConversationViewController)

    @objc optional func conversationViewController(_ controller: SKYChatConversationViewController,
                                                   didFetchedMessages messages: [SKYMessage])

    @objc optional func conversationViewController(
        _ controller: SKYChatConversationViewController,
        failedFetchingMessagesWithError error: Error)
}

open class SKYChatConversationViewController: JSQMessagesViewController {

    weak public var delegate: SKYChatConversationViewControllerDelegate?

    public var skygear: SKYContainer = SKYContainer.default()
    public var conversation: SKYConversation?
    public var participants: [String: SKYRecord] = [:]
    public var messages: [SKYMessage] = []
    public var messagesFetchLimit: UInt = 25
    public var typingIndicatorShowDuration: TimeInterval = TimeInterval(5)

    public var messageChangeObserver: Any?
    public var typingIndicatorChangeObserver: Any?
    public var typingIndicatorPromptTimer: Timer?

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

        self.senderId = self.skygear.auth.currentUserRecordID

        // update the display name after fetching participants
        self.senderDisplayName = NSLocalizedString("me", comment: "")

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

        self.customizeViews()

        if self.participants.count == 0 {
            self.fetchParticipants()
        }

        if self.messages.count == 0 {
            self.fetchMessages(before: nil)
        }

        self.subscribeMessageChanges()
        self.subscribeTypingIndicatorChanges()
    }

    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        self.unsubscribeMessageChanges()
        self.unsubscribeTypingIndicatorChanges()
        self.skygear.chatExtension?.unsubscribeFromUserChannel()
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

    open func customizeViews() {
        self.updateTitle()

        if let color = self.delegate?.incomingMessageColorForConversationViewController?(self) {
            self.incomingMessageBubbleColor = color
        }

        if let color = self.delegate?.outgoingMessageColorForConversationViewController?(self) {
            self.outgoingMessageBubbleColor = color
        }

        let shouldShowAccessoryButton: Bool =
            self.delegate?.accessoryButtonShouldShowInConversationViewController?(self) ?? false

        if !shouldShowAccessoryButton {
            self.inputToolbar?.contentView?.leftBarButtonItem?.removeFromSuperview()
            self.inputToolbar?.contentView?.leftBarButtonItem = nil
        }
    }

    open func updateTitle() {
        if let title = self.conversation?.title {
            self.navigationItem.title = title
        } else if let namelist
            = self.conversation?.nameList(fromParticipants: self.participants.map { $0.value },
                                          currentUserID: self.senderId) {

            self.navigationItem.title = namelist
        } else {
            self.navigationItem.title = nil
        }
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

        return JSQMessage(senderId: msg.creatorUserRecordID(),
                          senderDisplayName: msgSenderName,
                          date: msg.creationDate(),
                          text: msg.body)
    }

    open override func collectionView(
        _ collectionView: JSQMessagesCollectionView!,
        messageBubbleImageDataForItemAt indexPath: IndexPath!
    ) -> JSQMessageBubbleImageDataSource! {

        let msg = self.messages[indexPath.row]
        if msg.creatorUserRecordID() == self.senderId {
            return self.outgoingMessageBubble
        }

        return self.incomingMessageBubble
    }

    open override func collectionView(
        _ collectionView: JSQMessagesCollectionView!,
        attributedTextForCellBottomLabelAt indexPath: IndexPath!
    ) -> NSAttributedString! {

        let msg = self.messages[indexPath.row]

        if msg.creatorUserRecordID() != self.senderId {
            return nil
        }

        switch msg.conversationStatus {
        case .allRead:
            return NSAttributedString(string: NSLocalizedString("All read", comment: ""))
        case .someRead:
            return NSAttributedString(string: NSLocalizedString("Some read", comment: ""))
        case .delivered:
            return NSAttributedString(string: NSLocalizedString("Delivered", comment: ""))
        case .delivering:
            return NSAttributedString(string: NSLocalizedString("Delivering", comment: ""))
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

    // Subclasses can override this method to render a custom typing indicator
    open func displayTypingIndicator() {
        guard self.showTypingIndicator == false else {
            // no need to update
            return
        }

        self.showTypingIndicator = true
        if self.automaticallyScrollsToMostRecentMessage {
            self.scrollToBottom(animated: true)
        }
    }

    // Subclasses can override this method to render a custom typing indicator
    open func hideTypingIndicator() {
        guard self.showTypingIndicator == true else {
            // no need to update
            return
        }

        self.showTypingIndicator = false
    }
}

// MARK: - Actions

extension SKYChatConversationViewController {
    open override func textViewDidChange(_ textView: UITextView) {
        super.textViewDidChange(textView)

        self.skygear.chatExtension?.sendTypingIndicator(.begin, in: self.conversation!)
    }

    open override func textViewDidEndEditing(_ textView: UITextView) {
        super.textViewDidEndEditing(textView)

        self.skygear.chatExtension?.sendTypingIndicator(.pause, in: self.conversation!)
    }

    open override func didPressAccessoryButton(_ sender: UIButton!) {
        if let alert =
            self.delegate?.conversationViewController?(self,
                                                       alertControllerForAccessoryButton: sender!) {
            self.present(alert, animated: true, completion: nil)
        }
    }

    open override func didPressSend(_ button: UIButton!,
                                    withMessageText text: String!,
                                    senderId: String!,
                                    senderDisplayName: String!,
                                    date: Date!) {

        

        guard let conv = self.conversation else {
            self.failedToSendMessage(text,
                                     date: date!,
                                     errorCode: SKYErrorInvalidArgument,
                                     errorMessage: "Cannot send message to nil conversation")
            return
        }

        
        let msg = SKYMessage()
        msg.body = text
        msg.setCreatorUserRecordID(self.senderId)
        msg.setCreationDate(date)

        self.delegate?.conversationViewController?(self, readyToSendMessage: msg)
        self.skygear.chatExtension?.addMessage(
            msg,
            to: conv,
            completion: { (result, error) in
                guard error == nil else {
                    print("Failed to sent message: \(error!.localizedDescription)")
                    self.failedToSendMessage(text,
                                             date: date!,
                                             errorCode: SKYErrorBadResponse,
                                             errorMessage: error!.localizedDescription)
                    return
                }

                guard let sentMsg = result else {
                    print("Error: Got nil sent message")
                    self.failedToSendMessage(text,
                                             date: date!,
                                             errorCode: SKYErrorBadResponse,
                                             errorMessage: "Got nil sent message")
                    return
                }

                // find the index for the "sending" message
                let ids = self.messages.map({$0.recordID().recordName})
                guard let idx = ids.index(of: sentMsg.recordID().recordName) else {
                    return
                }

                self.messages[idx] = sentMsg
                self.collectionView?.reloadData()

                self.delegate?.conversationViewController?(self, finishSendingMessage: sentMsg)
            }
        )

        self.messages.append(msg)
        self.finishSendingMessage(animated: true)

        self.skygear.chatExtension?.sendTypingIndicator(.finished, in: self.conversation!)
    }

    open func failedToSendMessage(_ messageText: String,
                                  date: Date,
                                  errorCode: SKYErrorCode,
                                  errorMessage: String) {

        let err = self.errorCreator.error(with: errorCode, message: errorMessage)
        self.delegate?.conversationViewController?(self,
                                                   failedToSendMessageText: messageText,
                                                   date: date,
                                                   error: err)
    }
}

// MARK: - Subscription

extension SKYChatConversationViewController {

    open func subscribeMessageChanges() {

        self.unsubscribeMessageChanges()

        let handler: ((SKYChatRecordChangeEvent, SKYMessage) -> Void) = {(event, msg) in
            let idx = self.messages
                .map({ $0.recordID().recordName })
                .index(of: msg.recordID().recordName
            )

            switch event {
            case .create:
                if let foundIndex = idx {
                    self.messages[foundIndex] = msg
                } else {
                    self.messages.append(msg)
                }

                self.skygear.chatExtension?.markReadMessages([msg], completion: nil)
                self.skygear.chatExtension?.markLastReadMessage(msg,
                                                                in: self.conversation!,
                                                                completion: nil)

                self.delegate?.conversationViewController?(self, didFetchedMessages: [msg])

                self.finishReceivingMessage()
            case .update:
                if let foundIndex = idx {
                    self.messages[foundIndex] = msg
                    self.collectionView.reloadData()
                    self.collectionView.layoutIfNeeded()
                }
            case .delete:
                if let foundIndex = idx {
                    self.messages.remove(at: foundIndex)
                    self.collectionView.reloadData()
                    self.collectionView.layoutIfNeeded()
                }
            }
        }

        self.messageChangeObserver = self.skygear.chatExtension?
            .subscribeToMessages(in: self.conversation!, handler: handler)

    }

    open func unsubscribeMessageChanges() {
        if let observer = self.messageChangeObserver {
            self.skygear.chatExtension?.unsubscribeToMessages(withObserver: observer)
            self.messageChangeObserver = nil
        }
    }

    open func subscribeTypingIndicatorChanges() {

        self.unsubscribeTypingIndicatorChanges()

        let handler: ((SKYChatTypingIndicator) -> Void) = {(indicator) in
            // invalidate the existing timer
            if let timer = self.typingIndicatorPromptTimer {
                timer.invalidate()
                self.typingIndicatorPromptTimer = nil
            }

            let shouldShowIndicator: Bool = indicator.userIDs
                .flatMap({ SKYRecordID(canonicalString: $0).recordName })
                .filter({ $0 != nil && $0 != self.senderId })
                .count > 0

            if shouldShowIndicator {
                self.displayTypingIndicator()

                // schedule a timer to hide the typing indicator
                self.typingIndicatorPromptTimer =
                    Timer.scheduledTimer(timeInterval: self.typingIndicatorShowDuration,
                                         target: self,
                                         selector: #selector(self.hideTypingIndicator),
                                         userInfo: nil,
                                         repeats: false)
            } else {
                self.hideTypingIndicator()
            }
        }

        self.typingIndicatorChangeObserver = self.skygear.chatExtension?
            .subscribeToTypingIndicator(in: self.conversation!, handler: handler)
    }

    open func unsubscribeTypingIndicatorChanges() {
        if let observer = self.typingIndicatorChangeObserver {
            self.skygear.chatExtension?.unsubscribeToTypingIndicator(withObserver: observer)
            self.typingIndicatorChangeObserver = nil
        }
    }
}

// MARK: - Utility Methods

extension SKYChatConversationViewController {

    open func fetchParticipants() {
        guard self.conversation != nil else {
            print("Cannot fetch participants with nil conversation")
            return
        }

        let participantIDs = self.conversation!.participantIds
            .map { (eachParticipantID) -> SKYRecordID in
                return SKYRecordID(recordType: "user", name: eachParticipantID)
            }

        self.skygear.publicCloudDatabase
            .fetchRecords(with: participantIDs, completionHandler: { (result, error) in
                guard error == nil else {
                    print("Failed to fetch participants: \(error?.localizedDescription ?? "")")
                    self.delegate?.conversationViewController?(
                        self, failedFetchingParticipantWithError: error!)

                    return
                }

                guard let participantMap = result as? [SKYRecordID: SKYRecord] else {
                    print("Fetched participants are in wrong format")
                    let err = self.errorCreator.error(
                        with: SKYErrorBadResponse,
                        message: "Fetched participants are in wrong format")

                    self.delegate?.conversationViewController?(
                        self, failedFetchingParticipantWithError: err)

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

                self.updateTitle()

                self.delegate?.conversationViewController?(
                    self, didFetchedParticipants: participants)

                self.collectionView?.reloadData()
                self.collectionView?.layoutIfNeeded()

            }, perRecordErrorHandler: nil)
    }

    open func fetchMessages(before: Date?) {
        guard self.conversation != nil else {
            print("Cannot fetch messages with nil conversation")
            return
        }

        let chatExt = self.skygear.chatExtension

        self.delegate?.startFetchingMessages?(self)
        chatExt?.fetchMessages(
            conversation: self.conversation!,
            limit: Int(self.messagesFetchLimit),
            beforeTime: before,
                 order: nil,
            completion: { (result, error) in
                guard error == nil else {
                    print("Failed to fetch messages: \(error?.localizedDescription ?? "")")
                    self.delegate?.conversationViewController?(
                        self, failedFetchingMessagesWithError: error!)

                    return
                }

                guard let msgs = result else {
                    print("Failed to get any messages")
                    let err = self.errorCreator.error(
                        with: SKYErrorBadResponse, message: "Failed to get any messages")

                    self.delegate?.conversationViewController?(
                        self, failedFetchingMessagesWithError: err)

                    return
                }

                if self.messages.count == 0, let first = msgs.first {
                    // this is the first page
                    chatExt?.markReadMessages(msgs, completion: nil)
                    chatExt?.markLastReadMessage(first,
                                                 in: self.conversation!,
                                                 completion: nil)
                }

                // prepend new messages
                var newMessages = Array(msgs.reversed())
                newMessages.append(contentsOf: self.messages)
                self.messages = newMessages

                self.delegate?.conversationViewController?(self, didFetchedMessages: msgs)

                self.finishReceivingMessage()
        })
    }

    open func getSender(forMessage message: SKYMessage) -> SKYRecord? {
        guard self.participants.count > 0 else {
            print("Warning: No participants are fetched")
            return nil
        }

        return self.participants[message.creatorUserRecordID()]
    }
}
