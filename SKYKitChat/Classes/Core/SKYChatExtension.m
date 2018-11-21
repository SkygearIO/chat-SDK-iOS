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
#import "SKYParticipant.h"
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
    BOOL isFetchingUserChannel;
    NSMutableArray<SKYChatChannelCompletion> *fetchOrCreateUserChannelCompletions;
}

- (instancetype)initWithContainer:(SKYContainer *)container
                  cacheController:(SKYChatCacheController *)cacheController
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
                        object:container.auth
                         queue:[NSOperationQueue mainQueue]
                    usingBlock:^(NSNotification *note) {
                        if (container.auth.currentUser != nil) {
                            return;
                        }
                        // Unsubscribe because the current user has changed. We do not
                        // want the UI to keep notified for changes intended for previous user.
                        [self unsubscribeFromUserChannel];

                        // cleanup fetchOrCreateUserChannelCompletions if needed when user logout
                        NSError *error = [NSError
                            errorWithDomain:@"SKYChatExtension"
                                       code:0
                                   userInfo:@{NSLocalizedDescriptionKey : @"user logged out"}];
                        [self handleFetchOrCreateUserChannelCompletionWithUserChannel:nil
                                                                                error:error];
                    }];

        _cacheController = cacheController;
        fetchOrCreateUserChannelCompletions = [NSMutableArray array];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:notificationObserver];
}

#pragma mark - Conversations

- (void)createConversationWithParticipants:(NSArray<SKYParticipant *> *)participants
                                     title:(NSString *)title
                                  metadata:(NSDictionary<NSString *, id> *)metadata
                                completion:(SKYChatConversationCompletion)completion
{
    [self createConversationWithParticipants:participants
                                       title:title
                                    metadata:metadata
                                      admins:nil
                      distinctByParticipants:NO
                                  completion:completion];
}

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

