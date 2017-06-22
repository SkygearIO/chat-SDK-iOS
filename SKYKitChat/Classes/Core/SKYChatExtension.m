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
#import "SKYConversation_Private.h"
#import "SKYMessage.h"
#import "SKYPubsub.h"
#import "SKYReference.h"
#import "SKYUserChannel.h"
#import "SKYUserConversation.h"

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
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:notificationObserver];
}

#pragma mark - Conversations

- (void)fetchDistinctConversationWithParticipantIDs:(NSArray<NSString *> *)participantIDs
                                         completion:(SKYChatConversationCompletion)completion
{
    NSMutableArray *predicates = [NSMutableArray array];
    [predicates addObject:[NSPredicate predicateWithFormat:@"distinct_by_participants = %@", @YES]];
    for (NSString *participantID in participantIDs) {
        [predicates
            addObject:[NSPredicate predicateWithFormat:@"%@ in participant_ids", participantID]];
    }
    [predicates addObject:[NSPredicate predicateWithFormat:@"participant_count = %@",
                                                           @(participantIDs.count)]];
    NSPredicate *pred = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];

    SKYQuery *query = [SKYQuery queryWithRecordType:@"conversation" predicate:pred];
    query.limit = 1;

    SKYDatabase *database = self.container.publicCloudDatabase;
    [database performQuery:query
         completionHandler:^(NSArray *results, NSError *error) {
             if (!completion) {
                 return;
             } else if (error) {
                 completion(nil, error);
             } else if (results.count == 0) {
                 completion(nil, nil);
             } else {

                 SKYConversation *con = [SKYConversation recordWithRecord:results.firstObject
                                                          withUnreadCount:0
                                                    withLastReadMessageId:nil];
                 completion(con, nil);
             }
         }];
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

