//
//  SKYChatExtension.m
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

#import "SKYChatExtension.h"
#import "SKYChatExtension_Private.h"

#import <SKYKit/SKYKit.h>

#import "SKYChatReceipt.h"
#import "SKYChatRecordChange_Private.h"
#import "SKYChatTypingIndicator_Private.h"
#import "SKYConversation.h"
#import "SKYMessage.h"
#import "SKYReference.h"
#import "SKYUserChannel.h"

#import "SKYChatCacheController.h"
#import "SKYMessageCacheObject.h"

NSString *const SKYChatMessageUnreadCountKey = @"message";
NSString *const SKYChatConversationUnreadCountKey = @"conversation";

NSString *const SKYChatDidReceiveTypingIndicatorNotification =
    @"SKYChatDidReceiveTypingIndicatorNotification";
NSString *const SKYChatDidReceiveRecordChangeNotification =
    @"SKYChatDidReceiveRecordChangeNotification";

NSString *const SKYChatTypingIndicatorUserInfoKey = @"typingIndicator";
NSString *const SKYChatRecordChangeUserInfoKey = @"recordChange";

@implementation SKYChatExtension {
    id notificationObserver;
    SKYUserChannel *subscribedUserChannel;
}

- (instancetype)initWithContainer:(SKYContainer *_Nonnull)container
                  cacheController:(nonnull SKYChatCacheController *)cacheController
{
    if ((self = [super init])) {
        if (!container) {
            @throw [NSException exceptionWithName:NSInvalidArgumentException
                                           reason:@"container cannot be null"
                                         userInfo:nil];
        }
        _container = container;
        _automaticallyMarkMessagesAsDelivered = YES;

        notificationObserver = [[NSNotificationCenter defaultCenter]
            addObserverForName:SKYContainerDidChangeCurrentUserNotification
                        object:container
                         queue:[NSOperationQueue mainQueue]
                    usingBlock:^(NSNotification *_Nonnull note) {
                        // Unsubscribe because the current user has changed. We do not
                        // want the UI to keep notified for changes intended for previous user.
                        [self unsubscribeFromUserChannel];
                    }];

        _cacheController = cacheController;
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:notificationObserver];
}

#pragma mark - Conversations

- (void)createConversationWithParticipantIDs:(NSArray<NSString *> *)participantIDs
                                       title:(NSString *)title
                                    metadata:(NSDictionary<NSString *, id> *)metadata
                                  completion:(SKYChatConversationCompletion)completion
{
    [self createConversationWithParticipantIDs:participantIDs
                                         title:title
                                      metadata:metadata
                                      adminIDs:nil
                        distinctByParticipants:NO
                                    completion:completion];
}

- (void)createConversationWithParticipantIDs:(NSArray<NSString *> *)participantIDs
                                       title:(NSString *)title
                                    metadata:(NSDictionary<NSString *, id> *)metadata
                                    adminIDs:(NSArray<NSString *> *)adminIDs
                      distinctByParticipants:(BOOL)distinctByParticipants
                                  completion:(SKYChatConversationCompletion)completion
{
    if (!participantIDs || participantIDs.count == 0) {
        if (completion) {
            completion(
                nil, [NSError errorWithDomain:@"SKYChatExtension"
                                         code:0
                                     userInfo:@{
                                         NSLocalizedDescriptionKey :
                                             @"cannot create conversation with no participants"
                                     }]);
        }
        return;
    }

    if (![participantIDs containsObject:self.container.auth.currentUserRecordID]) {
        participantIDs =
            [participantIDs arrayByAddingObject:self.container.auth.currentUserRecordID];
    }
    participantIDs = [[NSSet setWithArray:participantIDs] allObjects];

    if (!adminIDs || adminIDs.count == 0) {
        adminIDs = [participantIDs copy];
    } else if (![adminIDs containsObject:self.container.auth.currentUserRecordID]) {
        adminIDs = [adminIDs arrayByAddingObject:self.container.auth.currentUserRecordID];
    }
    adminIDs = [[NSSet setWithArray:adminIDs] allObjects];

    NSDictionary<NSString *, id> *options =
        @{ @"distinctByParticipants" : @(distinctByParticipants),
           @"adminIDs" : adminIDs };

    if (!metadata) {
        metadata = (NSDictionary *)[NSNull null];
    }

    if (!title) {
        title = (NSString *)[NSNull null];
    }

    [self.container callLambda:@"chat:create_conversation"
                     arguments:@[ participantIDs, title, metadata, options ]
             completionHandler:^(NSDictionary *response, NSError *error) {
                 if (error) {
                     NSLog(@"error calling chat:create_conversation: %@", error);
                     if (completion) {
                         completion(nil, error);
                     }
                     return;
                 }
                 NSLog(@"Received response = %@", response);
                 SKYRecordDeserializer *deserializer = [SKYRecordDeserializer deserializer];
                 NSObject *obj = [response objectForKey:@"conversation"];
                 SKYRecord *record = [deserializer recordWithDictionary:[obj copy]];
                 SKYConversation *conversation = [SKYConversation recordWithRecord:record];
                 if (completion) {
                     completion(conversation, error);
                 }
             }];
}

