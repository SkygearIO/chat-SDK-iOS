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
#import "SKYMessageOperation.h"

NS_ASSUME_NONNULL_BEGIN

/**
 When obtaining a dictionary containing unread count information, use this
 key to get the number of unread messages.
 */
extern NSString *const SKYChatMessageUnreadCountKey;

/**
 When obtaining a dictionary containing unread count information, use this
 key to get the number of unread conversations.
 */
extern NSString *const SKYChatConversationUnreadCountKey;

/**
 This notification is posted when the client receives an event for typing indicator.
 */
extern NSString *const SKYChatDidReceiveTypingIndicatorNotification;

/**
 This notification is posted when the client receives an event for record change.
 */
extern NSString *const SKYChatDidReceiveRecordChangeNotification;

/**
 For the SKYChatDidReceiveTypingIndicatorNotification, this user info key
 can be used to get an object of SKYChatTypingIndicator.
 */
extern NSString *const SKYChatTypingIndicatorUserInfoKey;

/**
 For the SKYChatDidReceiveRecordChangeNotification, this user info key
 can be used to get an object of SKYChatRecordChange.
 */
extern NSString *const SKYChatRecordChangeUserInfoKey;

@class SKYParticipant, SKYConversation, SKYMessage, SKYUserChannel, SKYMessageOperation;

/**
 SKYChatExtension is a simple object that expose easy to use helper methods to develop a chat
 app.

 Most of the functions provide by the chat plugin is available through this extension object.

 The extension requires a SKYContainer to function. For most app developer, you should obtain
 a SKYChatExtension through the `-[SKYContainer chatExtension]` category method.
 */
@interface SKYChatExtension : NSObject

typedef void (^SKYChatDeleteConversationCompletion)(NSNumber *_Nullable result,
                                                    NSError *_Nullable error);
typedef void (^SKYChatConversationCompletion)(SKYConversation *_Nullable conversation,
                                              NSError *_Nullable error);
typedef void (^SKYChatFetchParticpantsCompletion)(
    NSDictionary<NSString *, SKYParticipant *> *participantsMap, BOOL isCached,
    NSError *_Nullable error);
typedef void (^SKYChatMessageCompletion)(SKYMessage *_Nullable message, NSError *_Nullable error);
typedef void (^SKYChatUnreadCountCompletion)(
    NSDictionary<NSString *, NSNumber *> *_Nullable response, NSError *_Nullable error);
typedef void (^SKYChatChannelCompletion)(SKYUserChannel *_Nullable userChannel,
                                         NSError *_Nullable error);
typedef void (^SKYChatFetchConversationListCompletion)(
    NSArray<SKYConversation *> *_Nullable conversationList, NSError *_Nullable error);
typedef void (^SKYChatFetchMessagesListCompletion)(NSArray<SKYMessage *> *_Nullable messageList,
                                                   BOOL isCached, NSError *_Nullable error);
typedef void (^SKYChatFetchMessageOperationsListCompletion)(
    NSArray<SKYMessageOperation *> *_Nullable messageOperationList);

typedef void (^SKYMessageOperationCompletion)(SKYMessageOperation *messageOperation,
                                              SKYMessage *_Nullable message,
                                              NSError *_Nullable error);
typedef void (^SKYMessageOperationListCompletion)(
    NSArray<SKYMessageOperation *> *messageOperations);

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
    (NSDictionary<NSString *, id> *);

///------------------------------------------
/// @name Creating and fetching conversations
///------------------------------------------

/**
 Creates a conversation with the selected participants.

 All participants will also become the admins of the created conversation. The conversation
 will not be distinct by participants by default.

 If participants list do not include the current user, the current user will be added to the
 list as well. The same applies for admins list.

 @param participantIDs an array of all participants in the conversation
 @param title title of the conversation
 @param metadata application metadata for the conversation
 @param completion completion block
 */
- (void)createConversationWithParticipantIDs:(NSArray<NSString *> *)participantIDs
                                       title:(NSString *_Nullable)title
                                    metadata:(NSDictionary<NSString *, id> *_Nullable)metadata
                                  completion:(SKYChatConversationCompletion _Nullable)completion
    /* clang-format off */ NS_SWIFT_NAME(createConversation(participantIDs:title:metadata:completion:)); /* clang-format on */

