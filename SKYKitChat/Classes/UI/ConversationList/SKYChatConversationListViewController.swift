//
//  SKYChatConversationListViewController.swift
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

import SVProgressHUD

@objc public protocol SKYChatConversationListViewControllerDataSource: class {
    /**
     * Return the avatar image for a conversation. Returning nil will remove the avatar image view
     * when displaying the conversation.
     **/
    @objc optional func listViewController(_ controller: SKYChatConversationListViewController,
                                           avatarImageForConversation conversation: SKYConversation,
                                           atIndexPath indexPath: IndexPath) -> UIImage?
}

@objc public protocol SKYChatConversationListViewControllerDelegate: class {
    /**
     * Notify the delegate which conversation is selected.
     **/
    @objc optional func listViewController(_ controller: SKYChatConversationListViewController,
                                           didSelectConversation conversation: SKYConversation)
}

open class SKYChatConversationListViewController: UIViewController {

    public var skygear: SKYContainer = SKYContainer.default()
    public weak var delegate: SKYChatConversationListViewControllerDelegate?
    public weak var dataSource: SKYChatConversationListViewControllerDataSource?

    @IBOutlet public var tableView: UITableView!

    var refreshControl: UIRefreshControl!
    var conversations: [SKYConversation] = []
    var users: [String: SKYRecord] = [:]
    var conversationChangeObserver: Any?
}

// MARK: - Initializing

extension SKYChatConversationListViewController {

    public class var nib: UINib {
        return  UINib(nibName: "SKYChatConversationListViewController",
                      bundle: Bundle(for: SKYChatConversationListViewController.self))
    }

    public class func create() -> SKYChatConversationListViewController {
        return SKYChatConversationListViewController(nibName: "SKYChatConversationListViewController",
                                                     bundle: Bundle(for: SKYChatConversationListViewController.self))
    }
}

// MARK: - Lifecycle

extension SKYChatConversationListViewController {

