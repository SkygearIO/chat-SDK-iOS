//
//  SKYChatExtension.h
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

#import <SKYKit/SKYKit.h>

#import "SKYChatReceipt.h"
#import "SKYChatRecordChange.h"
#import "SKYChatTypingIndicator.h"

/**
 When obtaining a dictionary containing unread count information, use this
 key to get the number of unread messages.
 */
extern NSString *_Nonnull const SKYChatMessageUnreadCountKey;

/**
 When obtaining a dictionary containing unread count information, use this
 key to get the number of unread conversations.
 */
extern NSString *_Nonnull const SKYChatConversationUnreadCountKey;

/**
 This notification is posted when the client receives an event for typing indicator.
 */
extern NSString *_Nonnull const SKYChatDidReceiveTypingIndicatorNotification;

/**
 This notification is posted when the client receives an event for record change.
 */
extern NSString *_Nonnull const SKYChatDidReceiveRecordChangeNotification;

/**
 For the SKYChatDidReceiveTypingIndicatorNotification, this user info key
 can be used to get an object of SKYChatTypingIndicator.
 */
extern NSString *_Nonnull const SKYChatTypingIndicatorUserInfoKey;

/**
 For the SKYChatDidReceiveRecordChangeNotification, this user info key
 can be used to get an object of SKYChatRecordChange.
 */
extern NSString *_Nonnull const SKYChatRecordChangeUserInfoKey;

@class SKYConversation, SKYMessage, SKYUserChannel, SKYUserConversation;

/**
 SKYChatExtension is a simple object that expose easy to use helper methods to develop a chat
 app.

 Most of the functions provide by the chat plugin is available through this extension object.

 The extension requires a SKYContainer to function. For most app developer, you should obtain
 a SKYChatExtension through the `-[SKYContainer chatExtension]` category method.
 */
@interface SKYChatExtension : NSObject

typedef void (^SKYChatUserConversationCompletion)(SKYUserConversation *_Nullable conversation,
                                                  NSError *_Nullable error);
typedef void (^SKYChatMessageCompletion)(SKYMessage *_Nullable message, NSError *_Nullable error);
typedef void (^SKYChatUnreadCountCompletion)(
    NSDictionary<NSString *, NSNumber *> *_Nullable response, NSError *_Nullable error);
typedef void (^SKYChatChannelCompletion)(SKYUserChannel *_Nullable userChannel,
                                         NSError *_Nullable error);
typedef void (^SKYChatFetchUserConversationListCompletion)(
    NSArray<SKYUserConversation *> *_Nullable conversationList, NSError *_Nullable error);
typedef void (^SKYChatFetchMessagesListCompletion)(NSArray<SKYMessage *> *_Nullable messageList,
                                                   NSError *_Nullable error);
typedef void (^SKYChatConversationCompletion)(SKYConversation *_Nullable conversation,
                                              NSError *_Nullable error);

/**
 Gets or sets whether messages fetched from server are automatically marked as delivered.

 When this is true, the chat extension will automatically send delivery receipt to the
 server when a message is fetched from the server.

 This is enabled by default.
 */
@property (assign, nonatomic) bool automaticallyMarkMessagesAsDelivered;

/**
 Gets or sets user channel message handler.

 The user channel message handler is a low-level interface for getting messages from the user
 channel.
 For most apps, get messages from user channel with notifications posted by chat extension.
 */
@property (nonatomic, copy, nullable) void (^userChannelMessageHandler)
    (NSDictionary<NSString *, id> *_Nonnull);

///------------------------------------------
/// @name Creating and fetching conversations
///------------------------------------------

/**
 Creates a conversation with the selected participants.

 All participants will also become the admins of the created conversation. The conversation
 will not be distinct by participants by default.

 If participants list do not include the current user, the current user will be added to the
 list as well. The same apply for admins list.

 @param participantIDs an array of all participants in the conversation
 @param title title of the conversation
 @param metadata application metadata for the conversation
 @param completion completion block
 */