- (void)deleteConversation:(SKYConversation *)conversation
                completion:(SKYChatDeleteConversationCompletion)completion
{
    [self.container
               callLambda:@"chat:delete_conversation"
                arguments:@[ conversation.recordName ]
        completionHandler:^(NSDictionary *response, NSError *error) {
            /* FIXME: remove SKYErrorName checking after
             https://github.com/SkygearIO/skygear-SDK-iOS/issues/118 is close */
            if (error && [error.userInfo[@"SKYErrorName"] isEqualToString:@"PermissionDenied"]) {
                NSLog(@"error calling chat:delete_conversation: %@", error);
                if (completion) {
                    completion(nil, error);
                }
                return;
            }
            if (completion) {
                completion(@YES, nil);
            }
        }];
}

- (void)createDirectConversationWithUserID:(NSString *)userID
                                     title:(NSString *)title
                                  metadata:(NSDictionary<NSString *, id> *)metadata
                                completion:(SKYChatConversationCompletion)completion
{
    [self createConversationWithParticipantIDs:@[ userID ]
                                         title:title
                                      metadata:metadata
                                      adminIDs:nil
                        distinctByParticipants:YES
                                    completion:completion];
}

- (void)saveConversation:(SKYConversation *)conversation
              completion:(SKYChatConversationCompletion)completion
{
    [self.container.publicCloudDatabase saveRecord:conversation.record
                                        completion:^(SKYRecord *record, NSError *error) {
                                            if (!completion) {
                                                return;
                                            }

                                            if (error) {
                                                completion(nil, error);
                                            }

                                            SKYConversation *newConversation =
                                                [SKYConversation recordWithRecord:record];
                                            completion(newConversation, error);
                                        }];
}

#pragma mark Fetching Conversations
- (void)fetchConversationsWithCompletion:(SKYChatFetchConversationListCompletion)completion
{
    [self fetchConversationsWithFetchLastMessage:TRUE completion:completion];
}

- (void)fetchConversationsWithFetchLastMessage:(BOOL)fetchLastMessage
                                    completion:(SKYChatFetchConversationListCompletion)completion
{
    [self.container callLambda:@"chat:get_conversations"
                     arguments:@[
                         [NSNumber numberWithInt:1], [NSNumber numberWithInt:50],
                         [NSNumber numberWithBool:fetchLastMessage]
                     ]
             completionHandler:^(NSDictionary *response, NSError *error) {
                 if (error) {
                     NSLog(@"error calling chat:get_conversations: %@", error);
                     if (completion) {
                         completion(nil, error);
                     }
                     return;
                 }
                 NSLog(@"Received response = %@", response);
                 SKYRecordDeserializer *deserializer = [SKYRecordDeserializer deserializer];
                 NSMutableArray *result = [response mutableArrayValueForKey:@"conversations"];
                 NSMutableArray *conversations = [NSMutableArray array];
                 for (NSDictionary *obj in result) {
                     SKYRecord *record = [deserializer recordWithDictionary:[obj copy]];
                     SKYConversation *conversation = [SKYConversation recordWithRecord:record];
                     [conversations addObject:conversation];
                 }

                 if (completion) {
                     completion(conversations, error);
                 }
             }];
}

- (void)fetchConversationWithConversationID:(NSString *)conversationId
                           fetchLastMessage:(BOOL)fetchLastMessage
                                 completion:(SKYChatConversationCompletion)completion
{
    [self.container callLambda:@"chat:get_conversation"
                     arguments:@[ conversationId, [NSNumber numberWithBool:fetchLastMessage] ]
             completionHandler:^(NSDictionary *response, NSError *error) {
                 if (error) {
                     NSLog(@"error calling chat:get_conversation: %@", error);
                     if (completion) {
                         completion(nil, error);
                     }
                     return;
                 }
                 NSLog(@"Received response = %@", response);
                 SKYRecordDeserializer *deserializer = [SKYRecordDeserializer deserializer];
                 NSObject *obj = [response objectForKey:@"conversation"];
                 SKYRecord *record = [deserializer recordWithDictionary:[obj copy]];
                 SKYConversation *conversation = [SKYConversation recordWithRecord:record];
                 if (completion) {
                     completion(conversation, error);
                 }
             }];
}

