# Documentation of UIKit for Skygear Chat
=========================

The UIKit for Skygear Chat plugin is consist of 3 UI components which developers can
directly use to build a common chat UI:

- [Participant List View](https://github.com/SkygearIO/chat-SDK-iOS/blob/master/docs/UIKit/ParticipantListView.md)
- [Conversation List View](https://github.com/SkygearIO/chat-SDK-iOS/blob/master/docs/UIKit/ConversationListView.md)
- [Conversation View](https://github.com/SkygearIO/chat-SDK-iOS/blob/master/docs/UIKit/ConversationView.md)

Please note that the `name` field of the `user` record will be used for
displaying user name. The following snippet is an example for how to save the name of the user
to the `user` record:

```swift
let skygear = SKYContainer.default()
skygear.signup(withUsername: username, password: password) { (user, error) in
    guard error == nil else {
        // TODO: error handling
        return
    }

    // query the corresponding user record
    let userQuery = SKYQuery(recordType: "user",
                             predicate: NSPredicate(format: "_id = %@",
                                                    argumentArray:[user.userID!]))
    skygear.publicCloudDatabase.perform(
        userQuery, completionHandler: { (results, queryError) in
            guard queryError == nil else {
                // TODO: error handling
                return
            }

            if let userRecords = results as? [SKYRecord] {
                guard userRecords.count > 0 else {
                    // TODO: error handling
                    print("Cannot get any user records")
                    return
                }

                // Set the username to the name field
                let theUser = userRecords[0]
                theUser.setValue(user.username, forKey: "name")
                skygear.publicCloudDatabase.save(theUser, completion: { (savedRecord, saveError) in
                    guard saveError == nil else {
                        // TODO: error handling
                        return
                    }

                    print("Name of the user record updated.")
                })
            }
    })
}
```