/**
 Creates a conversation with the selected participants.

 All participants will also become the admins of the created conversation. The conversation
 will not be distinct by participants by default.

 If participants list do not include the current user, the current user will be added to the
 list as well. The same applies for admins list.

 @param participants an array of all participants in the conversation
 @param title title of the conversation
 @param metadata application metadata for the conversation
 @param completion completion block
 */
- (void)createConversationWithParticipants:(NSArray<SKYParticipant *> *)participants
                                     title:(NSString *_Nullable)title
                                  metadata:(NSDictionary<NSString *, id> *_Nullable)metadata
                                completion:(SKYChatConversationCompletion _Nullable)completion
    /* clang-format off */ NS_SWIFT_NAME(createConversation(participants:title:metadata:completion:)); /* clang-format on */

/**
 Creates a conversation with the selected participants.

 If participants list do not include the current user, the current user will be added to the
 list as well. The same applies for admins list. If the admins list is not specified, the admins
 list will be the same as the participants list.

 If distinctByParticipants is set to YES, the chat extension will attempt to find an existing
 conversation with the same list of participants before creating a new one.

 @param participantIDs an array of all participants in the conversation
 @param title title of the conversation
 @param metadata application metadata for the conversation
 @param adminIDs an array of all participants that can administrate the conversation
 @param completion completion block
 */

- (void)createConversationWithParticipantIDs:(NSArray<NSString *> *)participantIDs
                                       title:(NSString *_Nullable)title
                                    metadata:(NSDictionary<NSString *, id> *_Nullable)metadata
                                    adminIDs:(NSArray<NSString *> *_Nullable)adminIDs
                      distinctByParticipants:(BOOL)distinctByParticipants
                                  completion:(SKYChatConversationCompletion _Nullable)completion
    /* clang-format off */ NS_SWIFT_NAME(createConversation(participantIDs:title:metadata:adminIDs:distinctByParticipants:completion:)); /* clang-format on */

/**
 Creates a conversation with the selected participants.

 If participants list do not include the current user, the current user will be added to the
 list as well. The same applies for admins list. If the admins list is not specified, the admins
 list will be the same as the participants list.

 If distinctByParticipants is set to YES, the chat extension will attempt to find an existing
 conversation with the same list of participants before creating a new one.

 @param participants an array of all participants in the conversation
 @param title title of the conversation
 @param metadata application metadata for the conversation
 @param admins an array of all participants that can administrate the conversation
 @param completion completion block
 */

- (void)createConversationWithParticipants:(NSArray<SKYParticipant *> *)participants
                                     title:(NSString *_Nullable)title
                                  metadata:(NSDictionary<NSString *, id> *_Nullable)metadata
                                    admins:(NSArray<SKYParticipant *> *_Nullable)admins
                    distinctByParticipants:(BOOL)distinctByParticipants
                                completion:(SKYChatConversationCompletion _Nullable)completion
    /* clang-format off */ NS_SWIFT_NAME(createConversation(participants:title:metadata:admins:distinctByParticipants:completion:)); /* clang-format on */

/**
 Creates a direct conversation with a specific participant.

 The current user and the specified participant will be in the participants list and admins list.

 The new conversation will have distinctByParticipants set to YES. This allows the application
 to reuse an existing direct conversation.

 @param participantID the ID of the participant in the direct conversation
 @param title title of the conversation
 @param metadata application metadata for the conversation
 @param completion completion block
 */
- (void)createDirectConversationWithParticipantID:(NSString *)participantID
                                            title:(NSString *_Nullable)title
                                         metadata:(NSDictionary<NSString *, id> *_Nullable)metadata
                                       completion:
                                           (SKYChatConversationCompletion _Nullable)completion
    /* clang-format off */ NS_SWIFT_NAME(createDirectConversation(participantID:title:metadata:completion:)); /* clang-format on */

/**
 Creates a direct conversation with a specific participant.

 The current user and the specified participant will be in the participants list and admins list.

 The new conversation will have distinctByParticipants set to YES. This allows the application
 to reuse an existing direct conversation.

 @param participant the participant in the direct conversation
 @param title title of the conversation
 @param metadata application metadata for the conversation
 @param completion completion block
 */
- (void)createDirectConversationWithParticipant:(SKYParticipant *)participant
                                          title:(NSString *_Nullable)title
                                       metadata:(NSDictionary<NSString *, id> *_Nullable)metadata
                                     completion:(SKYChatConversationCompletion _Nullable)completion
    /* clang-format off */ NS_SWIFT_NAME(createDirectConversation(participant:title:metadata:completion:)); /* clang-format on */