- (void)fetchMessagesWithIDs:(NSArray<NSString *> *)messageIDs
                  completion:(SKYChatFetchMessagesListCompletion)completion
{
    if (completion) {
        [self.cacheController fetchMessagesWithIDs:messageIDs
                                        completion:^(NSArray<SKYMessage *> *_Nullable messageList,
                                                     BOOL isCached, NSError *_Nullable error) {
                                            completion(messageList, YES, nil);
                                        }];
    }

    [self.container callLambda:@"chat:get_messages_by_ids"
                     arguments:@[ messageIDs ]
             completionHandler:^(NSDictionary *response, NSError *error) {
                 if (error) {
                     NSLog(@"error calling chat:get_messages_by_ids: %@", error);
                     if (completion) {
                         completion(nil, NO, error);
                     }
                     return;
                 }
                 NSLog(@"Received response = %@", response);
                 NSArray *resultArray = [response objectForKey:@"results"];
                 NSMutableArray *returnArray = [[NSMutableArray alloc] init];
                 NSMutableArray *deletedReturnArray = [[NSMutableArray alloc] init];
                 for (NSDictionary *obj in resultArray) {
                     SKYRecordDeserializer *deserializer = [SKYRecordDeserializer deserializer];
                     SKYRecord *record = [deserializer recordWithDictionary:[obj copy]];

                     SKYMessage *msg = [[SKYMessage alloc] initWithRecordData:record];
                     msg.alreadySyncToServer = true;
                     msg.fail = false;
                     if (msg && msg.deleted) {
                         [deletedReturnArray addObject:msg];
                     } else if (msg && !msg.deleted) {
                         [returnArray addObject:msg];
                     }
                 }
                 if (completion) {
                     completion(returnArray, NO, error);
                 }
             }];
}

#pragma mark Conversation Memberships

- (void)updateMembershipsWithLambda:(NSString *)lambda
                            UserIDs:(NSArray<NSString *> *)userIDs
                     toConversation:(SKYConversation *)conversation
                         completion:(SKYChatConversationCompletion)completion
{
    [self.container callLambda:lambda
                     arguments:@[ conversation.recordID.recordName, userIDs ]
             completionHandler:^(NSDictionary *response, NSError *error) {
                 if (error) {
                     NSLog(@"error calling chat:%@: %@", lambda, error);
                     if (completion) {
                         completion(nil, error);
                     }
                     return;
                 }
                 NSLog(@"Received response = %@", response);
                 SKYRecordDeserializer *deserializer = [SKYRecordDeserializer deserializer];
                 NSObject *obj = [response objectForKey:@"conversation"];
                 SKYRecord *record = [deserializer recordWithDictionary:[obj copy]];
                 SKYConversation *conversation = [SKYConversation recordWithRecord:record];
                 if (completion) {
                     completion(conversation, error);
                 }
             }];
}

- (void)addParticipantsWithUserIDs:(NSArray<NSString *> *)userIDs
                    toConversation:(SKYConversation *)conversation
                        completion:(SKYChatConversationCompletion)completion
{
    [self updateMembershipsWithLambda:@"chat:add_participants"
                              UserIDs:userIDs
                       toConversation:conversation
                           completion:completion];
}

- (void)removeParticipantsWithUserIDs:(NSArray<NSString *> *)userIDs
                     fromConversation:(SKYConversation *)conversation
                           completion:(SKYChatConversationCompletion)completion
{
    [self updateMembershipsWithLambda:@"chat:remove_participants"
                              UserIDs:userIDs
                       toConversation:conversation
                           completion:completion];
}

- (void)addAdminsWithUserIDs:(NSArray<NSString *> *)userIDs
              toConversation:(SKYConversation *)conversation
                  completion:(SKYChatConversationCompletion)completion
{
    [self updateMembershipsWithLambda:@"chat:add_admins"
                              UserIDs:userIDs
                       toConversation:conversation
                           completion:completion];
}

- (void)removeAdminsWithUserIDs:(NSArray<NSString *> *)userIDs
               fromConversation:(SKYConversation *)conversation
                     completion:(SKYChatConversationCompletion)completion
{
    [self updateMembershipsWithLambda:@"chat:remove_admins"
                              UserIDs:userIDs
                       toConversation:conversation
                           completion:completion];
}

- (void)leaveConversation:(SKYConversation *)conversation
               completion:(void (^)(NSError *error))completion
{
    [self leaveConversationWithConversationID:[conversation recordName] completion:completion];
}

- (void)leaveConversationWithConversationID:(NSString *)conversationID
                                 completion:(void (^)(NSError *error))completion
{
    [self.container callLambda:@"chat:leave_conversation"
                     arguments:@[ conversationID ]
             completionHandler:^(NSDictionary *response, NSError *error) {
                 if (completion) {
                     completion(error);
                 }
             }];
}

