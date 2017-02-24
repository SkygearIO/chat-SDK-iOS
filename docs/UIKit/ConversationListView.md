## Conversation List View
==========================

Conversation List View displays a list of conversations in which the user is
participanting.

You can customize the Conversation List View by creating your own view
controller that extends the Conversation List View. Make sure you set your own
view controller as the `Custom Class` in your storyboard.

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

Besides overriding these methods, you can also implement some methods
of SKYChatConversationListViewControllerDataSource to
provide extra data for displaying a conversation.

For example, you may provide custom avatar of the conversation as followed:

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
        // implement a store for storing conversation data
        return AvatarStore.shared.avatar(forConversation: conversation)
    }
}
```

To customize the action when user selects a conversation in Conversation List View,
you can implement a SKYChatConversationListViewControllerDelegate method.

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