/**
 Saves a conversation.

 This method can be used to save a new conversation or update an existing conversation. This
 method does not reuse an existing conversation even if distinctByParticipants is set to YES.

 To create or reuse a conversation, call createConversation... instead.

 @param conversation the conversation to be saved
 @param completion completion block
 */
- (void)saveConversation:(SKYConversation *)conversation
              completion:(SKYChatConversationCompletion _Nullable)completion
    /* clang-format off */ NS_SWIFT_NAME(saveConversation(_:completion:)); /* clang-format on */

/**
 Deletes a conversation.

 This method can be used to delete an existing conversation.
 @param conversation the conversation to be saved
 @param completion completion block
 */
- (void)deleteConversation:(SKYConversation *)conversation
                completion:(SKYChatDeleteConversationCompletion _Nullable)completion
    /* clang-format off */ NS_SWIFT_NAME(deleteConversation(_:completion:)); /* clang-format on */

/**
 Fetches conversations.

 @param completion completion block
 */
- (void)fetchConversationsWithCompletion:
    (SKYChatFetchConversationListCompletion _Nullable)completion
    /* clang-format off */ NS_SWIFT_NAME(fetchConversations(completion:)); /* clang-format on */

/**
 Fetches conversations with optional last message in conversation.

 @param fetchLastMessage whether to fetch the last message
 @param completion completion block
 */
- (void)fetchConversationsWithFetchLastMessage:(BOOL)fetchLastMessage
                                    completion:
                                        (SKYChatFetchConversationListCompletion _Nullable)completion
    /* clang-format off */ NS_SWIFT_NAME(fetchConversations(fetchLastMessage:completion:)); /* clang-format on */

/**
 Fetches a conversation by conversation ID.

 @param conversationID ID of conversation
 @param fetchLastMessage whether to fetch the last message
 @param completion completion block
 */
- (void)fetchConversationWithConversationID:(NSString *)conversationID
                           fetchLastMessage:(BOOL)fetchLastMessage
                                 completion:(SKYChatConversationCompletion _Nullable)completion
    /* clang-format off */ NS_SWIFT_NAME(fetchConversation(conversationID:fetchLastMessage:completion:)); /* clang-format on */

///---------------------------------------
/// @name Adding and removing participants
///---------------------------------------

/**
 Fetches participants matching the array of IDs

 The provided IDs are used to fetch participants from server. The fetched participants will be
 cached locally. The `completion` may be called twice, one for local cached participants and
 another for participants from server, identified by the parameter `isCached`.

 @param participantIDs the array of participant IDs
 @param completion the completion callback
 */
- (void)fetchParticipants:(NSArray<NSString *> *)participantIDs
               completion:(SKYChatFetchParticpantsCompletion _Nullable)completion
    /* clang-format off */ NS_SWIFT_NAME(fetchParticipants(participantIDs:completion:)); /* clang-format on */

/**
 Adds participants to a conversation.

 The specified participant IDs are added to the conversation record as participants. The modified
 conversation will be saved to the server.

 @param participantIDs the array of participant IDs
 @param conversation conversation record
 @param completion completion block
 */
- (void)addParticipantsWithIDs:(NSArray<NSString *> *)participantIDs
                toConversation:(SKYConversation *)conversation
                    completion:(SKYChatConversationCompletion _Nullable)completion
    /* clang-format off */ NS_SWIFT_NAME(add(participantIDs:to:completion:)); /* clang-format on */

/**
 Adds participants to a conversation.

 The specified participants are added to the conversation record as participants. The modified
 conversation will be saved to the server.

 @param participants the array of participants
 @param conversation conversation record
 @param completion completion block
 */
- (void)addParticipants:(NSArray<SKYParticipant *> *)participants
         toConversation:(SKYConversation *)conversation
             completion:(SKYChatConversationCompletion _Nullable)completion
    /* clang-format off */ NS_SWIFT_NAME(add(participants:to:completion:)); /* clang-format on */

/**
 Removes participants from a conversation.

 The specified participant IDs are removed from the conversation record as participants. The
 modified conversation will be saved to the server.

 @param participantIDs the array of participant IDs
 @param conversation conversation record
 @param completion completion block
 */
