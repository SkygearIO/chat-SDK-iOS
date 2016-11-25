//
//  SKYContainer+Chat.h
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

#import <SKYKit/SKYKit.h>

typedef NS_ENUM(int, SKYChatMetaDataType) {
    SKYChatMetaDataImage,
    SKYChatMetaDataVoice,
    SKYChatMetaDataText
};

extern NSString *const SKYChatMetaDataAssetNameImage;
extern NSString *const SKYChatMetaDataAssetNameVoice;
extern NSString *const SKYChatMetaDataAssetNameText;

@class FBSDKAccessToken, SKYConversation, SKYConversationChange, SKYMessage, SKYUserChannel,
    SKYLastMessageRead, SKYChatUser, SKYUserConversation;

@interface SKYChatExtension : NSObject

typedef void (^SKYContainerUserConversationOperationActionCompletion)(
    SKYUserConversation *conversation, NSError *error);
typedef void (^SKYContainerMessageOperationActionCompletion)(SKYMessage *message, NSError *error);
typedef void (^SKYContainerMarkLastMessageReadOperationActionCompletion)(
    SKYUserConversation *conversation, NSError *error);
typedef void (^SKYContainerLastMessageReadOperationActionCompletion)(
    SKYLastMessageRead *lastMessageRead, NSError *error);
typedef void (^SKYContainerTotalUnreadCountOperationActionCompletion)(NSDictionary *response,
                                                                      NSError *error);
typedef void (^SKYContainerUnreadCountOperationActionCompletion)(NSInteger count, NSError *error);
typedef void (^SKYContainerChannelOperationActionCompletion)(SKYUserChannel *userChannel,
                                                             NSError *error);
typedef void (^SKYContainerGetAgentListActionCompletion)(NSArray<SKYChatUser *> *agentListArray,
                                                         NSError *error);
typedef void (^SKYContainerGetUserConversationListActionCompletion)(
    NSArray<SKYUserConversation *> *conversationList, NSError *error);
typedef void (^SKYContainerGetMessagesActionCompletion)(NSArray<SKYMessage *> *messageList,
                                                        NSError *error);
typedef void (^SKYContainerGetAssetsActionCompletion)(SKYAsset *assets, NSError *error);
typedef void (^SKYContainerConversationOperationActionCompletion)(SKYConversation *conversation,
                                                                  NSError *error);

@property (strong, nonatomic, readonly) SKYContainer *_Nonnull container;

- (instancetype)initWithContainer:(SKYContainer *_Nonnull)container;

#pragma mark - Conversations

- (void)createConversationWithParticipantIDs:(NSArray<NSString *> *)participantIds
                                adminIDs:(NSArray<NSString *> *)adminIds
                                   title:(NSString *)title
                           completionHandler:
                               (SKYContainerConversationOperationActionCompletion)completionHandler;

- (void)fetchOrCreateDirectConversationWithUserId:(NSString *)userId
                               completionHandler:(SKYContainerConversationOperationActionCompletion)
                                                     completionHandler;

- (void)deleteConversation:(SKYConversation *)conversation
                           completionHandler:
                               (SKYContainerConversationOperationActionCompletion)completionHandler;

- (void)deleteConversationWithID:(NSString *)conversationId
               completionHandler:(SKYContainerConversationOperationActionCompletion)completionHandler;

- (void)saveConversation:(SKYConversation *)conversation
                           completionHandler:
                               (SKYContainerConversationOperationActionCompletion)completionHandler;

#pragma mark Fetching User Conversations

- (void)fetchUserConversationsCompletionHandler:
    (SKYContainerGetUserConversationListActionCompletion)completionHandler;

- (void)fetchUserConversationWithID:(NSString *)conversationId
                            completionHandler:
                                (SKYContainerUserConversationOperationActionCompletion)
                                    completionHandler;

#pragma mark Conversation Memberships

- (void)addParticipantsWithIDs:(NSArray<NSString *> *)participantIDs
                toConversation:(SKYConversation *)conversation
             completionHandler:
(SKYContainerConversationOperationActionCompletion)completionHandler;

- (void)removeParticipantsWithIDs:(NSArray<NSString *> *)participantIDs
                 fromConversation:(SKYConversation *)conversation
                completionHandler:
(SKYContainerConversationOperationActionCompletion)completionHandler;