#pragma mark - Messages

- (void)createMessageWithConversation:(SKYConversation *)conversation
                                 body:(NSString *)body
                             metadata:(NSDictionary *)metadata
                           completion:(SKYChatMessageCompletion)completion
{
    [self createMessageWithConversation:conversation
                                   body:body
                             attachment:nil
                               metadata:metadata
                             completion:completion];
}

- (void)createMessageWithConversation:(SKYConversation *)conversation
                                 body:(NSString *)body
                           attachment:(SKYAsset *)attachment
                             metadata:(NSDictionary *)metadata
                           completion:(SKYChatMessageCompletion)completion
{
    SKYMessage *message = [SKYMessage message];
    if (body) {
        message.body = body;
    }
    if (metadata) {
        message.metadata = metadata;
    }
    if (attachment) {
        message.attachment = attachment;
    }
    [self addMessage:message toConversation:conversation completion:completion];
}

- (void)saveMessage:(SKYMessage *)message completion:(SKYChatMessageCompletion)completion
{
    [self.cacheController saveMessage:message completion:nil];

    SKYDatabase *database = self.container.publicCloudDatabase;
    [database saveRecord:message.record
              completion:^(SKYRecord *record, NSError *error) {
                  SKYMessage *msg = nil;
                  if (error) {
                      message.alreadySyncToServer = false;
                      message.fail = true;
                      [self.cacheController didSaveMessage:message error:error];
                  } else {
                      msg = [[SKYMessage alloc] initWithRecordData:record];
                      msg.alreadySyncToServer = true;
                      msg.fail = false;
                      [self.cacheController didSaveMessage:msg error:error];
                  }

                  if (completion) {
                      completion(msg, error);
                  }
              }];
}

- (void)addMessage:(SKYMessage *)message
    toConversation:(SKYConversation *)conversation
        completion:(SKYChatMessageCompletion)completion
{
    message.conversationRef = [SKYReference referenceWithRecord:conversation.record];
    message.sendDate = [NSDate date];
    if (!message.attachment || !message.attachment.url.isFileURL) {
        [self saveMessage:message completion:completion];
        return;
    }

    [self.container.publicCloudDatabase uploadAsset:message.attachment
                                  completionHandler:^(SKYAsset *uploadedAsset, NSError *error) {
                                      if (error) {
                                          NSLog(@"error uploading asset: %@", error);

                                          // NOTE(cheungpat): No idea why we should save message
                                          // when upload asset has failed, but this is the existing
                                          // behavior.
                                      } else {
                                          message.attachment = uploadedAsset;
                                      }
                                      [self saveMessage:message completion:completion];
                                  }];
}

- (void)fetchUnsentMessagesWithConversationID:(NSString *)conversationId
                                   completion:(void (^)(NSArray<SKYMessage *> *_Nonnull))completion
{
    [self.cacheController fetchUnsentMessagesWithConversationID:conversationId
                                                     completion:completion];
}

- (void)fetchMessagesWithConversation:(SKYConversation *)conversation
                                limit:(NSInteger)limit
                           beforeTime:(NSDate *)beforeTime
                           completion:(SKYChatFetchMessagesListCompletion)completion
{
    [self fetchMessagesWithConversationID:conversation.recordID.recordName
                                    limit:limit
                               beforeTime:beforeTime
                                    order:nil
                               completion:completion];
}

- (void)fetchMessagesWithConversation:(SKYConversation *)conversation
                                limit:(NSInteger)limit
                           beforeTime:(NSDate *)beforeTime
                                order:(NSString *)order
                           completion:(SKYChatFetchMessagesListCompletion)completion
{
    [self fetchMessagesWithConversationID:conversation.recordID.recordName
                                    limit:limit
                               beforeTime:beforeTime
                                    order:order
                               completion:completion];
}