- (void)removeParticipantsWithIDs:(NSArray<NSString *> *)participantIDs
                 fromConversation:(SKYConversation *)conversation
                       completion:(SKYChatConversationCompletion _Nullable)completion
    /* clang-format off */ NS_SWIFT_NAME(remove(participantIDs:from:completion:)); /* clang-format on */

/**
 Removes participants from a conversation.

 The specified participants are removed from the conversation record as participants. The modified
 conversation will be saved to the server.

 @param participants the array of participants
 @param conversation conversation record
 @param completion completion block
 */
- (void)removeParticipants:(NSArray<SKYParticipant *> *)participants
          fromConversation:(SKYConversation *)conversation
                completion:(SKYChatConversationCompletion _Nullable)completion
    /* clang-format off */ NS_SWIFT_NAME(remove(participantIDs:from:completion:)); /* clang-format on */

/**
 Adds admins to a conversation.

 The specified admin IDs are added to the conversation record as admins. The modified
 conversation will be saved to the server.

 @param adminIDs the array of admin IDs
 @param conversation conversation record
 @param completion completion block
 */
- (void)addAdminsWithIDs:(NSArray<NSString *> *)adminIDs
          toConversation:(SKYConversation *)conversation
              completion:(SKYChatConversationCompletion _Nullable)completion
    /* clang-format off */ NS_SWIFT_NAME(add(adminIDs:to:completion:)); /* clang-format on */

/**
 Adds admins to a conversation.

 The specified admins are added to the conversation record as admins. The modified
 conversation will be saved to the server.

 @param admins the array of admins
 @param conversation conversation record
 @param completion completion block
 */
- (void)addAdmins:(NSArray<SKYParticipant *> *)admins
    toConversation:(SKYConversation *)conversation
        completion:(SKYChatConversationCompletion _Nullable)completion
    /* clang-format off */ NS_SWIFT_NAME(add(admins:to:completion:)); /* clang-format on */

/**
 Removes admins to a conversation.

 The specified admin IDs are removed from the conversation record as admins. The modified
 conversation will be saved to the server.

 @param adminIDs the array of admin IDs
 @param conversation conversation record
 @param completion completion block
 */
- (void)removeAdminsWithIDs:(NSArray<NSString *> *)adminIDs
           fromConversation:(SKYConversation *)conversation
                 completion:(SKYChatConversationCompletion _Nullable)completion
    /* clang-format off */ NS_SWIFT_NAME(remove(adminIDs:from:completion:)); /* clang-format on */

/**
 Removes admins to a conversation.

 The specified user IDs are removed from the conversation record as admins. The modified
 conversation will be saved to the server.

 @param admins the array of admins
 @param conversation conversation record
 @param completion completion block
 */
- (void)removeAdmins:(NSArray<SKYParticipant *> *)admins
    fromConversation:(SKYConversation *)conversation
          completion:(SKYChatConversationCompletion _Nullable)completion
    /* clang-format off */ NS_SWIFT_NAME(remove(admins:from:completion:)); /* clang-format on */

/**
 Remove the current user from the specified conversation.

 This method should be called when the current user wants to leave a conversation. Since modifying
 the participant list is only allowed if the user is an admin, calling
 -removeParticipantsWithIDs:fromConversation:completion: does not work.
 */
- (void)leaveConversation:(SKYConversation *)conversation
               completion:(void (^_Nullable)(NSError *_Nullable error))completion;

/**
 Remove the current user from the specified conversation by ID.

 This method should be called when the current user wants to leave a conversation. Since modifying
 the participant list is only allowed if the user is an admin, calling
 -removeParticipantsWithIDs:fromConversation:completion: does not work.
 */
- (void)leaveConversationWithConversationID:(NSString *)conversationID
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
- (void)createMessageWithConversation:(SKYConversation *)conversation
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
- (void)createMessageWithConversation:(SKYConversation *)conversation
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
- (void)addMessage:(SKYMessage *)message
    toConversation:(SKYConversation *)conversation
        completion:(SKYChatMessageCompletion _Nullable)completion
    /* clang-format off */ NS_SWIFT_NAME(addMessage(_:to:completion:)); /* clang-format on */

/**
 Fetch messages in a conversation.

 @param conversation conversation object
 @param limit the number of messages to fetch
 @param beforeTime only messages before this time is fetched
 @param order order of the messages, either 'edited_at' or '_created_at'
 @param completion completion block
 */
