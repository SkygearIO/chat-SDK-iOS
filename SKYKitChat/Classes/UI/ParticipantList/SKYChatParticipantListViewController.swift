//
//  SKYChatParticipantListViewController.swift
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

public enum SKYChatParticipantQueryMethod: UInt {
    // By username of the user, supposed to be unique
    case ByUsername

    // By email of the user, supposed to be unique
    case ByEmail

    // By name of the user, can limit the searching scope by setting participantScope
    case ByName
}

@objc public protocol SKYChatParticipantListViewControllerDelegate: class {
    @objc optional func listViewController(_ controller: SKYChatParticipantListViewController,
                                           didSelectParticipant participant: SKYRecord)
}

open class SKYChatParticipantListViewController: UIViewController {

    static let queryMethodCoderKey = "QUERY_METHOD"

    public var skygear: SKYContainer = SKYContainer.default()

    /*
      The method users are being search.
     */
    public var queryMethod: SKYChatParticipantQueryMethod = .ByUsername {
        didSet {
            self.searchBar.keyboardType = .default

            switch self.queryMethod {
            case .ByEmail:
                self.searchBar.placeholder = "Search for user email"
                self.searchBar.keyboardType = .emailAddress
            case .ByUsername:
                self.searchBar.placeholder = "Search for username"
            case .ByName:
                self.searchBar.placeholder = "Search for name of user"
            default:
                self.searchBar.placeholder = nil
            }
        }
    }

    /*
      The participant searching scope. (Only available when queryMethod is set to `.ByName`)
     */
    public var participantScope: SKYQuery?

    public var delegate: SKYChatParticipantListViewControllerDelegate?
    internal(set) public var searchTerm: String?

    @IBOutlet public var searchBar: UISearchBar!
    @IBOutlet public var tableView: UITableView!

    var participants: [SKYRecord] = []

}

// MARK: - Initializing

extension SKYChatParticipantListViewController {

    public class var nib: UINib {
        return UINib(nibName: "SKYChatParticipantListViewController",
                     bundle: Bundle(for: SKYChatParticipantListViewController.self))
    }

    public class func create() -> SKYChatParticipantListViewController {
        return SKYChatParticipantListViewController(nibName: "SKYChatParticipantListViewController",
                                                    bundle: Bundle(for: SKYChatParticipantListViewController.self))
    }
}

// MARK: - Lifecycle

extension SKYChatParticipantListViewController {

    open override func viewDidLoad() {
        super.viewDidLoad()

        SKYChatParticipantListViewController.nib.instantiate(withOwner: self, options: nil)

        self.searchBar.autocapitalizationType = .none
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard self.participantScope == nil || self.participantScope?.recordType == "user" else {
            print("Participant Scope should only for user records")
            self.dismiss(animated: animated)
            return
        }

        if let _ = self.navigationController {
            self.edgesForExtendedLayout = [.left, .right, .bottom]
        }

        if self.queryMethod == .ByName {
            // show all users under the scope
            self.performUserQuery()
        }

        self.searchBar.becomeFirstResponder()

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


// MARK: - UITableViewDelegate, UITableViewDataSource

extension SKYChatParticipantListViewController: UITableViewDelegate, UITableViewDataSource {

    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.participants.count
    }

    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        let user = self.participants[indexPath.row]

        cell.textLabel?.text = nil
        switch self.queryMethod {
        case .ByEmail:
            if let email = user.transient.object(forKey: "_email") as? String {
                cell.textLabel?.text = email
            }
        case .ByUsername:
            if let username = user.transient.object(forKey: "_username") as? String {
                cell.textLabel?.text = username
            }
        case .ByName:
            if let name = user.object(forKey: "name") as? String {
                cell.textLabel?.text = name
            }
        default:
            break
        }

        return cell
    }

    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let d = self.delegate {
            let participant = self.participants[indexPath.row]
            d.listViewController?(self, didSelectParticipant: participant)
        }
    }

}

// MARK: - UISearchBarDelegate

extension SKYChatParticipantListViewController: UISearchBarDelegate {

    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let text = searchBar.text {
            if text.characters.count > 0 {
                self.searchTerm = text
            } else {
                self.searchTerm = nil
            }
        } else {
            self.searchTerm = nil
        }

        self.performUserQuery()
    }

    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.searchTerm = nil

    }
}

// MARK: - Utility Methods

extension SKYChatParticipantListViewController {

    open func getParticipants() -> [SKYRecord] {
        return self.participants
    }

    var queryPredicate: NSPredicate? {
        switch self.queryMethod {
        case .ByEmail:
            if let term = self.searchTerm {
                return SKYUserDiscoverPredicate(emails: [term])
            } else {
                print("Cannot search for an empty email")
                return nil
            }

        case .ByUsername:
            if let term = self.searchTerm {
                return SKYUserDiscoverPredicate(usernames: [term])
            } else {
                print("Cannot search for an empty email")
                return nil
            }

        case .ByName:
            var predicate: NSPredicate
            if let term = self.searchTerm {
                predicate = NSPredicate(format: "name LIKE[c] %@", argumentArray: ["*\(term)*"])
            } else {
                predicate = NSPredicate(format: "name != nil")
            }

            if let scope = self.participantScope {
                predicate = NSCompoundPredicate(
                    andPredicateWithSubpredicates: [predicate, scope.predicate])
            }

            return predicate

        default:
            return nil
        }
    }

    open func performUserQuery() {
        let predicate = self.queryPredicate

        guard predicate != nil else {
            self.participants = []
            self.tableView.reloadData()
            return
        }

        let query = SKYQuery(recordType: "user", predicate: self.queryPredicate)

        SVProgressHUD.show()
        self.skygear.publicCloudDatabase.perform(query, completionHandler: { (result, error) in
            SVProgressHUD.dismiss()
            if let err = error {
                self.handleQueryError(error: err)
                return
            }

            if let r = result as? [SKYRecord] {
                self.handleQueryResult(result: r)
            } else {
                let err = SKYErrorCreator().error(with: SKYErrorBadResponse,
                                                  message: "Query does not response SKYRecord")
                self.handleQueryError(error: err!)
            }
        })
    }

    open func handleQueryResult(result: [SKYRecord]) {
        self.participants = result
        self.tableView.reloadData()
    }

    open func handleQueryError(error: Error) {
        SVProgressHUD.showError(withStatus: error.localizedDescription)
    }
}