- (void)createConversationWithParticipantIDs:(NSArray<NSString *> *_Nonnull)participantIDs
                                       title:(NSString *_Nullable)title
                                    metadata:(NSDictionary<NSString *, id> *_Nullable)metadata
                                  completion:(SKYChatUserConversationCompletion _Nullable)completion
    /* clang-format off */ NS_SWIFT_NAME(createConversation(participantIDs:title:metadata:completion:)); /* clang-format on */

/**
 Creates a conversation with the selected participants.

 If participants list do not include the current user, the current user will be added to the
 list as well. The same apply for admins list. If the admins list is not specified, the admins
 list will be the same as the participants list.

 If distinctByParticipants is set to YES, the chat extension will attempt to find an existing
 conversation with the same list of participants before creating a new one.

 @param participantIDs an array of all participants in the conversation
 @param title title of the conversation
 @param metadata application metadata for the conversation
 @param adminIDs an array of all participants that can administrate the conversation
 @param completion completion block
 */

- (void)createConversationWithParticipantIDs:(NSArray<NSString *> *_Nonnull)participantIDs
                                       title:(NSString *_Nullable)title
                                    metadata:(NSDictionary<NSString *, id> *_Nullable)metadata
                                    adminIDs:(NSArray<NSString *> *_Nullable)adminIDs
                      distinctByParticipants:(BOOL)distinctByParticipants
                                  completion:(SKYChatUserConversationCompletion _Nullable)completion
    /* clang-format off */ NS_SWIFT_NAME(createConversation(participantIDs:title:metadata:adminIDs:distinctByParticipants:completion:)); /* clang-format on */

/**
 Creates a direct conversation with a specific user.

 The current user and the specified user will be in the participants list and admins list.

 The new conversation will have distinctByParticipants set to YES. This allows the application
 to reuse an exisitng direct conversation.

 @param userID the ID of the other user in the direct conversation
 @param title title of the conversation
 @param metadata application metadata for the conversation
 @param completion completion block
 */
- (void)createDirectConversationWithUserID:(NSString *_Nonnull)userID
                                     title:(NSString *_Nullable)title
                                  metadata:(NSDictionary<NSString *, id> *_Nullable)metadata
                                completion:(SKYChatUserConversationCompletion _Nullable)completion
    /* clang-format off */ NS_SWIFT_NAME(createDirectConversation(userID:title:metadata:completion:)); /* clang-format on */

/**
 Saves a conversation.

 This method can be used to save a new conversation or update an existing conversation. This
 method does not reuse an existing conversation even if distinctByParticipants is set to YES.

 To create or reuse a conversation, call createConversation... instead.

 @param conversationID the ID of the conversation to be deleted
 @param completion completion block
 */
- (void)saveConversation:(SKYConversation *_Nonnull)conversation
              completion:(SKYChatConversationCompletion _Nullable)completion
    /* clang-format off */ NS_SWIFT_NAME(saveConversation(_:completion:)); /* clang-format on */

/**
 Fetches user conversations.

 @param completion completion block
 */
- (void)fetchUserConversationsWithCompletion:
    (SKYChatFetchUserConversationListCompletion _Nullable)completion
    /* clang-format off */ NS_SWIFT_NAME(fetchUserConversations(completion:)); /* clang-format on */

/**
 Fetches user conversations with optional last message in conversation.

 @param fetchLastMessage whether to fetch the last message
 @param completion completion block
 */
- (void)fetchUserConversationsWithFetchLastMessage:(BOOL)fetchLastMessage
                                        completion:
                                            (SKYChatFetchUserConversationListCompletion _Nullable)
                                                completion
    /* clang-format off */ NS_SWIFT_NAME(fetchUserConversations(fetchLastMessage:completion:)); /* clang-format on */

/**
 Fetches a user conversation by conversation ID.

 @param conversationID ID of conversation
 @param fetchLastMessage whether to fetch the last message
 @param completion completion block
 */
- (void)fetchUserConversationWithConversationID:(NSString *_Nonnull)conversationID
                               fetchLastMessage:(BOOL)fetchLastMessage
                                     completion:
                                         (SKYChatUserConversationCompletion _Nullable)completion
    /* clang-format off */ NS_SWIFT_NAME(fetchUserConversation(conversationID:fetchLastMessage:completion:)); /* clang-format on */

/**
 Fetches a user conversation by conversation.

 @param conversation conversation object
 @param fetchLastMessage whether to fetch the last message
 @param completion completion block
 */