- (void)fetchMessagesWithConversationID:(NSString *)conversationId
                                  limit:(NSInteger)limit
                             beforeTime:(NSDate *)beforeTime
                                  order:(NSString *)order
                             completion:(SKYChatFetchMessagesListCompletion)completion
{

    NSMutableDictionary *arguments = [NSMutableDictionary dictionaryWithObjectsAndKeys:conversationId, @"conversation_id", @(limit), @"limit", nil];
    if (beforeTime) {
        NSString *dateString = [SKYDataSerialization stringFromDate:beforeTime];
        NSLog(@"dateString :%@", dateString);

        [arguments setObject:dateString forKey:@"before_time"];
    }

    if (order) {
        [arguments setObject:order forKey:@"order"];
    }

    if (completion) {
        [self.cacheController
            fetchMessagesWithConversationID:conversationId
                                      limit:limit
                                 beforeTime:beforeTime
                                      order:order
                                 completion:^(NSArray<SKYMessage *> *_Nullable messageList,
                                              BOOL isCached, NSError *_Nullable error) {
                                     completion(messageList, YES, error);
                                 }];
    }

    [self.container
               callLambda:@"chat:get_messages"
      dictionaryArguments:arguments
        completionHandler:^(NSDictionary *response, NSError *error) {
            if (error) {
                NSLog(@"error calling chat:get_messages: %@", error);
                if (completion) {
                    completion(nil, NO, error);
                }
                return;
            }
            NSArray *resultArray = [response objectForKey:@"results"];
            NSMutableArray *returnArray = [[NSMutableArray alloc] init];
            for (NSDictionary *obj in resultArray) {
                SKYRecordDeserializer *deserializer = [SKYRecordDeserializer deserializer];
                SKYRecord *record = [deserializer recordWithDictionary:[obj copy]];

                SKYMessage *msg = [[SKYMessage alloc] initWithRecordData:record];
                msg.alreadySyncToServer = true;
                msg.fail = false;
                if (msg) {
                    [returnArray addObject:msg];
                }
            }

            NSArray *deletedArray = [response objectForKey:@"deleted"];
            NSMutableArray *returnDeletedArray =
                [NSMutableArray arrayWithCapacity:deletedArray.count];
            for (NSDictionary *obj in deletedArray) {
                SKYRecordDeserializer *deserializer = [SKYRecordDeserializer deserializer];
                SKYRecord *record = [deserializer recordWithDictionary:[obj copy]];
                SKYMessage *msg = [[SKYMessage alloc] initWithRecordData:record];
                if (msg) {
                    [returnDeletedArray addObject:msg];
                }
            }

            [self.cacheController didFetchMessages:returnArray deletedMessages:returnDeletedArray];

            if (completion) {
                completion(returnArray, NO, error);
            }

            // The SDK notifies the server that these messages are received
            // from the client side. The app developer is not required
            // to call this method.
            if (returnArray.count && self.automaticallyMarkMessagesAsDelivered) {
                [self markDeliveredMessages:returnArray completion:nil];
            }
        }];
}

#pragma mark Delivery and Read Status

- (void)callLambda:(NSString *)lambda
        messageIDs:(NSArray<NSString *> *)messageIDs
        completion:(void (^)(NSError *error))completion
{
    [self.container callLambda:lambda
                     arguments:@[ messageIDs ]
             completionHandler:^(NSDictionary *dict, NSError *error) {
                 if (completion) {
                     completion(error);
                 }
             }];
}

- (void)markReadMessages:(NSArray<SKYMessage *> *)messages
              completion:(void (^)(NSError *error))completion
{
    NSMutableArray *recordIDs = [NSMutableArray array];
    [messages enumerateObjectsUsingBlock:^(SKYMessage *_Nonnull obj, NSUInteger idx,
                                           BOOL *_Nonnull stop) {
        [recordIDs addObject:obj.recordID.recordName];
    }];
    [self callLambda:@"chat:mark_as_read" messageIDs:recordIDs completion:completion];
}

- (void)markReadMessagesWithID:(NSArray<NSString *> *)messageIDs
                    completion:(void (^)(NSError *error))completion
{
    [self callLambda:@"chat:mark_as_read" messageIDs:messageIDs completion:completion];
}

- (void)markDeliveredMessages:(NSArray<SKYMessage *> *)messages
                   completion:(void (^)(NSError *error))completion
{
    NSMutableArray *recordIDs = [NSMutableArray array];
    [messages enumerateObjectsUsingBlock:^(SKYMessage *_Nonnull obj, NSUInteger idx,
                                           BOOL *_Nonnull stop) {
        [recordIDs addObject:obj.recordID.recordName];
    }];
    [self callLambda:@"chat:mark_as_delivered" messageIDs:recordIDs completion:completion];
}

- (void)markDeliveredMessagesWithID:(NSArray<NSString *> *)messageIDs
                         completion:(void (^)(NSError *error))completion
{
    [self callLambda:@"chat:mark_as_delivered" messageIDs:messageIDs completion:completion];
}

- (void)fetchReceiptsWithMessage:(SKYMessage *)message
                      completion:(void (^)(NSArray<SKYChatReceipt *> *, NSError *error))completion
{
    [self.container callLambda:@"chat:get_receipt"
                     arguments:@[ message.recordID.recordName ]
             completionHandler:^(NSDictionary *dict, NSError *error) {
                 if (!completion) {
                     return;
                 }
                 if (error) {
                     completion(nil, error);
                 }

                 NSMutableArray *receipts = [NSMutableArray array];
                 for (NSDictionary *receiptDict in dict[@"receipts"]) {
                     SKYChatReceipt *receipt =
                         [[SKYChatReceipt alloc] initWithReceiptDictionary:receiptDict];
                     [receipts addObject:receipt];
                 }

                 completion(receipts, nil);
             }];
}

