//
//  SKYChatExtension.h
//  SKYKit
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

extern NSString *_Nonnull const SKYChatMessageUnreadCountKey;
extern NSString *_Nonnull const SKYChatConversationUnreadCountKey;

extern NSString *_Nonnull const SKYChatAdminsMetadataKey;
extern NSString *_Nonnull const SKYChatDistinctByParticipantsMetadataKey;

extern NSString *_Nonnull const SKYChatMetaDataAssetNameImage;
extern NSString *_Nonnull const SKYChatMetaDataAssetNameVoice;
extern NSString *_Nonnull const SKYChatMetaDataAssetNameText;

@class SKYConversation, SKYMessage, SKYUserChannel, SKYUserConversation, SKYChatReceipt;

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
 Gets an instance of SKYContainer used by this SKYChatExtension.
 */
@property (strong, nonatomic, readonly, nonnull) SKYContainer *container;

/**
 Gets or sets whether messages fetched from server are automatically marked as delivered.

 The SDK automatically mark messages as delivered by default.
 */
@property (assign, nonatomic) bool automaticallyMarkMessagesAsDelivered;

/**
 Creates an instance of SKYChatExtension.

 For most user of the chat extension, get an instance of SKYChatExtension by using the category
 method called `-[SKYContainer chatExtension]`.

 @param container the SKYContainer that contains user credentials and server configuration
 @return an instance of SKYChatExtension
 */
- (nullable instancetype)initWithContainer:(nonnull SKYContainer *)container;

#pragma mark - Conversations

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
    NS_SWIFT_NAME(createConversation(participantIDs:title:metadata:completion:));

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

// clang-format off
- (void)createConversationWithParticipantIDs:(NSArray<NSString *> *_Nonnull)participantIDs
                                       title:(NSString *_Nullable)title
                                    metadata:(NSDictionary<NSString *, id> *_Nullable)metadata
                                    adminIDs:(NSArray<NSString *> *_Nullable)adminIDs
                      distinctByParticipants:(BOOL)distinctByParticipants
                                  completion:(SKYChatUserConversationCompletion _Nullable)completion
    NS_SWIFT_NAME(createConversation(participantIDs:title:metadata:adminIDs:distinctByParticipants:completion:));
// clang-format on

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
    NS_SWIFT_NAME(createDirectConversation(userID:title:metadata:completion:));

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
    NS_SWIFT_NAME(saveConversation(_:completion:));

#pragma mark Fetching User Conversations

/**
 Fetches user conversations.

 @param completion completion block
 */
- (void)fetchUserConversationsWithCompletion:
    (SKYChatFetchUserConversationListCompletion _Nullable)completion;

/**
 Fetches a user conversation by conversation ID.

 @param conversationID ID of conversation
 @param completion completion block
 */
- (void)fetchUserConversationWithConversationID:(NSString *_Nonnull)conversationID
                                     completion:
                                         (SKYChatUserConversationCompletion _Nullable)completion
    NS_SWIFT_NAME(fetchUserConversation(conversationID:completion:));

/**
 Fetches a user conversation by conversation.

 @param conversation conversation object
 @param completion completion block
 */
- (void)fetchUserConversationWithConversation:(SKYConversation *_Nonnull)conversation
                                   completion:
                                       (SKYChatUserConversationCompletion _Nullable)completion
    NS_SWIFT_NAME(fetchUserConversation(conversation:completion:));

#pragma mark Conversation Memberships

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
    NS_SWIFT_NAME(addParticipants(userIDs:to:completion:));

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
    NS_SWIFT_NAME(removeParticipants(userIDs:from:completion:));

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
    NS_SWIFT_NAME(addAdmins(userIDs:to:completion:));

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
    NS_SWIFT_NAME(removeAdmins(userIDs:from:completion:));

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
NS_SWIFT_NAME(leave(conversationID:completion:));


#pragma mark - Messages

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
    NS_SWIFT_NAME(createMessage(conversation:body:metadata:completion:));

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
    NS_SWIFT_NAME(createMessage(conversation:body:attachment:metadata:completion:));

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
    NS_SWIFT_NAME(addMessage(_:to:completion:));

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
    NS_SWIFT_NAME(fetchMessages(conversation:limit:beforeTime:completion:));

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
    NS_SWIFT_NAME(fetchMessages(conversationID:limit:beforeTime:completion:));

#pragma mark Delivery and Read Status

/**
 Marks messages as read.

 Marking a messages as read also mark the message as delivered.

 @param messages messages to mark
 @param completion completion block
 */
- (void)markReadMessages:(NSArray<SKYMessage *> *_Nonnull)messages
              completion:(void (^_Nullable)(NSError *_Nullable error))completion
    NS_SWIFT_NAME(markReadMessages(_:completion:));

/**
 Marks messages as read.

 Marking a messages as read also mark the message as delivered.

 @param messageIDs ID of messages to mark
 @param completion completion block
 */
- (void)markReadMessagesWithID:(NSArray<NSString *> *_Nonnull)messageIDs
                    completion:(void (^_Nullable)(NSError *_Nullable error))completion
    NS_SWIFT_NAME(markReadMessages(id:completion:));

/**
 Marks messages as delivered.

 The SDK marks a message as delivered automatically when the message is fetched from server.
 You are not required to call this method.

 @param messages messages to delivered
 @param completion completion block
 */
- (void)markDeliveredMessages:(NSArray<SKYMessage *> *_Nonnull)messages
                   completion:(void (^_Nullable)(NSError *_Nullable error))completion
    NS_SWIFT_NAME(markDeliveredMessages(_:completion:));

/**
 Marks messages as delivered.

 The SDK marks a message as delivered automatically when the message is fetched from server.
 You are not required to call this method.

 @param messageIDs ID of messages to delivered
 @param completion completion block
 */
- (void)markDeliveredMessagesWithID:(NSArray<NSString *> *_Nonnull)messageIDs
                         completion:(void (^_Nullable)(NSError *_Nullable error))completion
    NS_SWIFT_NAME(markDeliveredMessages(id:completion:));

/**
 Fetch delivery and read receipts of a message.

 @param message the message object
 @param completion completion block
 */
- (void)fetchReceiptsWithMessage:(SKYMessage *_Nonnull)message
                      completion:(void (^_Nullable)(NSArray<SKYChatReceipt *> *_Nullable receipts,
                                                    NSError *_Nullable error))completion
    NS_SWIFT_NAME(fetchReceipts(message:completion:));

#pragma mark Message Markers

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
    NS_SWIFT_NAME(markLastReadMessage(_:in:completion:));

/**
 Fetches unread count of a user conversation

 @param userConversation the user conversation object
 @param completion completion block
 */
- (void)fetchUnreadCountWithUserConversation:(SKYUserConversation *_Nonnull)userConversation
                                  completion:(SKYChatUnreadCountCompletion _Nullable)completion
    NS_SWIFT_NAME(fetchUnreadCount(userConversation:completion:));

/**
 Fetches the total unread count of conversations and messages.

 @param completion completion block
 */
- (void)fetchTotalUnreadCount:(SKYChatUnreadCountCompletion _Nullable)completion
    NS_SWIFT_NAME(fetchTotalUnreadCount(completion:));

- (void)getOrCreateUserChannelCompletionHandler:(SKYChatChannelCompletion _Nullable)completion;

#pragma mark - Subscriptions

- (void)subscribeHandler:(void (^_Nonnull)(NSDictionary<NSString *, id> *_Nonnull))messageHandler;

@end