- (void)fetchUserConversationWithConversation:(SKYConversation *_Nonnull)conversation
                             fetchLastMessage:(BOOL)fetchLastMessage
                                   completion:
                                       (SKYChatUserConversationCompletion _Nullable)completion
    /* clang-format off */ NS_SWIFT_NAME(fetchUserConversation(conversation:fetchLastMessage:completion:)); /* clang-format on */

///---------------------------------------
/// @name Adding and removing participants
///---------------------------------------

/**
 Adds participants to a conversation.

 The specified user IDs are added to the conversation record as participants. The modified
 conversation will be saved to the server.

 @param userIDs array of participant user ID
 @param conversation conversation record
 @param completion completion block
 */
- (void)addParticipantsWithUserIDs:(NSArray<NSString *> *_Nonnull)userIDs
                    toConversation:(SKYConversation *_Nonnull)conversation
                        completion:(SKYChatConversationCompletion _Nullable)completion
    /* clang-format off */ NS_SWIFT_NAME(addParticipants(userIDs:to:completion:)); /* clang-format on */

/**
 Removes participants from a conversation.

 The specified user IDs are removed from the conversation record as participants. The modified
 conversation will be saved to the server.

 @param userIDs array of participant user ID
 @param conversation conversation record
 @param completion completion block
 */
- (void)removeParticipantsWithUserIDs:(NSArray<NSString *> *_Nonnull)userIDs
                     fromConversation:(SKYConversation *_Nonnull)conversation
                           completion:(SKYChatConversationCompletion _Nullable)completion
    /* clang-format off */ NS_SWIFT_NAME(removeParticipants(userIDs:from:completion:)); /* clang-format on */

/**
 Adds admins to a conversation.

 The specified user IDs are added to the conversation record as admins. The modified
 conversation will be saved to the server.

 @param userIDs array of admin user ID
 @param conversation conversation record
 @param completion completion block
 */
- (void)addAdminsWithUserIDs:(NSArray<NSString *> *_Nonnull)userIDs
              toConversation:(SKYConversation *_Nonnull)conversation
                  completion:(SKYChatConversationCompletion _Nullable)completion
    /* clang-format off */ NS_SWIFT_NAME(addAdmins(userIDs:to:completion:)); /* clang-format on */

/**
 Removes admins to a conversation.

 The specified user IDs are removed from the conversation record as admins. The modified
 conversation will be saved to the server.

 @param userIDs array of admin user ID
 @param conversation conversation record
 @param completion completion block
 */
- (void)removeAdminsWithUserIDs:(NSArray<NSString *> *_Nonnull)userIDs
               fromConversation:(SKYConversation *_Nonnull)conversation
                     completion:(SKYChatConversationCompletion _Nullable)completion
    /* clang-format off */ NS_SWIFT_NAME(removeAdmins(userIDs:from:completion:)); /* clang-format on */

/**
 Remove the current user from the specified conversation.

 This method should be called when the current user wants to leave a conversation. Since modifying
 the participant list is only allowed if the user is an admin, calling
 -removeParticipantsWithUserIDs:fromConversation:completion: does not work.
 */
- (void)leaveConversation:(SKYConversation *_Nonnull)conversation
               completion:(void (^_Nullable)(NSError *_Nullable error))completion;

/**
 Remove the current user from the specified conversation by ID.

 This method should be called when the current user wants to leave a conversation. Since modifying
 the participant list is only allowed if the user is an admin, calling
 -removeParticipantsWithUserIDs:fromConversation:completion: does not work.
 */
- (void)leaveConversationWithConversationID:(NSString *_Nonnull)conversationID
                                 completion:(void (^_Nullable)(NSError *_Nullable error))completion
    /* clang-format off */ NS_SWIFT_NAME(leave(conversationID:completion:)); /* clang-format on */

///------------------------
/// @name Creating messages
///------------------------

/**
 Creates a message in the specified conversation.

 @param conversation conversation object
 @param body message body
 @param metadata application metadata for the conversation
 @param completion completion block
 */
