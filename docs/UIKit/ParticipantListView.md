## Participant List View
==========================

Participant List View is a common UI for chat apps to query users.

You can specify how the user is being queried by setting the query method
before the Participant List View is shown. Currently, only 3 types of queries
are supported:

- By Username (the `username` when user sign up)
- By Email (the `email` when user sign up)
- By Name (the `name` field of user record)

And user query by username is set by default.

Since email and username are private information of the user, a user will only
be found when the email or username is exactly matched.

For querying by name, a user will be found when his name is partially matched
the query string. Also, a scope can be specified to limit the users being
queried.

The following snippet shows how to specified the query method and provide an
extra query scope:

```swift
class UserQueryViewController: SKYChatParticipantListViewController {

  override func viewDidLoad() {
      super.viewDidLoad()

      self.queryMethod = .ByName

      // exclude the current user being query
      if let userID = self.skygear.currentUser?.userID {
          self.participantScope = SKYQuery(recordType: "user",
                                           predicate: NSPredicate(format: "_id != %@", userID))
      }
  }
}
```

To provide the avatars of the users being found, you can implement the
following method of `SKYChatParticipantListViewControllerDataSource`:

- `listViewController(_:avatarImageForParticipant:atIndexPath:)`

Moreover, by implementing the following method of
`SKYChatParticipantListViewControllerDelegate`, you will be notified when a
user is selected in Participant List View:

- `listViewController(_:didSelectParticipant:)`
