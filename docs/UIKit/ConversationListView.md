## Conversation List View
==========================

Conversation List View helps to fetch conversations which the user is
attending.

You can create your View Controller and extending the Conversation List View
and directly set it as the `Custom Class` in your storyboard.

```swift
import SKYKitChat

class ConversationListDemoViewController: SKYChatConversationListViewController {

}
```

To customize the Conversation List View, you can override some of its methods:

- `performQuery()`
- `performUserQuery(byIDs:)`
- `handleQueryResult(result:)`
- `handleQueryError(error:)`
- `handleUserQueryResult(result:)`
- `handleUserQueryError(error:)`

Besides overriding the methods, you can also implement the Data Source to
provide extra data for displaying a conversation.

You may provide the avatar of the conversation as followed:

```swift
class ConversationListDemoViewController: SKYChatConversationListViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        self.dataSource = self
    }
}

extension ConversationListDemoViewController: SKYChatConversationListViewControllerDataSource {
    func listViewController(_ controller: SKYChatConversationListViewController,
                            avatarImageForConversation conversation: SKYConversation,
                            atIndexPath indexPath: IndexPath) -> UIImage?
    {
        // implement a store for conversation store
        var image = AvatarStore.shared.avatar(forConversation: conversation)
        if image == nil {
            image = /* fetch the image */
            AvatarStore.shared.cache(avatar: image, forConversation: conversation)
        }

        return image
    }
}
```

To customize the action for selecting a conversation in Conversation List View,
you can implement the delegate of it.

```swift
class ConversationListDemoViewController: SKYChatConversationListViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        self.delegate = self
    }
}

extension ConversationListDemoViewController: SKYChatConversationListViewControllerDelegate {
    func listViewController(_ controller: SKYChatConversationListViewController,
                            didSelectConversation conversation: SKYConversation)
    {
        self.selectedConversation = conversation

        // show the conversation
        self.performSegue(withIdentifier: "ShowConversation", sender: self)
    }
}
```