- (void)createMessageWithConversation:(SKYConversation *_Nonnull)conversation
                                 body:(NSString *_Nullable)body
                             metadata:(NSDictionary<NSString *, id> *_Nullable)metadata
                           completion:(SKYChatMessageCompletion _Nullable)completion
    /* clang-format off */ NS_SWIFT_NAME(createMessage(conversation:body:metadata:completion:)); /* clang-format on */

/**
 Creates a message in the specified conversation with an attachment.

 @param conversation conversation object
 @param body message body
 @param attachment SKYAsset object containing the attachment.
 @param metadata application metadata for the conversation
 @param completion completion block
 */
- (void)createMessageWithConversation:(SKYConversation *_Nonnull)conversation
                                 body:(NSString *_Nullable)body
                           attachment:(SKYAsset *_Nullable)attachment
                             metadata:(NSDictionary<NSString *, id> *_Nullable)metadata
                           completion:(SKYChatMessageCompletion _Nullable)completion
    /* clang-format off */ NS_SWIFT_NAME(createMessage(conversation:body:attachment:metadata:completion:)); /* clang-format on */

/**
 Adds a message to a conversation.

 The message is modified with the conversation and saved to the server. If the message contains
 attachment and the attachment is not uploaded yet, the attachment will be uploaded first and
 the message is then saved to the server.

 @param message message to add to a conversation
 @param conversation conversation object
 @param completion completion block
 */
- (void)addMessage:(SKYMessage *_Nonnull)message
    toConversation:(SKYConversation *_Nonnull)conversation
        completion:(SKYChatMessageCompletion _Nullable)completion
    /* clang-format off */ NS_SWIFT_NAME(addMessage(_:to:completion:)); /* clang-format on */

/**
 Fetch messages in a conversation.

 @param conversation conversation object
 @param limit the number of messages to fetch
 @param beforeTime only messages before this time is fetched
 @param completion completion block
 */
- (void)fetchMessagesWithConversation:(SKYConversation *_Nonnull)conversation
                                limit:(NSInteger)limit
                           beforeTime:(NSDate *_Nullable)beforeTime
                           completion:(SKYChatFetchMessagesListCompletion _Nullable)completion
    /* clang-format off */ NS_SWIFT_NAME(fetchMessages(conversation:limit:beforeTime:completion:)); /* clang-format on */

/**
 Fetch messages in a conversation by ID.

 @param conversationId ID of the conversation
 @param limit the number of messages to fetch
 @param beforeTime only messages before this time is fetched
 @param completion completion block
 */
- (void)fetchMessagesWithConversationID:(NSString *_Nonnull)conversationId
                                  limit:(NSInteger)limit
                             beforeTime:(NSDate *_Nullable)beforeTime
                             completion:(SKYChatFetchMessagesListCompletion _Nullable)completion
    /* clang-format off */ NS_SWIFT_NAME(fetchMessages(conversationID:limit:beforeTime:completion:)); /* clang-format on */

///----------------------------------------------
/// @name Send message delivery and read receipts
///----------------------------------------------

/**
 Marks messages as read.

 Marking a messages as read also mark the message as delivered.

 @param messages messages to mark
 @param completion completion block
 */
- (void)markReadMessages:(NSArray<SKYMessage *> *_Nonnull)messages
              completion:(void (^_Nullable)(NSError *_Nullable error))completion
    /* clang-format off */ NS_SWIFT_NAME(markReadMessages(_:completion:)); /* clang-format on */

/**
 Marks messages as read.

 Marking a messages as read also mark the message as delivered.

 @param messageIDs ID of messages to mark
 @param completion completion block
 */
- (void)markReadMessagesWithID:(NSArray<NSString *> *_Nonnull)messageIDs
                    completion:(void (^_Nullable)(NSError *_Nullable error))completion
    /* clang-format off */ NS_SWIFT_NAME(markReadMessages(id:completion:)); /* clang-format on */

/**
 Marks messages as delivered.

 The SDK marks a message as delivered automatically when the message is fetched from server.
 You are not required to call this method.

 @param messages messages to delivered
 @param completion completion block
 */
- (void)markDeliveredMessages:(NSArray<SKYMessage *> *_Nonnull)messages
                   completion:(void (^_Nullable)(NSError *_Nullable error))completion
    /* clang-format off */ NS_SWIFT_NAME(markDeliveredMessages(_:completion:)); /* clang-format on */

