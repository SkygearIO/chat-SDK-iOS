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
import ALCameraViewController
import CTAssetsPickerController
import AVFoundation
import SKPhotoBrowser

@objc public protocol SKYChatConversationViewControllerDelegate: class {

    /**
     * For customizing message date display
     */

    @objc optional func conversationViewController(
        _ controller: SKYChatConversationViewController,
        dateStringAt indexPath: IndexPath) -> NSAttributedString

    @objc optional func conversationViewController(
        _ controller: SKYChatConversationViewController,
        shouldShowDateAt indexPath: IndexPath) -> Bool

    /**
     * For customizing the views
     */

    @objc optional func incomingMessageColorForConversationViewController(
        _ controller: SKYChatConversationViewController) -> UIColor

    @objc optional func outgoingMessageColorForConversationViewController(
        _ controller: SKYChatConversationViewController) -> UIColor

    @objc optional func accessoryButtonShouldShowInConversationViewController(
        _ controller: SKYChatConversationViewController) -> Bool

    @objc optional func cameraButtonShouldShowInConversationViewController(
        _ controller: SKYChatConversationViewController) -> Bool

    @objc optional func conversationViewController(
        _ controller: SKYChatConversationViewController,
        alertControllerForAccessoryButton button: UIButton) -> UIAlertController

    @objc optional func conversationViewController(
        _ controller: SKYChatConversationViewController,
        shouldShowSenderNameAt indexPath: IndexPath) -> Bool

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

open class SKYChatConversationViewController: JSQMessagesViewController, AVAudioRecorderDelegate, SKYChatConversationImageItemDelegate {

    weak public var delegate: SKYChatConversationViewControllerDelegate?

    public var skygear: SKYContainer = SKYContainer.default()
    public var conversation: SKYConversation?
    public var participants: [String: SKYRecord] = [:]
    public var messages: [SKYMessage] = []
    public var messagesFetchLimit: UInt = 25
    public var typingIndicatorShowDuration: TimeInterval = TimeInterval(5)
    public var offsetYToLoadMore: CGFloat = CGFloat(40)
    fileprivate var hasMoreMessageToFetch: Bool = false
    fileprivate var isFetchingMessage: Bool = false

    public var messageChangeObserver: Any?
    public var typingIndicatorChangeObserver: Any?
    public var typingIndicatorPromptTimer: Timer?

    public var bubbleFactory: JSQMessagesBubbleImageFactory? = JSQMessagesBubbleImageFactory()
    public var incomingMessageBubble: JSQMessagesBubbleImage?
    public var outgoingMessageBubble: JSQMessagesBubbleImage?

    var defaultMediaDataFactory: JSQMessageMediaDataFactory = JSQMessageMediaDataFactory()
    open var messageMediaDataFactory: JSQMessageMediaDataFactory {
        get {
            return defaultMediaDataFactory
        }
    }


    public var cameraButton: UIButton?

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

    open func getMessageMediaDataFactory() -> JSQMessageMediaDataFactory {
        return messageMediaDataFactory
    }

    var sendButton: UIButton?
    var recordButton: UIButton?
    var audioRecorder: AVAudioRecorder?
    var inputTextView: UITextView?
    var slideToCancelTextView: UITextView?
    var gesture: UILongPressGestureRecognizer?
    var isRecordingCancelled: Bool = false
    var audioDict: [String: SKYChatConversationAudioItem] = [:]
    var audioTime: TimeInterval?
    var indicator: UIActivityIndicatorView?
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
        for (key, audioItem) in self.audioDict {
            audioItem.stop()
        }
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
    func createSlideToCancelTextView(_ frame: CGRect) -> UITextView {
        let textView = UITextView(frame: frame)
        textView.isEditable = false
        textView.isSelectable = false
        textView.text = "Slide to Cancel";
        textView.backgroundColor = UIColor.clear
        textView.textColor = UIColor.darkGray
        return textView
    }

    func createRecordButton(_ frame: CGRect) -> UIButton {
        let recordButton = UIButton(frame: frame)
        recordButton.setImage(UIImage(named: "icon-mic", in: self.bundle(), compatibleWith: nil), for: UIControlState.normal)
        recordButton.tintColor = self.sendButton?.tintColor
        return recordButton
    }