    open override func viewDidLoad() {
        super.viewDidLoad()

        SKYChatConversationListViewController.nib.instantiate(withOwner: self, options: nil)

        self.tableView.register(SKYChatConversationTableViewCell.nib,
                                forCellReuseIdentifier: "ConversationCell")
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl?.addTarget(self, action: #selector(handleRefresh), for: UIControlEvents.valueChanged)
        self.tableView.addSubview(refreshControl)
        self.refreshControl.beginRefreshing()
        self.handleRefresh(refreshControl: self.refreshControl)
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard self.skygear.chatExtension != nil else {
            print("Missing chat extension in Skygear container")
            self.dismiss(animated: animated)
            return
        }

        if let _ = self.navigationController {
            self.edgesForExtendedLayout = [.left, .right, .bottom]
        }
        self.subscribeConversationChanges()
    }

    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        self.unsubscribeConversationChanges()
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

    public func handleRefresh(refreshControl: UIRefreshControl) {
        self.performQuery(callback: {
            refreshControl.endRefreshing()
        })
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension SKYChatConversationListViewController: UITableViewDelegate, UITableViewDataSource {

    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }

    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let conversation = self.conversations[indexPath.row]
        if let cell = tableView.dequeueReusableCell(withIdentifier: "ConversationCell")
            as? SKYChatConversationTableViewCell {

            cell.conversation = conversation
            cell.conversationMessage = conversation.lastMessage?.body
            cell.unreadMessageCount = conversation.unreadCount
            cell.participants = []

            // add all participant records for display
            conversation.participantIds.forEach({ (eachParticipantID) in
                guard eachParticipantID != self.skygear.auth.currentUserRecordID! else {
                    // no need to show current user's name
                    return
                }

                if let eachParticipant = self.users[eachParticipantID] {
                    cell.participants.append(eachParticipant)
                }
            })

            if let ds = self.dataSource {
                cell.avatarImage = ds.listViewController?(self,
                                                          avatarImageForConversation: conversation,
                                                          atIndexPath: indexPath)
            } else {
                let title = conversation.title ?? ""
                cell.avatarImage = UIImage.avatarImage(forInitialsOfName: title)
            }

            return cell
        } else {
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            if let title = conversation.title {
                cell.textLabel?.text = title
                cell.textLabel?.textColor = UIColor.black
            } else {
                cell.textLabel?.text = NSLocalizedString("Untitled", comment: "")
                cell.textLabel?.textColor = UIColor.lightGray
            }

            return cell
        }
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(75)
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let d = self.delegate {
            let conv = self.conversations[indexPath.row]
            d.listViewController?(self,
                                  didSelectConversation: conv)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - Utility Methods

extension SKYChatConversationListViewController {

    public func getUsers() -> [String: SKYRecord] {
        return self.users
    }

    public func getUser(byUserID userID: String) -> SKYRecord? {
        return self.users[userID]
    }

    public func getConversations() -> [SKYConversation] {
        return self.conversations
    }

    open func performQuery(callback: (() -> Void)?) {
        self.skygear.chatExtension?.fetchConversations(fetchLastMessage: true, completion: {
            (conversations, error) in
            callback?()
            if let err = error {
                self.handleQueryError(error: err)
                return
            }

            if let conversations = conversations {
                self.handleQueryResult(result: conversations)
            } else {
                let err = SKYErrorCreator()
                    .error(with: SKYErrorBadResponse,
                           message: "Query does not response Conversation")
                self.handleQueryError(error: err)
            }
        })
    }

    open func performUserQuery(byIDs userIDs: [String]) {
        let predicate = NSPredicate(format: "_id IN %@", userIDs)
        let query = SKYQuery(recordType: "user", predicate: predicate)

        self.skygear.publicCloudDatabase.perform(query) { (result, error) in
            guard error == nil else {
                self.handleUserQueryError(error: error!)
                return
            }

            guard let users = result as? [SKYRecord] else {
                let err = SKYErrorCreator()
                    .error(with: SKYErrorBadResponse,
                           message: NSLocalizedString("Cannot get any users", comment: ""))
                self.handleUserQueryError(error: err)
                return
            }

            self.handleUserQueryResult(result: users)
        }
    }

    open func handleQueryResult(result: [SKYConversation]) {
        self.conversations = result
        self.tableView.reloadData()

        let currentCachedUserKeys = self.users.keys
        let userIDs = result
            .reduce(Set([])) { return $0.union(Set($1.participantIds))}
            .filter { !currentCachedUserKeys.contains($0) }

        if userIDs.count > 0 {
            self.performUserQuery(byIDs: userIDs)
        }
    }

    open func handleQueryError(error: Error) {
        SVProgressHUD.showError(withStatus: error.localizedDescription)
    }

    open func handleUserQueryResult(result: [SKYRecord]) {
        result.forEach { (eachUser) in
            let eachUserID = eachUser.recordID.recordName
            self.users[eachUserID] = eachUser
        }

        self.tableView.reloadData()
    }

    open func handleUserQueryError(error: Error) {
        SVProgressHUD.showError(withStatus: error.localizedDescription)
    }

    open func subscribeConversationChanges() {

        self.unsubscribeConversationChanges()

        let handler: ((SKYChatRecordChangeEvent, SKYConversation) -> Void) = {(event, msg) in
            switch event {
            case .create:
                NSLog("Conversation create")
            case .update:
                NSLog("Conversation update")
            case .delete:
                NSLog("Conversation delete")
            }
            self.performQuery(callback: nil)

        }

        self.conversationChangeObserver = self.skygear.chatExtension?
            .subscribeToConversation(handler: handler)

    }

    open func unsubscribeConversationChanges() {
        if let observer = self.conversationChangeObserver {
            self.skygear.chatExtension?.unsubscribeToConversation(withObserver: observer)
            self.conversationChangeObserver = nil
        }
    }
}