- (void)fetchMessagesWithConversation:(SKYConversation *)conversation
                                limit:(NSInteger)limit
                           beforeTime:(NSDate *_Nullable)beforeTime
                                order:(NSString *_Nullable)order
                           completion:(SKYChatFetchMessagesListCompletion _Nullable)completion
    /* clang-format off */ NS_SWIFT_NAME(fetchMessages(conversation:limit:beforeTime:order:completion:)); /* clang-format on */

/**
 Fetch messages in a conversation by ID.

 @param conversationId ID of the conversation
 @param limit the number of messages to fetch
 @param beforeTime only messages before this time is fetched
 @param order order of the messages, either 'edited_at' or '_created_at'
 @param completion completion block
 */
- (void)fetchMessagesWithConversationID:(NSString *)conversationId
                                  limit:(NSInteger)limit
                             beforeTime:(NSDate *_Nullable)beforeTime
                                  order:(NSString *_Nullable)order
                             completion:(SKYChatFetchMessagesListCompletion _Nullable)completion
    /* clang-format off */ NS_SWIFT_NAME(fetchMessages(conversationID:limit:beforeTime:order:completion:)); /* clang-format on */

/**
 Fetch messages in a conversation.

 @param conversation conversation object
 @param limit the number of messages to fetch
 @param beforeMessage only messages before this message is fetched
 @param order order of the messages, either 'edited_at' or '_created_at'
 @param completion completion block
 */
- (void)fetchMessagesWithConversation:(SKYConversation *_Nonnull)conversation
                                limit:(NSInteger)limit
                        beforeMessage:(SKYMessage *_Nullable)beforeMessage
                                order:(NSString *_Nullable)order
                           completion:(SKYChatFetchMessagesListCompletion _Nullable)completion
    /* clang-format off */ NS_SWIFT_NAME(fetchMessages(conversation:limit:beforeMessage:order:completion:)); /* clang-format on */

/**
 Fetch messages in a conversation.

 @param conversation conversation object
 @param limit the number of messages to fetch
 @param beforeMessageID only messages before this message ID is fetched
 @param order order of the messages, either 'edited_at' or '_created_at'
 @param completion completion block
 */
- (void)fetchMessagesWithConversation:(SKYConversation *_Nonnull)conversation
                                limit:(NSInteger)limit
                      beforeMessageID:(NSString *_Nullable)beforeMessageID
                                order:(NSString *_Nullable)order
                           completion:(SKYChatFetchMessagesListCompletion _Nullable)completion
    /* clang-format off */ NS_SWIFT_NAME(fetchMessages(conversation:limit:beforeMessageID:order:completion:)); /* clang-format on */

/**
 Fetch messages in a conversation by ID.

 @param conversationId ID of the conversation
 @param limit the number of messages to fetch
 @param beforeMessage only messages before this message is fetched
 @param order order of the messages, either 'edited_at' or '_created_at'
 @param completion completion block
 */
- (void)fetchMessagesWithConversationID:(NSString *_Nonnull)conversationId
                                  limit:(NSInteger)limit
                          beforeMessage:(SKYMessage *_Nullable)beforeMessage
                                  order:(NSString *_Nullable)order
                             completion:(SKYChatFetchMessagesListCompletion _Nullable)completion
    /* clang-format off */ NS_SWIFT_NAME(fetchMessages(conversationID:limit:beforeMessage:order:completion:)); /* clang-format on */

/**
 Fetch messages in a conversation by ID.

 @param conversationId ID of the conversation
 @param limit the number of messages to fetch
 @param beforeMessageID only messages before this message ID is fetched
 @param order order of the messages, either 'edited_at' or '_created_at'
 @param completion completion block
 */
- (void)fetchMessagesWithConversationID:(NSString *_Nonnull)conversationId
                                  limit:(NSInteger)limit
                        beforeMessageID:(NSString *_Nullable)beforeMessageID
                                  order:(NSString *_Nullable)order
                             completion:(SKYChatFetchMessagesListCompletion _Nullable)completion
    /* clang-format off */ NS_SWIFT_NAME(fetchMessages(conversationID:limit:beforeMessageID:order:completion:)); /* clang-format on */

///----------------------------------------------
/// @name Send message delivery and read receipts
///----------------------------------------------

/**
 Marks messages as read.

 Marking a messages as read also mark the message as delivered.

 @param messages messages to mark
 @param completion completion block
 */