- (void)createConversationWithParticipants:(NSArray<SKYParticipant *> *)participants
                                     title:(NSString *)title
                                  metadata:(NSDictionary<NSString *, id> *)metadata
                                    admins:(NSArray<SKYParticipant *> *)admins
                    distinctByParticipants:(BOOL)distinctByParticipants
                                completion:(SKYChatConversationCompletion)completion
{
    NSMutableArray<NSString *> *participantIDs = [self participantIDsFromParticipants:participants];

    NSMutableArray<NSString *> *adminIDs = nil;
    if (admins) {
        adminIDs = [self participantIDsFromParticipants:admins];
    }

    [self createConversationWithParticipantIDs:participantIDs
                                         title:title
                                      metadata:metadata
                                      adminIDs:adminIDs
                        distinctByParticipants:distinctByParticipants
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

- (void)createDirectConversationWithParticipant:(SKYParticipant *)participant
                                          title:(NSString *)title
                                       metadata:(NSDictionary<NSString *, id> *)metadata
                                     completion:(SKYChatConversationCompletion)completion
{
    [self createDirectConversationWithParticipantID:participant.recordName
                                              title:title
                                           metadata:metadata
                                         completion:completion];
}

- (void)createDirectConversationWithParticipantID:(NSString *)participantID
                                            title:(NSString *)title
                                         metadata:(NSDictionary<NSString *, id> *)metadata
                                       completion:(SKYChatConversationCompletion)completion
{
    [self createConversationWithParticipantIDs:@[ participantID ]
                                         title:title
                                      metadata:metadata
                                      adminIDs:nil
                        distinctByParticipants:YES
                                    completion:completion];
}

- (void)saveConversation:(SKYConversation *)conversation
              completion:(SKYChatConversationCompletion)completion
{
    [self.container.publicCloudDatabase saveRecord:conversation.recordForSave
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
    [self fetchConversationsWithPage:1 pageSize:50 fetchLastMessage:TRUE completion:completion];
}

- (void)fetchConversationsWithFetchLastMessage:(BOOL)fetchLastMessage
                                    completion:(SKYChatFetchConversationListCompletion)completion
{
    [self fetchConversationsWithPage:1
                            pageSize:50
                    fetchLastMessage:fetchLastMessage
                          completion:completion];
}

- (void)fetchConversationsWithPage:(NSInteger)page
                          pageSize:(NSInteger)pageSize
                  fetchLastMessage:(BOOL)fetchLastMessage
                        completion:(SKYChatFetchConversationListCompletion)completion
{
    [self.container callLambda:@"chat:get_conversations"
        dictionaryArguments:@{
            @"page" : @(page),
            @"page_size" : @(pageSize),
            @"include_last_message" : [NSNumber numberWithBool:fetchLastMessage]
        }
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

- (void)fetchParticipants:(NSArray<NSString *> *)participantIDs
               completion:(SKYChatFetchParticpantsCompletion _Nullable)completion
{
    if (participantIDs.count == 0) {
        if (completion) {
            completion(@{}, NO, nil);
        }
        return;
    }

    [self.cacheController fetchParticipants:participantIDs completion:completion];

    SKYQuery *userQuery = [[SKYQuery alloc]
        initWithRecordType:@"user"
                 predicate:[NSPredicate predicateWithFormat:@"_id IN %@", participantIDs]];
    [userQuery setLimit:participantIDs.count];

    [self.container.publicCloudDatabase
             performQuery:userQuery
        completionHandler:^(NSArray *_Nullable results, NSError *_Nullable error) {
            NSMutableDictionary<NSString *, SKYParticipant *> *participantMap = [@{} mutableCopy];
            if (error) {
                if (completion) {
                    completion(participantMap, NO, error);
                }
                return;
            }

            [results
                enumerateObjectsUsingBlock:^(SKYRecord *eachRecord, NSUInteger idx, BOOL *stop) {
                    SKYParticipant *eachParticipant =
                        [[SKYParticipant alloc] initWithRecordData:eachRecord];
                    [participantMap setObject:eachParticipant forKey:eachParticipant.recordName];
                }];

            [self.cacheController didFetchParticipants:participantMap.allValues];

            if (completion) {
                completion(participantMap, NO, nil);
            }
        }];
}

- (void)updateMembershipsWithLambda:(NSString *)lambda
                     participantIDs:(NSArray<NSString *> *)participantIDs
                     toConversation:(SKYConversation *)conversation
                         completion:(SKYChatConversationCompletion)completion
{
    [self.container callLambda:lambda
                     arguments:@[ conversation.recordID.recordName, participantIDs ]
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

- (void)addParticipantsWithIDs:(NSArray<NSString *> *)participantIDs
                toConversation:(SKYConversation *)conversation
                    completion:(SKYChatConversationCompletion)completion
{
    [self updateMembershipsWithLambda:@"chat:add_participants"
                       participantIDs:participantIDs
                       toConversation:conversation
                           completion:completion];
}

- (void)addParticipants:(NSArray<SKYParticipant *> *)participants
         toConversation:(SKYConversation *)conversation
             completion:(SKYChatConversationCompletion)completion
{
    NSArray<NSString *> *participantIDs = [self participantIDsFromParticipants:participants];
    [self addParticipantsWithIDs:participantIDs toConversation:conversation completion:completion];
}

- (void)removeParticipantsWithIDs:(NSArray<NSString *> *)participantIDs
                 fromConversation:(SKYConversation *)conversation
                       completion:(SKYChatConversationCompletion)completion
{
    [self updateMembershipsWithLambda:@"chat:remove_participants"
                       participantIDs:participantIDs
                       toConversation:conversation
                           completion:completion];
}

- (void)removeParticipants:(NSArray<SKYParticipant *> *)participants
          fromConversation:(SKYConversation *)conversation
                completion:(SKYChatConversationCompletion)completion
{
    NSArray<NSString *> *participantIDs = [self participantIDsFromParticipants:participants];
    [self removeParticipantsWithIDs:participantIDs
                   fromConversation:conversation
                         completion:completion];
}

- (void)addAdminsWithIDs:(NSArray<NSString *> *)adminIDs
          toConversation:(SKYConversation *)conversation
              completion:(SKYChatConversationCompletion)completion
{
    [self updateMembershipsWithLambda:@"chat:add_admins"
                       participantIDs:adminIDs
                       toConversation:conversation
                           completion:completion];
}

- (void)addAdmins:(NSArray<SKYParticipant *> *)admins
    toConversation:(SKYConversation *)conversation
        completion:(SKYChatConversationCompletion)completion
{
    NSArray<NSString *> *adminIDs = [self participantIDsFromParticipants:admins];
    [self addAdminsWithIDs:adminIDs toConversation:conversation completion:completion];
}

- (void)removeAdminsWithIDs:(NSArray<NSString *> *)adminIDs
           fromConversation:(SKYConversation *)conversation
                 completion:(SKYChatConversationCompletion)completion
{
    [self updateMembershipsWithLambda:@"chat:remove_admins"
                       participantIDs:adminIDs
                       toConversation:conversation
                           completion:completion];
}

- (void)removeAdmins:(NSArray<SKYParticipant *> *)admins
    fromConversation:(SKYConversation *)conversation
          completion:(SKYChatConversationCompletion)completion
{
    NSArray<NSString *> *adminIDs = [self participantIDsFromParticipants:admins];
    [self removeAdminsWithIDs:adminIDs fromConversation:conversation completion:completion];
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

- (void)saveMessage:(SKYMessage *)message
      forNewMessage:(BOOL)isNewMessage
         completion:(SKYChatMessageCompletion)completion
{
    SKYMessageOperationType operationType =
        isNewMessage ? SKYMessageOperationTypeAdd : SKYMessageOperationTypeEdit;
    SKYMessageOperation *operation =
        [self.cacheController didStartMessage:message
                               conversationID:message.conversationRef.recordID.recordName
                                operationType:operationType];

    SKYDatabase *database = self.container.publicCloudDatabase;
    [database saveRecord:message.record
              completion:^(SKYRecord *record, NSError *error) {
                  SKYMessage *msg = nil;
                  if (error) {
                      [self.cacheController didFailMessageOperation:operation error:error];
                  } else {
                      msg = [[SKYMessage alloc] initWithRecordData:record];
                      [self.cacheController didSaveMessage:msg];
                      [self.cacheController didCompleteMessageOperation:operation];
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
        [self saveMessage:message forNewMessage:YES completion:completion];
        return;
    }

    [self.container.publicCloudDatabase
              uploadAsset:message.attachment
        completionHandler:^(SKYAsset *uploadedAsset, NSError *error) {
            if (error) {
                NSLog(@"error uploading asset: %@", error);

                // NOTE(cheungpat): No idea why we should save message
                // when upload asset has failed, but this is the existing
                // behavior.
            } else {
                message.attachment = uploadedAsset;
            }
            [self saveMessage:message forNewMessage:YES completion:completion];
        }];
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

- (void)fetchMessagesWithConversation:(SKYConversation *)conversation
                                limit:(NSInteger)limit
                        beforeMessage:(SKYMessage *)beforeMessage
                                order:(NSString *)order
                           completion:(SKYChatFetchMessagesListCompletion)completion
{
    [self fetchMessagesWithConversationID:conversation.recordID.recordName
                                    limit:limit
                          beforeMessageID:beforeMessage.recordID.recordName
                                    order:order
                               completion:completion];
}

- (void)fetchMessagesWithConversation:(SKYConversation *)conversation
                                limit:(NSInteger)limit
                      beforeMessageID:(NSString *)beforeMessageID
                                order:(NSString *)order
                           completion:(SKYChatFetchMessagesListCompletion)completion
{
    [self fetchMessagesWithConversationID:conversation.recordID.recordName
                                    limit:limit
                          beforeMessageID:beforeMessageID
                                    order:order
                               completion:completion];
}

- (void)fetchMessagesWithConversationID:(NSString *)conversationId
                                  limit:(NSInteger)limit
                          beforeMessage:(SKYMessage *)beforeMessage
                                  order:(NSString *)order
                             completion:(SKYChatFetchMessagesListCompletion)completion
{
    [self fetchMessagesWithConversationID:conversationId
                                    limit:limit
                          beforeMessageID:beforeMessage.recordID.recordName
                                    order:order
                               completion:completion];
}

- (void)fetchMessagesWithArguments:(NSDictionary *)arguments
                        completion:(SKYChatFetchMessagesListCompletion)completion
{
    [self.container callLambda:@"chat:get_messages"
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

                 [self.cacheController didFetchMessages:returnArray
                                        deletedMessages:returnDeletedArray];

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

- (void)fetchMessagesWithConversationID:(NSString *)conversationId
                                  limit:(NSInteger)limit
                             beforeTime:(NSDate *)beforeTime
                                  order:(NSString *)order
                             completion:(SKYChatFetchMessagesListCompletion)completion
{

    NSMutableDictionary *arguments = [NSMutableDictionary
        dictionaryWithObjectsAndKeys:conversationId, @"conversation_id", @(limit), @"limit", nil];
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
    [self fetchMessagesWithArguments:arguments completion:completion];
}

- (void)fetchMessagesWithConversationID:(NSString *)conversationId
                                  limit:(NSInteger)limit
                        beforeMessageID:(NSString *)beforeMessageID
                                  order:(NSString *)order
                             completion:(SKYChatFetchMessagesListCompletion)completion
{

    NSMutableDictionary *arguments = [NSMutableDictionary
        dictionaryWithObjectsAndKeys:conversationId, @"conversation_id", @(limit), @"limit", nil];
    if (beforeMessageID) {
        [arguments setObject:beforeMessageID forKey:@"before_message_id"];
    }

    if (order) {
        [arguments setObject:order forKey:@"order"];
    }

    if (completion) {
        [self.cacheController
            fetchMessagesWithConversationID:conversationId
                                      limit:limit
                            beforeMessageID:beforeMessageID
                                      order:order
                                 completion:^(NSArray<SKYMessage *> *_Nullable messageList,
                                              BOOL isCached, NSError *_Nullable error) {
                                     completion(messageList, YES, error);
                                 }];
    }
    [self fetchMessagesWithArguments:arguments completion:completion];
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
    [messages enumerateObjectsUsingBlock:^(SKYMessage *obj, NSUInteger idx, BOOL *stop) {
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
    [messages enumerateObjectsUsingBlock:^(SKYMessage *obj, NSUInteger idx, BOOL *stop) {
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

- (void)editMessage:(SKYMessage *)message
           withBody:(NSString *)body
         completion:(SKYChatMessageCompletion _Nullable)completion
{

    NSLog(@"Edit a message, message ID %@", message.recordID.recordName);
    message.body = body;
    [self saveMessage:message forNewMessage:NO completion:completion];
}

#pragma mark Message Deletion

- (void)deleteMessage:(SKYMessage *)message
       inConversation:(SKYConversation *)conversation
           completion:(SKYChatConversationCompletion _Nullable)completion
{
    SKYMessageOperation *operation =
        [self.cacheController didStartMessage:message
                               conversationID:conversation.recordName
                                operationType:SKYMessageOperationTypeDelete];
    NSLog(@"Delete a message, messageID %@", message.recordID.recordName);
    [self.container callLambda:@"chat:delete_message"
                     arguments:@[ message.recordID.recordName ]
             completionHandler:^(NSDictionary *response, NSError *error) {
                 if (error) {
                     [self.cacheController didFailMessageOperation:operation error:error];
                     if (completion) {
                         completion(nil, error);
                     }

                     return;
                 }

                 SKYRecordDeserializer *deserializer = [SKYRecordDeserializer deserializer];
                 SKYRecord *record = [deserializer recordWithDictionary:[response copy]];
                 SKYMessage *msg = [[SKYMessage alloc] initWithRecordData:record];

                 [self.cacheController didDeleteMessage:msg];
                 [self.cacheController didCompleteMessageOperation:operation];

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

#pragma mark - Message Operations

- (void)fetchOutstandingMessageOperationsWithConverstionID:(NSString *)conversationId
                                             operationType:(SKYMessageOperationType)operationType
                                                completion:
                                                    (SKYMessageOperationListCompletion)completion
{
    [self.cacheController
        fetchMessageOperationsWithConversationID:conversationId
                                   operationType:operationType
                                      completion:^(
                                          NSArray<SKYMessageOperation *> *messageOperationList) {
                                          if (completion) {
                                              completion(messageOperationList);
                                          }
                                      }];
}

- (void)fetchOutstandingMessageOperationsWithMessageID:(NSString *)messageId
                                         operationType:(SKYMessageOperationType)operationType
                                            completion:(SKYMessageOperationListCompletion)completion
{
    [self.cacheController
        fetchMessageOperationsWithMessageID:messageId
                              operationType:operationType
                                 completion:^(
                                     NSArray<SKYMessageOperation *> *messageOperationList) {
                                     if (completion) {
                                         completion(messageOperationList);
                                     }
                                 }];
}

- (void)retryMessageOperation:(SKYMessageOperation *)operation
                   completion:(SKYMessageOperationCompletion)completion
{
    if (operation.status == SKYMessageOperationStatusPending) {
        NSLog(@"Message operation %@ is still pending. Pending operations cannot be retried.",
              operation.operationID);
        return;
    }

    [self.cacheController didCancelMessageOperation:operation];

    switch (operation.type) {
        case SKYMessageOperationTypeAdd:
        case SKYMessageOperationTypeEdit: {
            [self saveMessage:operation.message
                forNewMessage:(operation.type == SKYMessageOperationTypeAdd)
                   completion:^(SKYMessage *message, NSError *error) {
                       if (completion) {
                           completion(operation, message, error);
                       }
                   }];
            break;
        }
        case SKYMessageOperationTypeDelete: {
            [self deleteMessage:operation.message
                 inConversation:[SKYConversation
                                    recordWithRecord:[SKYRecord
                                                         recordWithRecordType:@"conversation"
                                                                         name:operation
                                                                                  .conversationID]]
                     completion:^(SKYConversation *conversation, NSError *error) {
                         if (completion) {
                             completion(operation, nil, error);
                         }
                     }];
            break;
        }
    }
}

- (void)cancelMessageOperation:(SKYMessageOperation *)operation
{
    if (operation.status == SKYMessageOperationStatusPending) {
        NSLog(@"Message operation %@ is still pending. Pending operations cannot be cancelled.",
              operation.operationID);
        return;
    }

    [self.cacheController didCancelMessageOperation:operation];
}

#pragma mark - Subscriptions

- (void)fetchOrCreateUserChannelWithCompletion:(SKYChatChannelCompletion)completion
{
    if (completion) {
        [fetchOrCreateUserChannelCompletions addObject:completion];
    }
    if (isFetchingUserChannel)
        return;

    isFetchingUserChannel = true;
    NSString *_userID = self.container.auth.currentUser.recordID.recordName;
    [self fetchUserChannelWithCompletion:^(SKYUserChannel *_Nullable userChannel,
                                           NSError *_Nullable error) {
        // user logged out
        if (self.container.auth.currentUser == nil ||
            ![self.container.auth.currentUser.recordID.recordName isEqualToString:_userID]) {
            return;
        }

        if (error) {
            [self handleFetchOrCreateUserChannelCompletionWithUserChannel:userChannel error:error];
            return;
        }

        if (!userChannel) {
            [self createUserChannelWithCompletion:^(SKYUserChannel *_Nullable userChannel,
                                                    NSError *_Nullable error) {
                // user logged out
                if (self.container.auth.currentUser == nil ||
                    !
                    [self.container.auth.currentUser.recordID.recordName isEqualToString:_userID]) {
                    return;
                }
                [self handleFetchOrCreateUserChannelCompletionWithUserChannel:userChannel
                                                                        error:error];
            }];
            return;
        }

        [self handleFetchOrCreateUserChannelCompletionWithUserChannel:userChannel error:error];
    }];
}

- (void)handleFetchOrCreateUserChannelCompletionWithUserChannel:(SKYUserChannel *)userChannel
                                                          error:(NSError *)error
{
    for (SKYChatChannelCompletion completion in fetchOrCreateUserChannelCompletions) {
        completion(userChannel, error);
    }

    [fetchOrCreateUserChannelCompletions removeAllObjects];
    isFetchingUserChannel = false;
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
            [results enumerateObjectsUsingBlock:^(SKYRecord *record, NSUInteger idx, BOOL *stop) {
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
                usingBlock:^(NSNotification *note) {
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
                usingBlock:^(NSNotification *note) {
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

- (id)subscribeToConversation:(void (^)(SKYChatRecordChangeEvent event,
                                        SKYConversation *conversation))handler
{
    [self subscribeToUserChannelWithCompletion:nil];

    return [[NSNotificationCenter defaultCenter]
        addObserverForName:SKYChatDidReceiveRecordChangeNotification
                    object:self
                     queue:[NSOperationQueue mainQueue]
                usingBlock:^(NSNotification *note) {
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

- (void)unsubscribeToConversationWithObserver:(id)observer
{
    [[NSNotificationCenter defaultCenter] removeObserver:observer
                                                    name:SKYChatDidReceiveRecordChangeNotification
                                                  object:self];
}

- (void)unsubscribeToMessagesWithObserver:(id)observer
{
    [[NSNotificationCenter defaultCenter] removeObserver:observer
                                                    name:SKYChatDidReceiveRecordChangeNotification
                                                  object:self];
}

- (void)unsubscribeToTypingIndicatorWithObserver:(id)observer
{
    [[NSNotificationCenter defaultCenter]
        removeObserver:observer
                  name:SKYChatDidReceiveTypingIndicatorNotification
                object:self];
}

- (NSArray<NSString *> *)participantIDsFromParticipants:(NSArray<SKYParticipant *> *)participants
{
    NSMutableArray<NSString *> *participantIDs = [@[] mutableCopy];
    [participants
        enumerateObjectsUsingBlock:^(SKYParticipant *eachParticipant, NSUInteger idx, BOOL *stop) {
            [participantIDs addObject:eachParticipant.recordName];
        }];

    return participantIDs;
}

@end