#pragma mark Message Editing

- (void)editMessage:(SKYMessage *_Nonnull)message
           withBody:(NSString *_Nonnull)body
         completion:(SKYChatMessageCompletion _Nullable)completion
{

    NSLog(@"Edit a message, message ID %@", message.recordID.recordName);
    message.body = body;
    [self saveMessage:message completion:completion];
}

#pragma mark Message Deletion

- (void)deleteMessage:(SKYMessage *_Nonnull)message
       inConversation:(SKYConversation *_Nonnull)conversation
           completion:(SKYChatConversationCompletion _Nullable)completion
{
    NSLog(@"Delete a message, messageID %@", message.recordID.recordName);
    [self.container callLambda:@"chat:delete_message"
                     arguments:@[ message.recordID.recordName ]
             completionHandler:^(NSDictionary *response, NSError *error) {
                 if (error) {
                     if (completion) {
                         completion(nil, error);
                     }

                     return;
                 }

                 SKYRecordDeserializer *deserializer = [SKYRecordDeserializer deserializer];
                 SKYRecord *record = [deserializer recordWithDictionary:[response copy]];
                 SKYMessage *msg = [[SKYMessage alloc] initWithRecordData:record];

                 [self.cacheController didDeleteMessage:msg];

                 if (completion) {
                     completion(conversation, nil);
                 }
             }];
}

#pragma mark Message Markers

- (void)markLastReadMessage:(SKYMessage *)message
             inConversation:(SKYConversation *)conversation
                 completion:(SKYChatConversationCompletion)completion
{
    NSLog(@"Mark last read message, messageID %@", message.recordID.recordName);
    [self.container callLambda:@"chat:mark_as_read"
                     arguments:@[ message.recordID.recordName ]
             completionHandler:^(NSDictionary *response, NSError *error) {
                 if (!completion) {
                     return;
                 }
                 if (error) {
                     completion(nil, error);
                 }
                 completion(conversation, error);

             }];
}

- (void)fetchUnreadCountWithConversation:(SKYConversation *)conversation
                              completion:(SKYChatUnreadCountCompletion)completion
{
    [self
        fetchConversationWithConversationID:[conversation recordName]
                           fetchLastMessage:NO
                                 completion:^(SKYConversation *conversation, NSError *error) {
                                     if (!completion) {
                                         return;
                                     }
                                     if (error) {
                                         completion(nil, error);
                                         return;
                                     }
                                     NSDictionary *response = @{
                                         SKYChatMessageUnreadCountKey : @(conversation.unreadCount),
                                     };
                                     completion(response, nil);
                                 }];
}

- (void)fetchTotalUnreadCount:(SKYChatUnreadCountCompletion)completion
{
    [self.container callLambda:@"chat:total_unread"
             completionHandler:^(NSDictionary *response, NSError *error) {
                 if (!completion) {
                     return;
                 }
                 if (error) {
                     completion(nil, error);
                 }

                 // Ensure the dictionary has correct type of classes
                 NSMutableDictionary *fixedResponse = [NSMutableDictionary dictionary];
                 [response enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                     if ([obj isKindOfClass:[NSNumber class]]) {
                         [fixedResponse setObject:obj forKey:key];
                     }
                 }];

                 completion(fixedResponse, error);

             }];
}

#pragma mark Typing Indicator

- (void)sendTypingIndicator:(SKYChatTypingEvent)typingEvent
             inConversation:(SKYConversation *)conversation
{
    [self sendTypingIndicator:typingEvent
               inConversation:conversation
                         date:[NSDate date]
                   completion:nil];
}

- (void)sendTypingIndicator:(SKYChatTypingEvent)typingEvent
             inConversation:(SKYConversation *)conversation
                       date:(NSDate *)date
                 completion:(void (^)(NSError *error))completion
{
    [self.container callLambda:@"chat:typing"
                     arguments:@[
                         [conversation recordName],
                         SKYChatTypingEventToString(typingEvent),
                         [SKYDataSerialization stringFromDate:date],
                     ]
             completionHandler:^(NSDictionary *dict, NSError *error) {
                 if (completion) {
                     completion(error);
                 }
             }];
}

#pragma mark - Subscriptions