/**
 Marks messages as delivered.

 The SDK marks a message as delivered automatically when the message is fetched from server.
 You are not required to call this method.

 @param messageIDs ID of messages to delivered
 @param completion completion block
 */
- (void)markDeliveredMessagesWithID:(NSArray<NSString *> *_Nonnull)messageIDs
                         completion:(void (^_Nullable)(NSError *_Nullable error))completion
    /* clang-format off */ NS_SWIFT_NAME(markDeliveredMessages(id:completion:)); /* clang-format on */

/**
 Fetch delivery and read receipts of a message.

 @param message the message object
 @param completion completion block
 */
- (void)fetchReceiptsWithMessage:(SKYMessage *_Nonnull)message
                      completion:(void (^_Nullable)(NSArray<SKYChatReceipt *> *_Nullable receipts,
                                                    NSError *_Nullable error))completion
    /* clang-format off */ NS_SWIFT_NAME(fetchReceipts(message:completion:)); /* clang-format on */

///--------------------------------------------------
/// @name Modifying read position with message marker
///--------------------------------------------------

/**
 Mark a message as the last read message in a user conversation.

 The last read message affects the last read position of messages in a user conversation. The
 number of unread conversations will change. Calling this method will not affect delivery and
 read receipts.

 @param message the message object
 @param userConversation the user conversation object
 @param completion completion block
 */
- (void)markLastReadMessage:(SKYMessage *_Nonnull)message
         inUserConversation:(SKYUserConversation *_Nonnull)userConversation
                 completion:(SKYChatUserConversationCompletion _Nullable)completion
    /* clang-format off */ NS_SWIFT_NAME(markLastReadMessage(_:in:completion:)); /* clang-format on */

/**
 Fetches unread count of a user conversation

 @param userConversation the user conversation object
 @param completion completion block
 */
- (void)fetchUnreadCountWithUserConversation:(SKYUserConversation *_Nonnull)userConversation
                                  completion:(SKYChatUnreadCountCompletion _Nullable)completion
    /* clang-format off */ NS_SWIFT_NAME(fetchUnreadCount(userConversation:completion:)); /* clang-format on */

/**
 Fetches the total unread count of conversations and messages.

 @param completion completion block
 */
- (void)fetchTotalUnreadCount:(SKYChatUnreadCountCompletion _Nullable)completion
    /* clang-format off */ NS_SWIFT_NAME(fetchTotalUnreadCount(completion:)); /* clang-format on */

///-----------------------
/// @name Typing indicator
///-----------------------

/**
 Send typing indicator to the specified conversation.

 This method calls -sendTypingIndicator:inConversation:date:completion: with the
 current date in the date parameter.

 @param typingEvent the event type
 @param conversation the conversation
 */
- (void)sendTypingIndicator:(SKYChatTypingEvent)typingEvent
             inConversation:(SKYConversation *_Nonnull)conversation
    /* clang-format off */ NS_SWIFT_NAME(sendTypingIndicator(_:in:)); /* clang-format on */

/**
 Send typing indicator to the specified conversation.

 Most app developers should call the method -sendTypingIndicator:inConversation:date:completion:
 instead.

 @param typingEvent the event type
 @param conversation the conversation
 @param date the date/time when this typing indicator occurs
 @param completion the completion handler
 */
- (void)sendTypingIndicator:(SKYChatTypingEvent)typingEvent
             inConversation:(SKYConversation *_Nonnull)conversation
                       date:(NSDate *_Nonnull)date
                 completion:(void (^_Nullable)(NSError *_Nullable error))completion
    /* clang-format off */ NS_SWIFT_NAME(sendTypingIndicator(_:in:at:completion:)); /* clang-format on */

///-----------------------------------------
/// @name Subscribing to events using pubsub
///-----------------------------------------

/**
 Fetches the user channel, or creates one if it does not exist.

 @param completion the completion handler
 */
- (void)fetchOrCreateUserChannelWithCompletion:(SKYChatChannelCompletion _Nullable)completion
    /* clang-format off */ NS_SWIFT_NAME(fetchOrCreateUserChannel(completion:)); /* clang-format on */