- (void)markReadMessages:(NSArray<SKYMessage *> *)messages
              completion:(void (^_Nullable)(NSError *_Nullable error))completion
    /* clang-format off */ NS_SWIFT_NAME(markReadMessages(_:completion:)); /* clang-format on */

/**
 Marks messages as read.

 Marking a messages as read also mark the message as delivered.

 @param messageIDs ID of messages to mark
 @param completion completion block
 */
- (void)markReadMessagesWithID:(NSArray<NSString *> *)messageIDs
                    completion:(void (^_Nullable)(NSError *_Nullable error))completion
    /* clang-format off */ NS_SWIFT_NAME(markReadMessages(id:completion:)); /* clang-format on */

/**
 Marks messages as delivered.

 The SDK marks a message as delivered automatically when the message is fetched from server.
 You are not required to call this method.

 @param messages messages to delivered
 @param completion completion block
 */
- (void)markDeliveredMessages:(NSArray<SKYMessage *> *)messages
                   completion:(void (^_Nullable)(NSError *_Nullable error))completion
    /* clang-format off */ NS_SWIFT_NAME(markDeliveredMessages(_:completion:)); /* clang-format on */

/**
 Marks messages as delivered.

 The SDK marks a message as delivered automatically when the message is fetched from server.
 You are not required to call this method.

 @param messageIDs ID of messages to delivered
 @param completion completion block
 */
- (void)markDeliveredMessagesWithID:(NSArray<NSString *> *)messageIDs
                         completion:(void (^_Nullable)(NSError *_Nullable error))completion
    /* clang-format off */ NS_SWIFT_NAME(markDeliveredMessages(id:completion:)); /* clang-format on */

/**
 Fetch delivery and read receipts of a message.

 @param message the message object
 @param completion completion block
 */
- (void)fetchReceiptsWithMessage:(SKYMessage *)message
                      completion:(void (^_Nullable)(NSArray<SKYChatReceipt *> *_Nullable receipts,
                                                    NSError *_Nullable error))completion
    /* clang-format off */ NS_SWIFT_NAME(fetchReceipts(message:completion:)); /* clang-format on */

///-----------------------------------------
/// @name Message Edit & Delete Function
///-----------------------------------------

/**
 Delete a message in a conversation

 The message is soft-deleted in the message. Conversation unread count, last read message and last
 message are updated.

 @param message the message object
 @param conversation the conversation object
 @param completion completion block
 */
- (void)deleteMessage:(SKYMessage *)message
       inConversation:(SKYConversation *)conversation
           completion:(SKYChatConversationCompletion _Nullable)completion
    /* clang-format off */ NS_SWIFT_NAME(deleteMessage(_:in:completion:)); /* clang-format on */

/**
 Edit a message in a conversation

 The message body is updated.

 @param message the message object
 @param body the new message body
 @param completion completion block
 */
- (void)editMessage:(SKYMessage *)message
           withBody:(NSString *)body
         completion:(SKYChatMessageCompletion _Nullable)completion
    /* clang-format off */ NS_SWIFT_NAME(editMessage(_:with:completion:)); /* clang-format on */

///--------------------------------------------------
/// @name Modifying read position with message marker
///--------------------------------------------------

/**
 Mark a message as the last read message in a conversation.

 The last read message affects the last read position of messages in a conversation. The
 number of unread conversations will change. Calling this method will not affect delivery and
 read receipts.

 @param message the message object
 @param conversation the conversation object
 @param completion completion block
 */
- (void)markLastReadMessage:(SKYMessage *)message
             inConversation:(SKYConversation *)conversation
                 completion:(SKYChatConversationCompletion _Nullable)completion
    /* clang-format off */ NS_SWIFT_NAME(markLastReadMessage(_:in:completion:)); /* clang-format on */

/**
 Fetches unread count of a conversation

 @param conversation the conversation object
 @param completion completion block
 */
- (void)fetchUnreadCountWithConversation:(SKYConversation *)conversation
                              completion:(SKYChatUnreadCountCompletion _Nullable)completion
    /* clang-format off */ NS_SWIFT_NAME(fetchUnreadCount(conversation:completion:)); /* clang-format on */

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
             inConversation:(SKYConversation *)conversation
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
             inConversation:(SKYConversation *)conversation
                       date:(NSDate *)date
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
- (id)subscribeToTypingIndicatorInConversation:(SKYConversation *)conversation
                                       handler:(void (^)(SKYChatTypingIndicator *indicator))handler
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
- (id)subscribeToMessagesInConversation:(SKYConversation *)conversation
                                handler:(void (^)(SKYChatRecordChangeEvent event,
                                                  SKYMessage *record))handler
    /* clang-format off */ NS_SWIFT_NAME(subscribeToMessages(in:handler:)); /* clang-format on */