- (void)createConversationWithParticipantIDs:(NSArray<NSString *> *)participantIDs
                                       title:(NSString *)title
                                    metadata:(NSDictionary<NSString *, id> *)metadata
                                    adminIDs:(NSArray<NSString *> *)adminIDs
                      distinctByParticipants:(BOOL)distinctByParticipants
                                  completion:(SKYChatConversationCompletion)completion
{
    if (!participantIDs || participantIDs.count == 0) {
        if (completion) {
            completion(nil,
                       [NSError errorWithDomain:@"SKYChatExtension"
                                           code:0
                                       userInfo:@{
                                           NSLocalizedDescriptionKey :
                                               @"cannot create conversation with no participants"
                                       }]);
        }
        return;
    }

    if (![participantIDs containsObject:self.container.currentUserRecordID]) {
        participantIDs = [participantIDs arrayByAddingObject:self.container.currentUserRecordID];
    }
    participantIDs = [[NSSet setWithArray:participantIDs] allObjects];

    if (!adminIDs || adminIDs.count == 0) {
        adminIDs = [participantIDs copy];
    } else if (![adminIDs containsObject:self.container.currentUserRecordID]) {
        adminIDs = [adminIDs arrayByAddingObject:self.container.currentUserRecordID];
    }
    adminIDs = [[NSSet setWithArray:adminIDs] allObjects];

    SKYConversation *newConversation =
        [SKYConversation recordWithRecord:[SKYRecord recordWithRecordType:@"conversation"]
                          withUnreadCount:0
                    withLastReadMessageId:nil];

    newConversation.title = title;
    newConversation.participantIds = participantIDs;
    newConversation.adminIds = adminIDs;
    newConversation.metadata = metadata;
    newConversation.distinctByParticipants = distinctByParticipants;

    if (!distinctByParticipants) {
        // When distinctByParticipants is NO, we do not need to look for exisitng conversation first
        // as a new one will be created.
        [self saveConversation:newConversation completeWithConversation:completion];
        return;
    }

    [self
        fetchDistinctConversationWithParticipantIDs:participantIDs
                                         completion:^(SKYConversation *conversation,
                                                      NSError *error) {
                                             if (!completion) {
                                                 return;
                                             }

                                             if (error) {
                                                 completion(nil, error);
                                                 return;
                                             }

                                             if (conversation) {
                                                 [self
                                                     fetchConversationWithConversation:conversation
                                                                      fetchLastMessage:NO
                                                                            completion:completion];
                                             } else {
                                                 [self saveConversation:newConversation
                                                     completeWithConversation:completion];
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
    [self.container.publicCloudDatabase
        saveRecord:conversation.record
        completion:^(SKYRecord *record, NSError *error) {
            if (!completion) {
                return;
            }

            if (error) {
                completion(nil, error);
            }

            SKYConversation *newConversation =
                [SKYConversation recordWithRecord:record
                                  withUnreadCount:conversation.unreadCount
                            withLastReadMessageId:conversation.lastReadMessageID];
            completion(newConversation, error);
        }];
}

- (void)saveConversation:(SKYConversation *)conversation
    completeWithConversation:(SKYChatConversationCompletion)completion
{
    [self saveConversation:conversation
                completion:^(SKYConversation *_Nullable conversation, NSError *_Nullable error) {
                    if (!completion) {
                        return;
                    }

                    if (error) {
                        completion(nil, error);
                    }

                    if (conversation) {
                        [self fetchConversationWithConversation:conversation
                                               fetchLastMessage:NO
                                                     completion:completion];
                    }
                }];
}

#pragma mark Fetching Conversations

- (void)fetchConversationsWithQuery:(SKYQuery *)query
                   fetchLastMessage:(BOOL)fetchLastMessage
                         completion:(SKYChatFetchConversationListCompletion)completion
{
    [self fetchUserConversationsWithQuery:query
                         fetchLastMessage:fetchLastMessage
                               completion:^(
                                   NSArray<SKYUserConversation *> *_Nullable userConversations,
                                   NSError *_Nullable error) {
                                   if (userConversations) {
                                       NSMutableArray<SKYConversation *> *conversations =
                                           [[NSMutableArray alloc] init];
                                       for (SKYUserConversation *uc in userConversations) {
                                           [conversations addObject:uc.conversation];
                                       }
                                       completion(conversations, error);
                                   } else {
                                       completion(nil, error);
                                   }
                               }];
}

- (void)fetchConversationsWithCompletion:(SKYChatFetchConversationListCompletion)completion
{
    [self fetchConversationsWithFetchLastMessage:YES page:1 pageSize:50 completion:completion];
}

- (void)fetchConversationsWithFetchLastMessage:(BOOL)fetchLastMessage
                                          page:(NSInteger)page
                                      pageSize:(NSInteger)pageSize
                                    completion:(SKYChatFetchConversationListCompletion)completion
{
    NSPredicate *predicate =
        [NSPredicate predicateWithFormat:@"user = %@", self.container.currentUserRecordID];
    SKYQuery *query = [SKYQuery queryWithRecordType:@"user_conversation" predicate:predicate];
    query.limit = pageSize;
    query.offset = (page - 1) * pageSize;
    query.sortDescriptors =
        @[ [NSSortDescriptor sortDescriptorWithKey:@"_updated_at" ascending:NO] ];
    [self fetchConversationsWithQuery:query
                     fetchLastMessage:fetchLastMessage
                           completion:completion];
}

- (void)fetchConversationWithConversationID:(NSString *)conversationId
                           fetchLastMessage:(BOOL)fetchLastMessage
                                 completion:(SKYChatConversationCompletion)completion
{
    NSPredicate *pred =
        [NSPredicate predicateWithFormat:@"user = %@ AND conversation = %@",
                                         self.container.currentUserRecordID, conversationId];
    SKYQuery *query = [SKYQuery queryWithRecordType:@"user_conversation" predicate:pred];
    query.limit = 1;
    [self fetchConversationsWithQuery:query
                     fetchLastMessage:fetchLastMessage
                           completion:^(NSArray<SKYConversation *> *conversationList,
                                        NSError *error) {
                               if (!completion) {
                                   return;
                               }

                               if (!conversationList.count) {
                                   NSError *error =
                                       [NSError errorWithDomain:SKYOperationErrorDomain
                                                           code:SKYErrorResourceNotFound
                                                       userInfo:nil];
                                   completion(nil, error);
                                   return;
                               }

                               SKYConversation *con = conversationList.firstObject;
                               completion(con, nil);
                           }];
}

- (void)fetchConversationWithConversation:(SKYConversation *)conversation
                         fetchLastMessage:(BOOL)fetchLastMessage
                               completion:(SKYChatConversationCompletion)completion
{
    [self fetchConversationWithConversationID:[conversation recordName]
                             fetchLastMessage:fetchLastMessage
                                   completion:completion];
}

- (void)fetchMessagesWithIDs:(NSArray<NSString *> *)messageIDs
                  completion:(SKYChatFetchMessagesListCompletion)completion
{
    [self.container callLambda:@"chat:get_messages_by_ids"
                     arguments:@[ messageIDs ]
             completionHandler:^(NSDictionary *response, NSError *error) {
                 if (error) {
                     NSLog(@"error calling chat:get_messages_by_ids: %@", error);
                     if (completion) {
                         completion(nil, error);
                     }
                     return;
                 }
                 NSLog(@"Received response = %@", response);
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
                 if (completion) {
                     completion(returnArray, error);
                 }
             }];
}

#pragma mark Conversation Memberships

- (void)addParticipantsWithUserIDs:(NSArray<NSString *> *)userIDs
                    toConversation:(SKYConversation *)conversation
                        completion:(SKYChatConversationCompletion)completion
{
    [conversation addParticipantsWithUserIDs:userIDs];
    [self saveConversation:conversation completion:completion];
}

- (void)removeParticipantsWithUserIDs:(NSArray<NSString *> *)userIDs
                     fromConversation:(SKYConversation *)conversation
                           completion:(SKYChatConversationCompletion)completion
{
    [conversation removeParticipantsWithUserIDs:userIDs];
    [self saveConversation:conversation completion:completion];
}

- (void)addAdminsWithUserIDs:(NSArray<NSString *> *)userIDs
              toConversation:(SKYConversation *)conversation
                  completion:(SKYChatConversationCompletion)completion
{
    [conversation addAdminsWithUserIDs:userIDs];
    [self saveConversation:conversation completion:completion];
}

- (void)removeAdminsWithUserIDs:(NSArray<NSString *> *)userIDs
               fromConversation:(SKYConversation *)conversation
                     completion:(SKYChatConversationCompletion)completion
{
    [conversation removeAdminsWithUserIDs:userIDs];
    [self saveConversation:conversation completion:completion];
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
    SKYDatabase *database = self.container.privateCloudDatabase;
    [database saveRecord:message.record
              completion:^(SKYRecord *record, NSError *error) {
                  SKYMessage *msg = nil;
                  if (error) {
                      message.alreadySyncToServer = false;
                      message.fail = true;
                  } else {
                      msg = [[SKYMessage alloc] initWithRecordData:record];
                      msg.alreadySyncToServer = true;
                      msg.fail = false;
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
    message.conversationID = [conversation recordName];
    if (!message.attachment || message.attachment.url.isFileURL) {
        [self saveMessage:message completion:completion];
        return;
    }

    [self.container uploadAsset:message.attachment
              completionHandler:^(SKYAsset *uploadedAsset, NSError *error) {
                  if (error) {
                      NSLog(@"error uploading asset: %@", error);

                      // NOTE(cheungpat): No idea why we should save message when upload asset
                      // has failed, but this is the existing behavior.
                  } else {
                      message.attachment = uploadedAsset;
                  }
                  [self saveMessage:message completion:completion];
              }];
}

- (void)fetchMessagesWithConversation:(SKYConversation *)conversation
                                limit:(NSInteger)limit
                           beforeTime:(NSDate *)beforeTime
                           completion:(SKYChatFetchMessagesListCompletion)completion
{
    [self fetchMessagesWithConversationID:conversation.recordID.recordName
                                    limit:limit
                               beforeTime:beforeTime
                               completion:completion];
}

- (void)fetchMessagesWithConversationID:(NSString *)conversationId
                                  limit:(NSInteger)limit
                             beforeTime:(NSDate *)beforeTime
                             completion:(SKYChatFetchMessagesListCompletion)completion
{

    NSMutableArray *arguments = [NSMutableArray arrayWithObjects:conversationId, @(limit), nil];
    if (beforeTime) {
        NSString *dateString = [SKYDataSerialization stringFromDate:beforeTime];
        NSLog(@"dateString :%@", dateString);

        [arguments addObject:dateString];
    }

    [self.container callLambda:@"chat:get_messages"
                     arguments:arguments
             completionHandler:^(NSDictionary *response, NSError *error) {
                 if (error) {
                     NSLog(@"error calling chat:get_messages: %@", error);
                     if (completion) {
                         completion(nil, error);
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
                 if (completion) {
                     completion(returnArray, error);
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
                 if (!completion) {
                     return;
                 }
                 if (error) {
                     completion(nil, error);
                 } else {
                     completion(conversation, nil);
                 }

             }];
}

#pragma mark Fetching User Conversations

- (void)fetchUserConversationsWithQuery:(SKYQuery *)query
                       fetchLastMessage:(BOOL)fetchLastMessage
                             completion:(SKYChatFetchUserConversationListCompletion)completion
{
    query.transientIncludes = @{
        @"conversation" : [NSExpression expressionForKeyPath:@"conversation"],
        @"user" : [NSExpression expressionForKeyPath:@"user"]
    };

    SKYDatabase *database = self.container.publicCloudDatabase;
    [database
             performQuery:query
        completionHandler:^(NSArray *results, NSError *error) {
            NSMutableArray<SKYUserConversation *> *resultArray = [[NSMutableArray alloc] init];
            NSMutableSet<NSString *> *messageIDs = [[NSMutableSet alloc] init];
            for (SKYRecord *record in results) {
                SKYUserConversation *uc = [[SKYUserConversation alloc] initWithRecordData:record];
                SKYConversation *c = uc.conversation;
                c.lastReadMessageID = uc.lastReadMessageID;
                c.unreadCount = uc.unreadCount;
                [resultArray addObject:uc];
                NSString *lastMessageRecordID = [c lastMessageID];
                NSString *lastReadMessageRecordID = [c lastReadMessageID];
                if (lastMessageRecordID) {
                    [messageIDs addObject:lastMessageRecordID];
                }
                if (lastReadMessageRecordID) {
                    [messageIDs addObject:lastReadMessageRecordID];
                }
            }
            if (!fetchLastMessage || ![messageIDs count]) {
                if (completion) {
                    completion(resultArray, error);
                }
                return;
            }
            [self
                fetchMessagesWithIDs:[messageIDs allObjects]
                          completion:^(NSArray<SKYMessage *> *_Nullable messageList,
                                       NSError *_Nullable error) {
                              NSMutableDictionary *idToMessage =
                                  [NSMutableDictionary dictionaryWithCapacity:messageList.count];
                              for (SKYMessage *message in messageList) {
                                  idToMessage[message.recordID.recordName] = message;
                              }
                              for (SKYUserConversation *uc in resultArray) {
                                  SKYConversation *con = [uc conversation];

                                  NSString *lastMessageRecordID = [con lastMessageID];
                                  NSString *lastReadMessageRecordID = [con lastReadMessageID];

                                  if (lastMessageRecordID) {
                                      [con setLastMessage:idToMessage[lastMessageRecordID]];
                                  }

                                  if (lastReadMessageRecordID) {
                                      [con setLastReadMessage:idToMessage[lastReadMessageRecordID]];
                                  }
                              }
                              if (completion) {
                                  completion(resultArray, error);
                              }
                          }];
        }];
}

#pragma mark Message Markers

- (void)markLastReadMessage:(SKYMessage *)message
             inConversation:(SKYConversation *)conversation
                 completion:(SKYChatConversationCompletion)completion
{
    conversation.lastReadMessageID = message.recordID.recordName;
    conversation.lastReadMessage = message;

    NSPredicate *pred = [NSPredicate predicateWithFormat:@"user = %@ AND conversation = %@",
                                                         self.container.currentUserRecordID,
                                                         conversation.recordID.recordName];
    SKYQuery *query = [SKYQuery queryWithRecordType:@"user_conversation" predicate:pred];
    query.limit = 1;

    [self
        fetchUserConversationsWithQuery:query
                       fetchLastMessage:true
                             completion:^(
                                 NSArray<SKYUserConversation *> *_Nullable userConversations,
                                 NSError *_Nullable error) {
                                 if (completion) {
                                     if (userConversations.count) {
                                         SKYDatabase *database = self.container.publicCloudDatabase;
                                         SKYUserConversation *userConversation =
                                             userConversations.firstObject;
                                         userConversation.lastReadMessageID =
                                             conversation.lastReadMessageID;
                                         [database saveRecord:userConversation.record
                                                   completion:^(SKYRecord *record, NSError *error) {
                                                       if (completion) {
                                                           if (error) {
                                                               completion(nil, error);
                                                           } else {
                                                               completion(conversation, nil);
                                                           }
                                                       }
                                                   }];
                                     }
                                 }

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
        [self.container.pubsubClient subscribeTo:userChannel.name
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
        [self.container.pubsubClient unsubscribe:subscribedUserChannel.name];
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
                            [SKYConversation recordWithRecord:recordChange.record
                                              withUnreadCount:0
                                        withLastReadMessageId:nil]);
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