- (void)fetchOrCreateUserChannelWithCompletion:(SKYChatChannelCompletion)completion
{
    [self fetchUserChannelWithCompletion:^(SKYUserChannel *_Nullable userChannel,
                                           NSError *_Nullable error) {
        if (error) {
            if (completion) {
                completion(nil, error);
            }
            return;
        }

        if (!userChannel) {
            [self createUserChannelWithCompletion:completion];
            return;
        }

        if (completion) {
            completion(userChannel, nil);
        }
    }];
}

- (void)fetchUserChannelWithCompletion:(SKYChatChannelCompletion)completion
{
    SKYQuery *query = [SKYQuery queryWithRecordType:@"user_channel" predicate:nil];
    query.limit = 1;
    [self.container.privateCloudDatabase
             performQuery:query
        completionHandler:^(NSArray *results, NSError *error) {
            if (!completion) {
                return;
            }

            if (error || results.count == 0) {
                completion(nil, error);
                return;
            }

            completion([[SKYUserChannel alloc] initWithRecordData:results.firstObject], error);
        }];
}

- (void)createUserChannelWithCompletion:(SKYChatChannelCompletion)completion
{
    SKYUserChannel *userChannel = [[SKYUserChannel alloc] init];
    userChannel.name = [[NSUUID UUID] UUIDString];
    [self.container.privateCloudDatabase saveRecord:userChannel.record
                                         completion:^(SKYRecord *record, NSError *error) {
                                             if (!completion) {
                                                 return;
                                             }

                                             if (error) {
                                                 completion(nil, error);
                                                 return;
                                             }

                                             SKYUserChannel *channel =
                                                 [[SKYUserChannel alloc] initWithRecordData:record];
                                             completion(channel, error);
                                         }];
}

- (void)deleteAllUserChannelsWithCompletion:(void (^)(NSError *error))completion
{
    SKYQuery *query = [SKYQuery queryWithRecordType:@"user_channel" predicate:nil];
    [self.container.privateCloudDatabase
             performQuery:query
        completionHandler:^(NSArray *results, NSError *error) {
            if (error) {
                if (completion) {
                    completion(error);
                }
                return;
            }

            NSMutableArray *recordIDsToDelete = [NSMutableArray array];
            [results enumerateObjectsUsingBlock:^(SKYRecord *record, NSUInteger idx,
                                                  BOOL *_Nonnull stop) {
                [recordIDsToDelete addObject:record.recordID];
            }];

            if (!recordIDsToDelete.count) {
                if (completion) {
                    completion(nil);
                }
                return;
            }

            [self.container.privateCloudDatabase
                 deleteRecordsWithIDs:recordIDsToDelete
                    completionHandler:^(NSArray *deletedRecordIDs, NSError *error) {
                        if (completion) {
                            completion(error);
                        }
                    }
                perRecordErrorHandler:nil];
        }];
}

- (void)handleUserChannelDictionary:(NSDictionary<NSString *, id> *)dict
{
    NSString *dictionaryEventType = dict[@"event"];
    NSDictionary *data = dict[@"data"];
    if ([SKYChatTypingIndicator isTypingIndicatorEventType:dictionaryEventType]) {
        [data enumerateKeysAndObjectsUsingBlock:^(NSString *conversationIDString,
                                                  NSDictionary *userDict, BOOL *stop) {
            NSString *conversationID =
                [[SKYRecordID recordIDWithCanonicalString:conversationIDString] recordName];

            SKYChatTypingIndicator *indicator =
                [[SKYChatTypingIndicator alloc] initWithDictionary:userDict
                                                    conversationID:conversationID];

            [[NSNotificationCenter defaultCenter]
                postNotificationName:SKYChatDidReceiveTypingIndicatorNotification
                              object:self
                            userInfo:@{
                                SKYChatTypingIndicatorUserInfoKey : indicator,
                            }];
        }];
    } else if ([SKYChatRecordChange isRecordChangeEventType:dictionaryEventType]) {
        SKYChatRecordChange *recordChange =
            [[SKYChatRecordChange alloc] initWithDictionary:data eventType:dictionaryEventType];
        if (!recordChange) {
            return;
        }

        [self.cacheController handleRecordChange:recordChange];

        [[NSNotificationCenter defaultCenter]
            postNotificationName:SKYChatDidReceiveRecordChangeNotification
                          object:self
                        userInfo:@{
                            SKYChatRecordChangeUserInfoKey : recordChange,
                        }];
    }

    if (self.userChannelMessageHandler) {
        self.userChannelMessageHandler(dict);
    }
}