/**
 Deletes all user channel.

 If chat extension is currently subscribed to a user channel, the chat extension will unsubscribe
 from
 the user channel first before deleting.

 @param completion the completion handler
 */
- (void)deleteAllUserChannelsWithCompletion:(void (^_Nullable)(NSError *_Nullable error))completion
    /* clang-format off */ NS_SWIFT_NAME(deleteAllUserChannels(completion:)); /* clang-format on */

/**
 Subscribe to changes from user channel.

 Changes such as new messages and typing indicator are pushed to the client side using pubsub. If
 you are interested to receive these events, you should call this method so that chat
 extension will subscribe to these messages. When subscribed, the chat extension will post
 notifications
 using NSNotificationCenter. Observe to these notifications by adding an observer to the default
 NSNotificationCenter.

 If user channel does not exist yet, one will be created for you automatically.

 Alternatively, if you are interested in one type of events from the user channel such as typing
 indicators,
 you can call the -subscribeToTypingIndicatorInConversation:handler: convenient method to get typing
 indicator objects
 as they are received. You do not need to call this method as that convenient method will call this
 method for you.

 @param completion the completion handler
 */
- (void)subscribeToUserChannelWithCompletion:(void (^_Nullable)(NSError *_Nullable error))completion
    /* clang-format off */ NS_SWIFT_NAME(subscribeToUserChannelWithCompletion(completion:)); /* clang-format on */

/**
 Unsubscribe from user channel.

 If the chat extension is currently subscribed to a user channel, the chat extension will
 unsubscribe from
 the underlying pubsub channel.

 The chat extension will also unsubscribe from user channel when the current user is changed (such
 as logout).
 */
- (void)unsubscribeFromUserChannel;

/**
 Subscribe to typing indicator events in a conversation.

 To get typing indicator event, call this method with a handler that accepts a
 SKYChatTypingIndicator as parameter.
 You are also required to specify a conversation where typing indicator events apply. You may
 subscribe to multiple
 conversation at the same time.

 This method adds an observer to NSNotificationCenter and return the observer to you. If you are no
 longer interested
 in updates for a particular conversation. Remove the observer from NSNotificationCenter using the
 returned object.

 @param conversation the conversation object
 @param handler the typing indicator handler
 @return NSNotificationCenter observer
 */
- (id _Nonnull)
subscribeToTypingIndicatorInConversation:(SKYConversation *_Nonnull)conversation
                                 handler:(void (^_Nonnull)(
                                             SKYChatTypingIndicator *_Nonnull indicator))handler
    /* clang-format off */ NS_SWIFT_NAME(subscribeToTypingIndicator(in:handler:)); /* clang-format on */

/**
 Subscribe to message events in a conversation.

 To get message event, call this method with a handler that accepts a SKYChatRecordChangeEvent and
 SKYMessage as parameters.
 You are also required to specify a conversation where message events apply. You may subscribe to
 multiple
 conversation at the same time.

 This method adds an observer to NSNotificationCenter and return the observer to you. If you are no
 longer interested
 in updates for a particular conversation. Remove the observer from NSNotificationCenter using the
 returned object.

 @param conversation the conversation object
 @param handler the message handler
 @return NSNotificationCenter observer
 */
- (id _Nonnull)subscribeToMessagesInConversation:(SKYConversation *_Nonnull)conversation
                                         handler:
                                             (void (^_Nonnull)(SKYChatRecordChangeEvent event,
                                                               SKYMessage *_Nonnull record))handler
    /* clang-format off */ NS_SWIFT_NAME(subscribeToMessages(in:handler:)); /* clang-format on */

/**
 Unsubscribe to message events

 This method removes an observer from NSNotificationCenter for message events. The observer can be
 obtained when subscribing message events.

 @param NSNotification observer
 */
- (void)unsubscribeToMessagesWithObserver:(id _Nonnull)observer;

/**
 Unsubscribe to typing indicator events

 This method removes an observer from NSNotificationCenter for typing indicator events. The
 observer can be obtained when subscribing typing indicator events.

 @param NSNotification observer
 */
- (void)unsubscribeToTypingIndicatorWithObserver:(id _Nonnull)observer;

@end