    func reLayout() {
        let contentView = self.inputToolbar?.contentView
        let rightContainerView = contentView?.rightBarButtonContainerView
        let sendButton = contentView?.rightBarButtonItem
        let cameraButton = self.cameraButton!
        rightContainerView?.removeConstraints(rightContainerView?.constraints ?? [])

        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: cameraButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 32),
            NSLayoutConstraint(item: cameraButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 32),
            NSLayoutConstraint(item: cameraButton, attribute: .left, relatedBy: .equal, toItem: rightContainerView, attribute: .left, multiplier: 1, constant: 8),
            NSLayoutConstraint(item: cameraButton, attribute: .right, relatedBy: .equal, toItem: sendButton, attribute: .left, multiplier: 1, constant: -8),
            NSLayoutConstraint(item: cameraButton, attribute: .top, relatedBy: .equal, toItem: rightContainerView, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: cameraButton, attribute: .bottom, relatedBy: .equal, toItem: rightContainerView, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: sendButton, attribute: .right, relatedBy: .equal, toItem: rightContainerView, attribute: .right, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: sendButton, attribute: .top, relatedBy: .equal, toItem: rightContainerView, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: sendButton, attribute: .bottom, relatedBy: .equal, toItem: rightContainerView, attribute: .bottom, multiplier: 1, constant: 0)
            ])
    }

    func shouldShowCameraButton() -> Bool {
        return
            self.delegate?.cameraButtonShouldShowInConversationViewController?(self) ?? true
    }

    func createActivityIndicator() {
        self.indicator = UIActivityIndicatorView()
        self.indicator?.activityIndicatorViewStyle = .gray
        self.indicator?.hidesWhenStopped = true
        self.view.addSubview(indicator!)
        indicator?.superview?.bringSubview(toFront: indicator!)
        indicator?.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: self.indicator!, attribute: .centerX, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.indicator!, attribute: .centerY, relatedBy: .equal, toItem: self.view, attribute: .centerY, multiplier: 1, constant: 0)
            ])
    }
    
    open func customizeViews() {
        self.updateTitle()

        if let color = self.delegate?.incomingMessageColorForConversationViewController?(self) {
            self.incomingMessageBubbleColor = color
        }

        if let color = self.delegate?.outgoingMessageColorForConversationViewController?(self) {
            self.outgoingMessageBubbleColor = color
        }

        let shouldShowAccessoryButton: Bool =
            self.delegate?.accessoryButtonShouldShowInConversationViewController?(self) ?? true

        if !shouldShowAccessoryButton {
            self.inputToolbar?.contentView?.leftBarButtonItem?.removeFromSuperview()
            self.inputToolbar?.contentView?.leftBarButtonItem = nil
        }

        let shouldShowCameraButton: Bool = self.shouldShowCameraButton()

        self.sendButton = self.inputToolbar?.contentView?.rightBarButtonItem
        self.sendButton?.removeFromSuperview()
        self.inputTextView = self.inputToolbar?.contentView?.textView
        self.slideToCancelTextView = self.createSlideToCancelTextView(self.inputTextView!.frame)
        self.recordButton = self.createRecordButton(self.sendButton!.frame)

        if shouldShowCameraButton {
            let cameraButton = UIButton(type: .custom)
            cameraButton.translatesAutoresizingMaskIntoConstraints = false
            cameraButton.setImage(UIImage(named: "icon-camera", in: self.bundle(), compatibleWith: nil), for: .normal)
            cameraButton.addTarget(self, action: #selector(didPressCameraButton(_:)), for: .touchUpInside)
            self.inputToolbar?.contentView?.rightBarButtonContainerView.addSubview(cameraButton)
            self.cameraButton = cameraButton
        }

        self.setRecordButton()
        self.createActivityIndicator()
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
            let senderName = sender.object(forKey: "username") as? String {

            msgSenderName = senderName
        }
        
        let mediaData = self.messageMediaDataFactory.mediaData(with: msg)
        var jsqMessage: JSQMessage

        if mediaData == nil {
            jsqMessage = JSQMessage(senderId: msg.creatorUserRecordID(),
                                    senderDisplayName: msgSenderName,
                                    date: msg.creationDate(),
                                    text: msg.body)
        } else {
            
            
            jsqMessage = JSQMessage(senderId: msg.creatorUserRecordID(),
                                    senderDisplayName: msgSenderName,
                                    date: msg.creationDate(),
                                    media: mediaData)
            
            /* Need to store strong reference for audio data
               https://github.com/jessesquires/JSQMessagesViewController/issues/1705
            */
            if let audioItem = mediaData as? SKYChatConversationAudioItem {
                let key = msg.recordID().canonicalString
                if let origAudioItem = self.audioDict[key] {
                    origAudioItem.stop()
                }
                self.audioDict[key] = audioItem
            }
            
            if let imageItem = mediaData as? SKYChatConversationImageItem {
                imageItem.delegate = self
            }
        }

        return jsqMessage
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
        attributedTextForCellTopLabelAt indexPath: IndexPath!
        ) -> NSAttributedString! {
        if let ds = self.delegate?.conversationViewController?(self, dateStringAt: indexPath) {
            return ds
        }
        
        let msg = self.messages[indexPath.row]
        let date = msg.creationDate()
        
        let dateFormatter: DateFormatter
        dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateFormatter.doesRelativeDateFormatting = true
        let dateString = dateFormatter.string(from: date)
        
        return NSAttributedString(string: "\(dateString)")
    }
    
    open override func collectionView(
        _ collectionView: JSQMessagesCollectionView!,
        layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!,
        heightForCellTopLabelAt indexPath: IndexPath!
        ) -> CGFloat {
        var shouldShow: Bool
        if let s = self.delegate?.conversationViewController?(self, shouldShowDateAt: indexPath) {
            shouldShow = s
        } else {
            // default behaviour
            // skip when date string is the same as previous one
            if indexPath.row == 0 {
                shouldShow = true
            } else {
                let thisString = self.collectionView(collectionView,
                                                     attributedTextForCellTopLabelAt: indexPath)
                let lastIndexPath = IndexPath(row: indexPath.row - 1, section: indexPath.section)
                let lastString = self.collectionView(collectionView,
                                                     attributedTextForCellTopLabelAt: lastIndexPath)
                shouldShow = thisString?.string != lastString?.string
            }
        }
        
        return shouldShow ? CGFloat(20) : CGFloat(0)
    }
    
    open override func collectionView(
        _ collectionView: JSQMessagesCollectionView!,
        attributedTextForMessageBubbleTopLabelAt indexPath: IndexPath!
        ) -> NSAttributedString! {
        let msg = self.messages[indexPath.row]
        var senderName: String = ""
        if let user = self.getSender(forMessage: msg),
            let userName = user.object(forKey: "username") as? String {
            senderName = userName
        }
        
        return NSAttributedString(string: senderName)
    }
    
    open override func collectionView(
        _ collectionView: JSQMessagesCollectionView!,
        layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!,
        heightForMessageBubbleTopLabelAt indexPath: IndexPath!
        ) -> CGFloat {
        var shouldShow: Bool
        if let s
            = self.delegate?.conversationViewController?(self, shouldShowSenderNameAt: indexPath) {
            shouldShow = s
        } else {
            // default behaviour
            // skip when it is "me" or only two members or sender name is the same as previous one
            let msg = self.messages[indexPath.row]
            if msg.creatorUserRecordID() == self.senderId || self.participants.count < 3 {
                shouldShow = false
            } else if indexPath.row == 0 {
                shouldShow = true
            } else {
                let thisString = self.collectionView(
                    collectionView,
                    attributedTextForMessageBubbleTopLabelAt: indexPath
                )
                let lastIndexPath = IndexPath(row: indexPath.row - 1, section: indexPath.section)
                let lastString = self.collectionView(
                    collectionView,
                    attributedTextForMessageBubbleTopLabelAt: lastIndexPath
                )
                shouldShow = thisString?.string != lastString?.string
            }
        }
        
        return shouldShow ? CGFloat(14) : CGFloat(0)
    }
    
    open override func collectionView(
        _ collectionView: JSQMessagesCollectionView!,
        avatarImageDataForItemAt indexPath: IndexPath!
    ) -> JSQMessageAvatarImageDataSource! {

        let msg = self.messages[indexPath.row]
        var senderName: String = ""
        if let user = self.getSender(forMessage: msg),
            let userName = user.object(forKey: "username") as? String {

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
    
    open func setRecordButton() {
        self.inputToolbar?.contentView?.rightBarButtonItem = self.recordButton
        self.inputToolbar?.contentView?.rightBarButtonItem.removeTarget(self, action: nil, for: UIControlEvents.touchUpInside)
        self.inputToolbar?.contentView?.rightBarButtonItem.removeTarget(self, action: nil, for: UIControlEvents.touchDown)
        self.inputToolbar?.contentView?.rightBarButtonItem.removeTarget(self.inputToolbar, action: nil, for: UIControlEvents.touchUpInside)
        self.inputToolbar?.contentView?.rightBarButtonItem.isEnabled = true
        self.cameraButton?.isHidden = false
        self.gesture = UILongPressGestureRecognizer(target: self, action: #selector(longPressAction(gesture:)))
        self.gesture?.minimumPressDuration = 0.1
        self.inputToolbar?.contentView?.rightBarButtonItem.addGestureRecognizer(self.gesture!)
        if self.shouldShowCameraButton() {
            self.reLayout()
        }
    }
    
    open func setSendButton() {
        self.inputToolbar?.contentView?.rightBarButtonItem.removeGestureRecognizer(self.gesture!)
        self.inputToolbar?.contentView?.rightBarButtonItem = self.sendButton
        self.inputToolbar?.contentView?.rightBarButtonItem.removeTarget(self.inputToolbar, action: nil, for: UIControlEvents.touchUpInside)
        self.inputToolbar?.contentView?.rightBarButtonItem.addTarget(self, action: #selector(didPressSendButton), for: UIControlEvents.touchUpInside)
        if self.shouldShowCameraButton() {
            self.reLayout()
        }
    }
    
    func longPressAction(gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            self.didStartRecord(button: self.recordButton!)
        }
        else {
            var cancelled = gesture.state == .cancelled
            if gesture.state == .changed || gesture.state == .ended {
                guard let view = gesture.view else {
                    return
                }
                
                let point = gesture.location(in: view.superview)
                if point.x < -10 || point.y < -10 {
                    cancelled = true
                }
            }
            
            if cancelled {
                self.didStopRecord(button: self.recordButton!, cancelled: true)
            }
            else if gesture.state == .ended && !cancelled {
                self.didStopRecord(button: self.recordButton!)
            }
        }
    }
    
    open func imageDidTap(_ url: URL?) {
        let photo = SKPhoto.photoWithImageURL(url!.absoluteString)
        let browser = SKPhotoBrowser(photos: [photo])
        
        self.present(browser, animated: true, completion: nil)
    }

    func defaultAccessoryButtonAlertController() -> UIAlertController {
        let alert = UIAlertController(title: "Actions",
                                      message: nil,
                                      preferredStyle: .actionSheet)


        // TODO: support Photo or Video
        alert.addAction(
            UIAlertAction(title: "Photo" /* Photo or Video */, style: .default, handler: self.defaultPhotoPickerActionHandler())
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        return alert
    }

    open func didPressCameraButton(_ sender: UIButton!) {
        // There is always a cropping overlay
        // So just disable it
        let croppingParams = CroppingParameters(isEnabled: false, allowResizing: true, allowMoving: true, minimumSize: CGSize.init(width: 64, height: 64))
        let imagePicker = CameraViewController(croppingParameters: croppingParams, allowsLibraryAccess: false) { [weak self] image, _ in
            if image != nil {
                self?.send(image: image!)
            }
            self?.dismiss(animated: true, completion: nil)
        }

        self.present(imagePicker, animated: true, completion: nil)
    }
}


// MARK: - Send Message

extension SKYChatConversationViewController {
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
    
    func sendMessage(_ msg: SKYMessage) {
        guard let conv = self.conversation else {
            self.failedToSendMessage(msg.body ?? "",
                                     date: msg.creationDate(),
                                     errorCode: SKYErrorInvalidArgument,
                                     errorMessage: "Cannot send message to nil conversation")
            return
        }

        self.delegate?.conversationViewController?(self, readyToSendMessage: msg)
        self.skygear.chatExtension?.addMessage(
            msg,
            to: conv,
            completion: { (result, error) in
                guard error == nil else {
                    print("Failed to sent message: \(error!.localizedDescription)")
                    self.failedToSendMessage(msg.body ?? "",
                                             date: msg.creationDate(),
                                             errorCode: SKYErrorBadResponse,
                                             errorMessage: error!.localizedDescription)
                    return
                }
                
                guard let sentMsg = result else {
                    print("Error: Got nil sent message")
                    self.failedToSendMessage(msg.body ?? "",
                                             date: msg.creationDate(),
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
                self.setRecordButton()
        }
        )
        
        self.messages.append(msg)
        self.collectionView?.reloadData()
        self.scrollToBottom(animated: true)
        self.finishSendingMessage(animated: true)
        self.skygear.chatExtension?.sendTypingIndicator(.finished, in: self.conversation!)
    }
}

// MARK: - Actions

extension SKYChatConversationViewController {
    open override func textViewDidChange(_ textView: UITextView) {
        super.textViewDidChange(textView)
        if textView.text.characters.count > 0 {
            self.setSendButton()
        } else {
            self.setRecordButton()
        }
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
        
        self.present(self.defaultAccessoryButtonAlertController(), animated: true, completion: nil)
    }

    open override func didPressSend(_ button: UIButton!,
                                    withMessageText text: String!,
                                    senderId: String!,
                                    senderDisplayName: String!,
                                    date: Date!) {
        let msg = SKYMessage()
        msg.body = text
        msg.setCreatorUserRecordID(self.senderId)
        msg.setCreationDate(date)
        self.sendMessage(msg)
    }
    
    open func didPressSendButton(button: UIButton) {
        self.inputToolbar?.delegate.messagesInputToolbar(self.inputToolbar, didPressRightBarButton: button)
    }

    open override func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        self.loadMoreMessage()
    }

    open override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let scrollViewHeight = scrollView.frame.size.height;
        let scrollContentSizeHeight = scrollView.contentSize.height;
        let scrollOffset = scrollView.contentOffset.y;

        if scrollOffset < self.offsetYToLoadMore {
            self.loadMoreMessage()
        }

        // should automaticallyScrollsToMostRecentMessage when reach bottom
        self.automaticallyScrollsToMostRecentMessage = scrollOffset >= scrollContentSizeHeight - scrollViewHeight
    }

    open func loadMoreMessage() {
        if !self.isFetchingMessage && self.hasMoreMessageToFetch {
            let firstMessage = self.messages[0]
            self.fetchMessages(before: firstMessage.creationDate())
        }
    }
}

// MARK: - Default accessory action handler

extension SKYChatConversationViewController {
    public func defaultPhotoPickerActionHandler() -> (UIAlertAction) -> Swift.Void {
        return { _ in
            let picker = CTAssetsPickerController()
            picker.delegate = self
            picker.assetsFetchOptions = PHFetchOptions()
            picker.assetsFetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
            self.present(picker, animated: true, completion: nil)
        }
    }
}

// MARK: - CTAssetsPickerControllerDelegate

extension SKYChatConversationViewController: CTAssetsPickerControllerDelegate {
    public func assetsPickerController(_ picker: CTAssetsPickerController!, didFinishPickingAssets assets: [Any]!) {
        for asset in assets {
            switch asset {
            case let a as PHAsset:
                self.send(asset: a)
            default:
                NSLog("Unknown asset type")
            }
        }
        picker.dismiss(animated: true, completion: nil)
    }
}


// MARK: - Send photos

extension SKYChatConversationViewController {
    func cleanup(asset: SKYAsset) {
        try? FileManager.default.removeItem(at: asset.url)
    }

    open func send(asset: PHAsset) {
        let manager = PHImageManager.default()
        let option = PHImageRequestOptions()
        option.resizeMode = .fast
        option.deliveryMode = .fastFormat
        manager.requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .default, options: option, resultHandler: {(result, info)->Void in
            if result != nil {
                self.send(image: result!)
            }
        })
    }

    open func send(image: UIImage) {
        let date = Date()

        guard let conv = self.conversation else {
            self.failedToSendMessage("",
                                     date: date,
                                     errorCode: SKYErrorInvalidArgument,
                                     errorMessage: "Cannot send message to nil conversation")
            return
        }

        let msg = SKYMessage(withImage: image)
        msg.setCreatorUserRecordID(self.senderId)
        msg.setCreationDate(date)

        self.delegate?.conversationViewController?(self, readyToSendMessage: msg)
        self.skygear.chatExtension?.addMessage(
            msg,
            to: conv,
            completion: { (result, error) in
                defer {
                    if let attachment = msg.attachment {
                        self.cleanup(asset: attachment)
                    }
                }

                guard error == nil else {
                    print("Failed to sent message: \(error!.localizedDescription)")
                    self.failedToSendMessage("",
                                             date: date,
                                             errorCode: SKYErrorBadResponse,
                                             errorMessage: error!.localizedDescription)
                    return
                }

                guard let sentMsg = result else {
                    print("Error: Got nil sent message")
                    self.failedToSendMessage("",
                                             date: date,
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
        self.collectionView?.reloadData()
        self.scrollToBottom(animated: true)
    }
}

// MARK: - Audio

extension SKYChatConversationViewController {
    func startRecord() {
        print("Start Recording")
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("recording.m4a")
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            
            if (self.audioRecorder == nil) {
                self.audioRecorder = try AVAudioRecorder(url: url, settings: settings)
                self.audioRecorder?.delegate = self
                self.audioRecorder?.stop()
                self.audioRecorder?.prepareToRecord()
            }
            
            self.audioRecorder?.record()
        } catch {
            //TODO: show dialog
            
        }
    }
    
    func didStartRecord(button: UIButton) {
        
        let recordingSession = AVAudioSession.sharedInstance()
        
        if recordingSession.recordPermission() == .granted {
            do {
                try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
                try recordingSession.setActive(true)
                self.inputTextView?.isHidden = true
                self.inputToolbar?.contentView?.leftBarButtonItem?.isHidden = true
                self.inputToolbar?.contentView?.addSubview(self.slideToCancelTextView!)
                self.cameraButton?.isHidden = true
                self.startRecord()
            } catch {
                print("Cannot start recording session.")
            }
        } else {
            recordingSession.requestRecordPermission() { allowed in }
        }
    }
    
    open func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        
        if !flag || self.isRecordingCancelled {
            print("Cancelled")
            self.setRecordButton()
            return
        }
        do{
            self.setRecordButton()
            let asset = SKYAsset(data: try Data(contentsOf: recorder.url))
            asset.mimeType = "audio/m4a"
            SKYContainer.default().publicCloudDatabase.uploadAsset(asset) { (asset, error) in
                if let err = error {
                    let alert = UIAlertController(title: "Unable to upload", message: err.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
                print("Uploaded")
                if let ast = asset {
                    NSLog(ast.url.absoluteString)
                }
                let msg = SKYMessage()
                msg.body = ""
                msg.metadata = ["length": Int(self.audioTime! * 1000)]
                msg.attachment = asset
                msg.setCreatorUserRecordID(self.senderId)
                msg.setCreationDate(Date())
                self.sendMessage(msg)
            }
        } catch {
            print("Unable to send audio")
        }
    }
    
    
    func didStopRecord(button: UIButton, cancelled: Bool = false) {
        let recordingSession = AVAudioSession.sharedInstance()
        if recordingSession.recordPermission() == .granted {
            print("Stop recording", cancelled)
            self.setSendButton()
            self.isRecordingCancelled = cancelled
            self.audioTime = self.audioRecorder?.currentTime
            self.audioRecorder?.stop()
            self.slideToCancelTextView?.removeFromSuperview()
            self.inputTextView?.isHidden = false
            self.inputToolbar?.contentView?.leftBarButtonItem?.isHidden = false
            do {
                
                try recordingSession.setActive(false)
            } catch {
                print("Failed to stop recording session.")
            }
        }
    }
}

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
                    let senderName = senderRecord.object(forKey: "username") as? String {

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

        self.indicator?.startAnimating()
        let chatExt = self.skygear.chatExtension
        self.isFetchingMessage = true

        self.delegate?.startFetchingMessages?(self)
        chatExt?.fetchMessages(
            conversation: self.conversation!,
            limit: Int(self.messagesFetchLimit),
            beforeTime: before,
                 order: nil,
            completion: { (result, error) in
                self.isFetchingMessage = false
                self.indicator?.stopAnimating()
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
                self.hasMoreMessageToFetch = msgs.count > 0

                self.delegate?.conversationViewController?(self, didFetchedMessages: msgs)

                self.finishReceivingMessage()
                self.scroll(to: IndexPath(row: msgs.count, section: 0), animated: false)
                self.collectionView.flashScrollIndicators()
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

// MARK: Resource

extension SKYChatConversationViewController {
    open func bundle() -> Bundle? {
        let podBundle = Bundle(for: SKYChatConversationViewController.self)
        let bundleUrl = podBundle.url(forResource: "SKYKitChatUI", withExtension:"bundle")
        let bundle = Bundle(url: bundleUrl!)
        return bundle
    }
}
