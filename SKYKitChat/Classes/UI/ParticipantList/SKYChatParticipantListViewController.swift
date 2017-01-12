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

public enum SKYChatParticipantQueryMethod: UInt {
    case Undefined
    case ByUsername
    case ByEmail
    case Custom
}

open class SKYChatParticipantListViewController: UIViewController {

    static let queryMethodCoderKey = "QUERY_METHOD"

    public var skygear: SKYContainer?
    public var queryMethod: SKYChatParticipantQueryMethod = .Undefined
    public var participantScope: SKYQuery?

    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var tableView: UITableView!

    var participants: [SKYRecord] = []

    // MARK: - Initializer

    public init(queryMethod: SKYChatParticipantQueryMethod) {
        super.init(nibName: "SKYChatParticipantListViewController",
                   bundle: Bundle(for: SKYChatParticipantListViewController.self))
        self.queryMethod = queryMethod
    }

    // MARK: - NSCoding Protocol

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        if let queryMethod = aDecoder.decodeObject(forKey: SKYChatParticipantListViewController.queryMethodCoderKey)
            as? SKYChatParticipantQueryMethod
        {
            self.queryMethod = queryMethod
        }

        let nib = UINib(nibName: "SKYChatParticipantListViewController",
                        bundle: Bundle(for: SKYChatParticipantListViewController.self))
        nib.instantiate(withOwner: self, options: nil)
    }

    open override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(self.queryMethod,
                      forKey: SKYChatParticipantListViewController.queryMethodCoderKey)
    }

}

// MARK: - Lifecycle

extension SKYChatParticipantListViewController {

    open override func viewDidLoad() {
        super.viewDidLoad()

        self.searchBar.autocapitalizationType = .none
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard self.skygear != nil else {
            print("Missing required settings: skygear")

            return
        }

        guard self.queryMethod != .Undefined else {
            print("Missing required settings: queryMethod")

            return
        }

        guard self.queryMethod != .Custom || self.participantScope != nil else {
            print("Missing required settings: participantScope")

            return
        }

        if let nc = self.navigationController {
            self.edgesForExtendedLayout = [.left, .right, .bottom]
        }

//        self.performUserQuery()
    }

}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension SKYChatParticipantListViewController: UITableViewDelegate, UITableViewDataSource {

    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.participants.count
    }

    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // TODO: dequeue reused cell
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.text = "\(indexPath.row)"

        return cell
    }

}

// MARK: - Utility Methods

extension SKYChatParticipantListViewController {

    open func getParticipants() -> [SKYRecord] {
        return self.participants
    }


//    open func performUserQuery() {
//        // TODO: perform query
//    }

}