/**
 Subscribe to conversation events.

 To get conversion event, call this method with a handler that accepts a SKYChatRecordChangeEvent
 and SKYMessage as parameters.

 This method adds an observer to NSNotificationCenter and return the observer to you. If you are no
 longer interested
 in updates for a particular conversation. Remove the observer from NSNotificationCenter using the
 returned object.

 @param handler the conversation handler
 @return NSNotificationCenter observer
 */
- (id)subscribeToConversation:
    (void (^)(SKYChatRecordChangeEvent event, SKYConversation *conversation))handler
    /* clang-format off */ NS_SWIFT_NAME(subscribeToConversation(handler:)); /* clang-format on */

/**
 Unsubscribe to conversation events

 This method removes an observer from NSNotificationCenter for message events. The observer can be
 obtained when subscribing conversation events.

 @param observer the observer
 */
- (void)unsubscribeToConversationWithObserver:(id)observer;

/**
 Unsubscribe to message events

 This method removes an observer from NSNotificationCenter for message events. The observer can be
 obtained when subscribing message events.

 @param observer the observer
 */
- (void)unsubscribeToMessagesWithObserver:(id)observer;

/**
 Unsubscribe to typing indicator events

 This method removes an observer from NSNotificationCenter for typing indicator events. The
 observer can be obtained when subscribing typing indicator events.

 @param observer the observer
 */
- (void)unsubscribeToTypingIndicatorWithObserver:(id)observer;

///-----------------------------------------
/// @name Managing Failed Message Operations
///-----------------------------------------

/**
 Fetches outstanding message operations of a conversation.

 This method fetches outstanding message operations that is cached locally. Messages operations that
 are pending or failed will be returned by this method. The application can display these
 outstanding messages to the user and decide how to handle these outstanding operations.

 @param conversationID The conversation ID of the message in a failed operation
 @param operationType The type of the message operation
 @param completion block to be called with an array of failed message operations
 */
- (void)fetchOutstandingMessageOperationsWithConverstionID:(NSString *)conversationID
                                             operationType:(SKYMessageOperationType)operationType
                                                completion:
                                                    (SKYMessageOperationListCompletion _Nullable)
                                                        completion
    /* clang-format off */ NS_SWIFT_NAME(fetchOutstandingMessageOperations(conversationID:operationType:completion:)); /* clang-format on */

/**
 Fetches outstanding message operations of a message.

 This method fetches outstanding message operations that is cached locally. Messages operations that
 are pending or failed will be returned by this method. The application can display these
 outstanding messages to the user and decide how to handle these outstanding operations.

 @param messageID The conversation ID of the message in a failed operation
 @param operationType The type of the message operation
 @param completion block to be called with an array of failed message operations
 */
- (void)fetchOutstandingMessageOperationsWithMessageID:(NSString *)messageID
                                         operationType:(SKYMessageOperationType)operationType
                                            completion:(SKYMessageOperationListCompletion _Nullable)
                                                           completion
    /* clang-format off */ NS_SWIFT_NAME(fetchOutstandingMessageOperations(messageID:operationType:completion:)); /* clang-format on */

/**
 Retry a failed message operation.

 This method is called by the application when it decides to retry the message operation. The
 operation will be removed and a new operation will be created. The message will be saved, edited,
 or deleted according to the message operation type.

 @param operation the message operation to retry
 @param completion block to be called when the message operation completes
 */
- (void)retryMessageOperation:(SKYMessageOperation *)operation
                   completion:(SKYMessageOperationCompletion _Nullable)completion
    /* clang-format off */ NS_SWIFT_NAME(retry(messageOperation:completion:)); /* clang-format on */

/**
 Cancel a failed message operation.

 This method is called by the application when it decides the message operation will not be carried
 out. The operation will be removed and no further actions will be performed.

 @param operation the message operation to retry
 */
- (void)cancelMessageOperation:(SKYMessageOperation *)operation
    /* clang-format off */ NS_SWIFT_NAME(cancel(messageOperation:)); /* clang-format on */

@end

NS_ASSUME_NONNULL_END
