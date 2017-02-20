## Conversation View
======================

Conversation View fetches messages for a specific conversation and provide UI
to send messages to the conversation.

You can create your View Controller and extending the Conversation List View
and directly set it as the `Custom Class` in your storyboard.

```swift
import SKYKitChat

class ConversationDemoViewController: SKYChatConversationViewController {

}
```

To customize the Conversation View, you can override some of its methods:

- `customizeViews()`
- `updateTitle()`
- `displayTypingIndicator()`
- `hideTypingIndicator()`
- `failedToSendMessage(_:date:errorCode:errorMessage:)`
- `subscribeMessageChanges()`
- `unsubscribeMessageChanges()`
- `subscribeTypingIndicatorChanges()`
- `unsubscribeTypingIndicatorChanges()`
- `fetchParticipants()`
- `fetchMessages(before:)`
- `getSender(forMessage:) -> SKYRecord?`

Besides overriding the methods, you can also implement the Delegate to
customize the Conversation View.

To set the color of the message bubble (both incoming or outgoing), you may
implement the following methods from
`SKYChatConversationViewControllerDelegate`:

- `incomingMessageColorForConversationViewController(_:)`
- `outgoingMessageColorForConversationViewController(_:)`

Also, you may also implement the following methods to control whether the
accessory button (the button on the left of the message input) should show and
the behavior of it:

- `accessoryButtonShouldShowInConversationViewController(_:)`
- `conversationViewController(_:alertControllerForAccessoryButton:)`

The following snippet gives an example how to customize the Conversation View
by implementing its delegate:

```swift
class ConversationDemoViewController: SKYChatConversationViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.delegate = self
    }
}

extension ConversationDemoViewController: SKYChatConversationViewControllerDelegate {
    func incomingMessageColorForConversationViewController(
        _ controller: SKYChatConversationViewController) -> UIColor
    {
        return UIColor.lightGray
    }

    func accessoryButtonShouldShowInConversationViewController(
        _ controller: SKYChatConversationViewController) -> Bool
    {
        return true
    }

    func conversationViewController(
        _ controller: SKYChatConversationViewController,
        alertControllerForAccessoryButton button: UIButton) -> UIAlertController
    {
        let alert = UIAlertController(title: "Accessory Button Action",
                                      message: nil,
                                      preferredStyle: .actionSheet)

        alert.addAction(
            UIAlertAction(title: "Info.", style: .default, handler: { _ in
                let newAlert =
                    UIAlertController(title: "Info.",
                                      message: "Custom action can be added to the Accessory Button",
                                      preferredStyle: .alert)
                newAlert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
                self.present(newAlert, animated: true, completion: nil)
            })
        )

        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))

        return alert
    }
}
```

Besides customizing the Conversation View, you can also get notified of some
events by implementing the corresponding methods in the delegate:

- `conversationViewController(_:readyToSendMessage:)`
- `conversationViewController(_:finishSendingMessage:)`
- `conversationViewController(_:failedToSendMessageText:date:error:)`
- `conversationViewController(_:didFetchedParticipants:)`
- `conversationViewController(_:failedFetchingParticipantWithError:)`
- `conversationViewController(_:didFetchedMessages:)`
- `conversationViewController(_:failedFetchingMessagesWithError:)`

Since SKYChatConversationViewController extends the JSQMessagesViewController,
you may refer to
[JSQMessagesViewController](https://github.com/jessesquires/JSQMessagesViewController)
for more customization on it.