- (void)addAdminsWithIDs:(NSArray<NSString *> *)adminIDs
                toConversation:(SKYConversation *)conversation
             completionHandler:
(SKYContainerConversationOperationActionCompletion)completionHandler;

- (void)removeAdminsWithIDs:(NSArray<NSString *> *)adminIDs
                 fromConversation:(SKYConversation *)conversation
                completionHandler:
(SKYContainerConversationOperationActionCompletion)completionHandler;

#pragma mark - Messages

- (void)createMessageWithConversation:(SKYConversation *)conversation
                               body:(NSString *)body
                             metadata:(NSDictionary *)metadata
                      completionHandler:
                          (SKYContainerMessageOperationActionCompletion)completionHandler;

- (void)createMessageWithConversation:(SKYConversation *)conversation
                                 body:(NSString *)body
                                image:(UIImage *)image
                    completionHandler:
(SKYContainerMessageOperationActionCompletion)completionHandler;

- (void)createMessageWithConversation:(SKYConversation *)conversation
                               body:(NSString *)body
                       voiceFileURL:(NSURL *)url
                           duration:(float)duration
                      completionHandler:
(SKYContainerMessageOperationActionCompletion)completionHandler;

- (void)addMessage:(SKYMessage *)message
    toConversation:(SKYConversation *)conversation
 completionHandler:(SKYContainerMessageOperationActionCompletion)completionHandler;

- (void)addMessage:(SKYMessage *)message
          andAsset:(SKYAsset *)asset
    toConversation:(SKYConversation *)conversation
    completionHandler:(SKYContainerMessageOperationActionCompletion)completionHandler;

- (void)deleteMessage:(SKYMessage *)message
    completionHandler:(SKYContainerMessageOperationActionCompletion)completionHandler;

- (void)deleteMessageWithID:(NSString *)messageID
    completionHandler:(SKYContainerMessageOperationActionCompletion)completionHandler;

- (void)fetchMessagesWithConversation:(SKYConversation *)conversation
                                limit:(NSString *)limit
                           beforeTime:(NSDate *)beforeTime
                    completionHandler:(SKYContainerGetMessagesActionCompletion)completionHandler;

- (void)fetchMessagesWithConversationID:(NSString *)conversationId
                                  limit:(NSString *)limit
                             beforeTime:(NSDate *)beforeTime
                      completionHandler:(SKYContainerGetMessagesActionCompletion)completionHandler;

#pragma mark Delivery and Read Status

- (void)markReadMessages:(NSArray<SKYMessage *> *)messages
       completionHandler:(void(^)(NSError *error))completionHandler;

- (void)markReadMessagesWithID:(NSArray<NSString *> *)messageIDs
       completionHandler:(void(^)(NSError *error))completionHandler;

- (void)markDeliveredMessages:(NSArray<SKYMessage *> *)messages
            completionHandler:(void(^)(NSError *error))completionHandler;

- (void)markDeliveredMessagesWithID:(NSArray<NSString *> *)messageIDs
                  completionHandler:(void(^)(NSError *error))completionHandler;

#pragma mark Message Markers

- (void)getOrCreateLastMessageReadithConversationId:(NSString *)conversationId
                                  completionHandler:
                                      (SKYContainerLastMessageReadOperationActionCompletion)
                                          completionHandler;

- (void)markAsLastMessageReadWithConversationId:(NSString *)conversationId
                                  withMessageId:(NSString *)messageId
                              completionHandler:
                                  (SKYContainerMarkLastMessageReadOperationActionCompletion)
                                      completionHandler;

- (void)getTotalUnreadCount:(SKYContainerTotalUnreadCountOperationActionCompletion)completionHandler;

- (void)getUnreadMessageCountWithConversationId:(NSString *)conversationId
                              completionHandler:(SKYContainerUnreadCountOperationActionCompletion)
                                                    completionHandler;

- (void)getOrCreateUserChannelCompletionHandler:
    (SKYContainerChannelOperationActionCompletion)completionHandler;

#pragma mark - Subscriptions

- (void)subscribeHandler:(void (^)(NSDictionary *))messageHandler;

#pragma mark - Assets

- (void)fetchAssetsByRecordId:(NSString *)recordId
            CompletionHandler:(SKYContainerGetAssetsActionCompletion)completionHandler;

@end