- (void)subscribeToUserChannelWithCompletion:(void (^)(NSError *error))completion
{
    if (subscribedUserChannel) {
        // Already subscribed. Do nothing except to call the completion handler.
        if (completion) {
            completion(nil);
        }
        return;
    }

    [self fetchOrCreateUserChannelWithCompletion:^(SKYUserChannel *userChannel, NSError *error) {
        if (error || !userChannel) {
            if (completion) {
                if (!error) {
                    error = [NSError errorWithDomain:SKYOperationErrorDomain
                                                code:SKYErrorResourceNotFound
                                            userInfo:nil];
                }
                completion(error);
            }
            return;
        }

        self->subscribedUserChannel = userChannel;
        [self.container.pubsub subscribeTo:userChannel.name
                                   handler:^(NSDictionary *data) {
                                       [self handleUserChannelDictionary:data];
                                   }];

        if (completion) {
            completion(nil);
        }
    }];
}

- (void)unsubscribeFromUserChannel
{
    if (subscribedUserChannel) {
        [self.container.pubsub unsubscribe:subscribedUserChannel.name];
        subscribedUserChannel = nil;
    }
}

- (id)subscribeToTypingIndicatorInConversation:(SKYConversation *)conversation
                                       handler:(void (^)(SKYChatTypingIndicator *indicator))handler
{
    if (!handler) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:@"must have handler"
                                     userInfo:nil];
    }

    [self subscribeToUserChannelWithCompletion:nil];

    NSString *conversationID = [conversation recordName];
    return [[NSNotificationCenter defaultCenter]
        addObserverForName:SKYChatDidReceiveTypingIndicatorNotification
                    object:self
                     queue:[NSOperationQueue mainQueue]
                usingBlock:^(NSNotification *_Nonnull note) {
                    SKYChatTypingIndicator *indicator =
                        [note.userInfo objectForKey:SKYChatTypingIndicatorUserInfoKey];
                    if ([indicator.conversationID isEqualToString:conversationID]) {
                        handler(indicator);
                    }
                }];
}

- (id)subscribeToMessagesInConversation:(SKYConversation *)conversation
                                handler:(void (^)(SKYChatRecordChangeEvent event,
                                                  SKYMessage *record))handler
{
    if (!handler) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:@"must have handler"
                                     userInfo:nil];
    }

    [self subscribeToUserChannelWithCompletion:nil];

    SKYRecordID *conversationID = [conversation recordID];
    return [[NSNotificationCenter defaultCenter]
        addObserverForName:SKYChatDidReceiveRecordChangeNotification
                    object:self
                     queue:[NSOperationQueue mainQueue]
                usingBlock:^(NSNotification *_Nonnull note) {
                    SKYChatRecordChange *recordChange =
                        [note.userInfo objectForKey:SKYChatRecordChangeUserInfoKey];
                    if (![recordChange.recordType isEqualToString:@"message"]) {
                        return;
                    }

                    SKYReference *ref = recordChange.record[@"conversation"];
                    if (![ref isKindOfClass:[SKYReference class]]) {
                        return;
                    }

                    if (![ref.recordID isEqualToRecordID:conversationID]) {
                        return;
                    }

                    handler(recordChange.event,
                            [[SKYMessage alloc] initWithRecordData:recordChange.record]);
                }];
}

- (id _Nonnull)subscribeToConversation:
    (void (^_Nonnull)(SKYChatRecordChangeEvent event,
                      SKYConversation *_Nonnull conversation))handler
{
    [self subscribeToUserChannelWithCompletion:nil];

    return [[NSNotificationCenter defaultCenter]
        addObserverForName:SKYChatDidReceiveRecordChangeNotification
                    object:self
                     queue:[NSOperationQueue mainQueue]
                usingBlock:^(NSNotification *_Nonnull note) {
                    SKYChatRecordChange *recordChange =
                        [note.userInfo objectForKey:SKYChatRecordChangeUserInfoKey];
                    if (![recordChange.recordType isEqualToString:@"conversation"]) {
                        return;
                    }
                    NSLog(@"Got conversation");

                    handler(recordChange.event,
                            [SKYConversation recordWithRecord:recordChange.record]);
                }];
}

- (void)unsubscribeToConversationWithObserver:(id _Nonnull)observer
{
    [[NSNotificationCenter defaultCenter] removeObserver:observer
                                                    name:SKYChatDidReceiveRecordChangeNotification
                                                  object:self];
}

- (void)unsubscribeToMessagesWithObserver:(id _Nonnull)observer
{
    [[NSNotificationCenter defaultCenter] removeObserver:observer
                                                    name:SKYChatDidReceiveRecordChangeNotification
                                                  object:self];
}

- (void)unsubscribeToTypingIndicatorWithObserver:(id _Nonnull)observer
{
    [[NSNotificationCenter defaultCenter]
        removeObserver:observer
                  name:SKYChatDidReceiveTypingIndicatorNotification
                object:self];
}
@end
