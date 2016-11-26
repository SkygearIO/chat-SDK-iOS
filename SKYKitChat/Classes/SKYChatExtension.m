//
//  SKYContainer+Chat.m
//  SKYKit
//
//  Copyright 2015 Oursky Ltd.
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

#import "SKYChatExtension.h"

#import <SKYKit/SKYKit.h>

#import "SKYChatReceipt.h"
#import "SKYConversation.h"
#import "SKYMessage.h"
#import "SKYPubsub.h"
#import "SKYReference.h"
#import "SKYUserChannel.h"
#import "SKYUserConversation.h"

NSString *const SKYChatMessageUnreadCountKey = @"message";
NSString *const SKYChatConversationUnreadCountKey = @"conversation";

NSString *const SKYChatMetaDataAssetNameImage = @"message-image";
NSString *const SKYChatMetaDataAssetNameVoice = @"message-voice";
NSString *const SKYChatMetaDataAssetNameText = @"message-text";

@implementation SKYChatExtension

- (instancetype)initWithContainer:(SKYContainer *_Nonnull)container
{
    if ((self = [super init])) {
        if (!container) {
            @throw [NSException exceptionWithName:NSInvalidArgumentException
                                           reason:@"container cannot be null"
                                         userInfo:nil];
        }
        _container = container;
    }
    return self;
}

#pragma mark - Conversations

- (void)fetchDistinctConversationWithParticipantIDs:(NSArray<NSString *> *)participantIDs
                                  completionHandler:(SKYChatConversationCompletion)completionHandler
{
    NSPredicate *pred =
        [NSPredicate predicateWithFormat:@"%@ in participant_ids AND distinct_by_participants = %@",
                                         participantIDs, @YES];

    SKYQuery *query = [SKYQuery queryWithRecordType:@"conversation" predicate:pred];
    query.limit = 1;

    SKYDatabase *database = self.container.publicCloudDatabase;
    [database performQuery:query
         completionHandler:^(NSArray *results, NSError *error) {
             if (!completionHandler) {
                 return;
             }
             if (error) {
                 completionHandler(nil, error);
             } else if (results.count == 0) {
                 completionHandler(nil, nil);
             } else {
                 SKYConversation *con = [SKYConversation recordWithRecord:results.firstObject];
                 completionHandler(con, nil);
             }
         }];
}

- (void)createConversationWithParticipantIDs:(NSArray<NSString *> *)participantIDs
                                       title:(NSString *)title
                                    metadata:(NSDictionary<NSString *, id> *)metadata
                           completionHandler:(SKYChatConversationCompletion)completionHandler
{
    [self createConversationWithParticipantIDs:participantIDs
                                         title:title
                                      metadata:metadata
                                      adminIDs:nil
                        distinctByParticipants:NO
                             completionHandler:completionHandler];
}

- (void)createConversationWithParticipantIDs:(NSArray<NSString *> *)participantIDs
                                       title:(NSString *)title
                                    metadata:(NSDictionary<NSString *, id> *)metadata
                                    adminIDs:(NSArray<NSString *> *)adminIDs
                      distinctByParticipants:(BOOL)distinctByParticipants
                           completionHandler:(SKYChatConversationCompletion)completionHandler
{
    if (!participantIDs || participantIDs.count == 0) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:@"cannot create conversation with no participants"
                                     userInfo:nil];
    }

    if (participantIDs.count == 1 &&
        [participantIDs.firstObject isEqualToString:self.container.currentUserRecordID]) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:@"cannot create conversation with yourself"
                                     userInfo:nil];
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

    SKYConversation *newConversation = [SKYConversation recordWithRecordType:@"conversation"];
    newConversation.participantIds = participantIDs;
    newConversation.adminIds = adminIDs;
    newConversation.metadata = metadata;
    newConversation.distinctByParticipants = distinctByParticipants;
    
    if (!distinctByParticipants) {
        // When distinctByParticipants is NO, we do not need to look for exisitng conversation first
        // as a new one will be created.
        [self saveConversation:newConversation
             completionHandler:completionHandler];
        return;
    }

    [self fetchDistinctConversationWithParticipantIDs:participantIDs
                                    completionHandler:^(SKYConversation *conversation,
                                                        NSError *error) {
                                        if (!completionHandler) {
                                            return;
                                        }

                                        if (conversation || error) {
                                            if (!completionHandler) {
                                                completionHandler(conversation, error);
                                            }
                                        } else {
                                            [self saveConversation:newConversation
                                                 completionHandler:completionHandler];
                                        }
                                    }];
}

- (void)createDirectConversationWithUserID:(NSString *)userID
                                     title:(NSString *)title
                                  metadata:(NSDictionary<NSString *, id> *)metadata
                         completionHandler:(SKYChatConversationCompletion)completionHandler
{
    [self createConversationWithParticipantIDs:@[ userID ]
                                         title:title
                                      metadata:metadata
                                      adminIDs:nil
                        distinctByParticipants:YES
                             completionHandler:completionHandler];
}

- (void)deleteConversation:(SKYConversation *)conversation
         completionHandler:(SKYChatConversationCompletion)completionHandler
{
    [self deleteConversationWithID:conversation.recordID.recordName
                 completionHandler:completionHandler];
}

- (void)deleteConversationWithID:(NSString *)conversationId
               completionHandler:(SKYChatConversationCompletion)completionHandler
{
    SKYRecordID *recordID =
        [SKYRecordID recordIDWithRecordType:@"conversation" name:conversationId];
    [self.container.publicCloudDatabase
        deleteRecordWithID:recordID
         completionHandler:^(SKYRecordID *recordID, NSError *error) {
             if (completionHandler != nil) {
                 completionHandler(nil, error);
             }
         }];
}

- (void)saveConversation:(SKYConversation *)conversation
       completionHandler:(SKYChatConversationCompletion)completionHandler
{
    [self.container.publicCloudDatabase saveRecord:conversation
                                        completion:^(SKYRecord *record, NSError *error) {
                                            SKYConversation *newConversation =
                                                [SKYConversation recordWithRecord:record];
                                            completionHandler(newConversation, error);
                                        }];
}

#pragma mark Fetching User Conversations

- (void)fetchUserConversationsWithQuery:(SKYQuery *)query
                      completionHandler:(SKYChatGetUserConversationListCompletion)completionHandler
{
    query.transientIncludes = @{
        @"conversation" : [NSExpression expressionForKeyPath:@"conversation"],
        @"user" : [NSExpression expressionForKeyPath:@"user"],
        @"last_read_message" : [NSExpression expressionForKeyPath:@"last_read_message"]
    };

    SKYDatabase *database = self.container.publicCloudDatabase;
    [database performQuery:query
         completionHandler:^(NSArray *results, NSError *error) {
             NSMutableArray *resultArray = [[NSMutableArray alloc] init];
             for (SKYRecord *record in results) {
                 NSLog(@"record :%@", [record transient]);
                 SKYUserConversation *con = [SKYUserConversation recordWithRecord:record];
                 [resultArray addObject:con];
             }

             if (completionHandler) {
                 completionHandler(resultArray, error);
             }
         }];
}

- (void)fetchUserConversationsCompletionHandler:
    (SKYChatGetUserConversationListCompletion)completionHandler
{
    NSPredicate *predicate =
        [NSPredicate predicateWithFormat:@"user = %@", self.container.currentUserRecordID];
    SKYQuery *query = [SKYQuery queryWithRecordType:@"user_conversation" predicate:predicate];
    [self fetchUserConversationsWithQuery:query completionHandler:completionHandler];
}

- (void)fetchUserConversationWithID:(NSString *)conversationId
                  completionHandler:(SKYChatUserConversationCompletion)completionHandler
{
    NSPredicate *pred1 =
        [NSPredicate predicateWithFormat:@"user = %@", self.container.currentUserRecordID];
    NSPredicate *pred2 = [NSPredicate predicateWithFormat:@"conversation = %@", conversationId];
    NSCompoundPredicate *predicate =
        [NSCompoundPredicate andPredicateWithSubpredicates:@[ pred1, pred2 ]];
    SKYQuery *query = [SKYQuery queryWithRecordType:@"user_conversation" predicate:predicate];
    query.limit = 1;
    [self fetchUserConversationsWithQuery:query
                        completionHandler:^(NSArray<SKYUserConversation *> *conversationList,
                                            NSError *error) {
                            if (!completionHandler) {
                                return;
                            }

                            if (!conversationList.count) {
                                NSError *error = [NSError errorWithDomain:SKYOperationErrorDomain
                                                                     code:SKYErrorResourceNotFound
                                                                 userInfo:nil];
                                completionHandler(@[], error);
                            }

                            SKYUserConversation *con =
                                [SKYUserConversation recordWithRecord:conversationList.firstObject];
                            completionHandler(con, nil);
                        }];
}

#pragma mark Conversation Memberships

- (void)addParticipantsWithIDs:(NSArray<NSString *> *)participantIDs
                toConversation:(SKYConversation *)conversation
             completionHandler:(SKYChatConversationCompletion)completionHandler
{
    [conversation addParticipantsWithIDs:participantIDs];
    [self saveConversation:conversation completionHandler:completionHandler];
}

- (void)removeParticipantsWithIDs:(NSArray<NSString *> *)participantIDs
                 fromConversation:(SKYConversation *)conversation
                completionHandler:(SKYChatConversationCompletion)completionHandler
{
    [conversation removeParticipantsWithIDs:participantIDs];
    [self saveConversation:conversation completionHandler:completionHandler];
}

- (void)addAdminsWithIDs:(NSArray<NSString *> *)adminIDs
          toConversation:(SKYConversation *)conversation
       completionHandler:(SKYChatConversationCompletion)completionHandler
{
    [conversation addAdminsWithIDs:adminIDs];
    [self saveConversation:conversation completionHandler:completionHandler];
}

- (void)removeAdminsWithIDs:(NSArray<NSString *> *)adminIDs
           fromConversation:(SKYConversation *)conversation
          completionHandler:(SKYChatConversationCompletion)completionHandler
{
    [conversation removeAdminsWithIDs:adminIDs];
    [self saveConversation:conversation completionHandler:completionHandler];
}

#pragma mark - Messages

- (void)createMessageWithConversation:(SKYConversation *)conversation
                                 body:(NSString *)body
                             metadata:(NSDictionary *)metadata
                    completionHandler:(SKYChatMessageCompletion)completionHandler
{
    SKYMessage *message = [SKYMessage message];
    if (body) {
        message.body = body;
    }
    if (metadata) {
        message.metadata = metadata;
    }
    [self addMessage:message toConversation:conversation completionHandler:completionHandler];
}

- (void)createMessageWithConversation:(SKYConversation *)conversation
                                 body:(NSString *)body
                                image:(UIImage *)image
                    completionHandler:(SKYChatMessageCompletion)completionHandler
{
    SKYMessage *message = [SKYMessage recordWithRecordType:@"message"];
    message.body = body;
    NSString *assetName = [self getAssetNameByType:SKYChatMetaDataAssetNameImage];
    NSString *mimeType = [self getMimeTypeByType:SKYChatMetaDataAssetNameImage];
    SKYAsset *asset = [SKYAsset assetWithName:assetName data:UIImageJPEGRepresentation(image, 0.7)];
    asset.mimeType = mimeType;

    [self addMessage:message
                 andAsset:asset
           toConversation:conversation
        completionHandler:completionHandler];
}

- (void)createMessageWithConversation:(SKYConversation *)conversation
                                 body:(NSString *)body
                         voiceFileURL:(NSURL *)url
                             duration:(float)duration
                    completionHandler:(SKYChatMessageCompletion)completionHandler
{
    SKYMessage *message = [SKYMessage recordWithRecordType:@"message"];
    message.body = body;

    NSString *assetName = [self getAssetNameByType:SKYChatMetaDataVoice];
    NSString *mimeType = [self getMimeTypeByType:SKYChatMetaDataVoice];
    assetName = [NSString stringWithFormat:@"%@duration%.1fduration", assetName, duration];
    SKYAsset *asset = [SKYAsset assetWithName:assetName fileURL:url];
    asset.mimeType = mimeType;

    [self addMessage:message
                 andAsset:asset
           toConversation:conversation
        completionHandler:completionHandler];
}

- (void)addMessage:(SKYMessage *)message
       toConversation:(SKYConversation *)conversation
    completionHandler:(SKYChatMessageCompletion)completionHandler
{
    message.conversationID = conversation.recordID.recordName;
    SKYDatabase *database = self.container.publicCloudDatabase;
    [database saveRecord:message
              completion:^(SKYRecord *record, NSError *error) {
                  SKYMessage *msg = nil;
                  if (error) {
                      message.alreadySyncToServer = false;
                      message.fail = true;
                  } else {
                      msg = [SKYMessage recordWithRecord:record];
                      msg.alreadySyncToServer = true;
                      msg.fail = false;
                  }
                  if (completionHandler) {
                      completionHandler(msg, error);
                  }
              }];
}

- (void)addMessage:(SKYMessage *)message
             andAsset:(SKYAsset *)asset
       toConversation:(SKYConversation *)conversation
    completionHandler:(SKYChatMessageCompletion)completionHandler
{
    if (!asset) {
        [self addMessage:message toConversation:conversation completionHandler:completionHandler];
        return;
    }

    [self.container uploadAsset:asset
              completionHandler:^(SKYAsset *uploadedAsset, NSError *error) {
                  if (error) {
                      NSLog(@"error uploading asset: %@", error);

                      // NOTE(cheungpat): No idea why we should save message when upload asset
                      // has failed, but this is the existing behavior.
                  } else {
                      message.attachment = uploadedAsset;
                  }
                  [self addMessage:message
                         toConversation:conversation
                      completionHandler:completionHandler];
              }];
}

- (void)deleteMessage:(SKYMessage *)message
    completionHandler:(SKYChatMessageCompletion)completionHandler
{
    [self deleteMessageWithID:message.recordID.recordName completionHandler:completionHandler];
}

- (void)deleteMessageWithID:(NSString *)messageID
          completionHandler:(SKYChatMessageCompletion)completionHandler
{
    SKYRecordID *recordID = [SKYRecordID recordIDWithRecordType:@"message" name:messageID];
    [self.container.publicCloudDatabase
        deleteRecordWithID:recordID
         completionHandler:^(SKYRecordID *recordID, NSError *error) {
             if (completionHandler != nil) {
                 completionHandler(nil, error);
             }
         }];
}

- (void)fetchMessagesWithConversation:(SKYConversation *)conversation
                                limit:(NSInteger)limit
                           beforeTime:(NSDate *)beforeTime
                    completionHandler:(SKYChatGetMessagesListCompletion)completionHandler
{
    [self fetchMessagesWithConversationID:conversation.recordID.recordName
                                    limit:limit
                               beforeTime:beforeTime
                        completionHandler:completionHandler];
}

- (void)fetchMessagesWithConversationID:(NSString *)conversationId
                                  limit:(NSInteger)limit
                             beforeTime:(NSDate *)beforeTime
                      completionHandler:(SKYChatGetMessagesListCompletion)completionHandler
{
    NSString *dateString = @"";
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ"];
    dateString = [formatter stringFromDate:beforeTime];
    NSLog(@"dateString :%@", dateString);
    [self.container callLambda:@"chat:get_messages"
                     arguments:@[ conversationId, @(limit), dateString ]
             completionHandler:^(NSDictionary *response, NSError *error) {
                 if (error) {
                     NSLog(@"error calling hello:someone: %@", error);
                 }
                 NSLog(@"Received response = %@", response);
                 NSArray *resultArray = [response objectForKey:@"results"];
                 if (resultArray.count > 0) {
                     NSMutableArray *returnArray = [[NSMutableArray alloc] init];
                     for (NSDictionary *obj in resultArray) {
                         SKYRecordDeserializer *deserializer = [SKYRecordDeserializer deserializer];
                         SKYRecord *record = [deserializer recordWithDictionary:[obj copy]];

                         SKYMessage *msg = [SKYMessage recordWithRecord:record];
                         msg.alreadySyncToServer = true;
                         msg.fail = false;
                         if (msg) {
                             [returnArray addObject:msg];
                         }
                     }
                     completionHandler(returnArray, error);
                 } else {
                     completionHandler(nil, error);
                 }

             }];
}

#pragma mark Delivery and Read Status

- (void)callLambda:(NSString *)lambda
           messageIDs:(NSArray<NSString *> *)messageIDs
    completionHandler:(void (^)(NSError *error))completionHandler
{
    [self.container callLambda:lambda
                     arguments:messageIDs
             completionHandler:^(NSDictionary *dict, NSError *error) {
                 if (completionHandler) {
                     completionHandler(error);
                 }
             }];
}

- (void)markReadMessages:(NSArray<SKYMessage *> *)messages
       completionHandler:(void (^)(NSError *error))completionHandler
{
    NSMutableArray *recordIDs = [NSMutableArray array];
    [messages enumerateObjectsUsingBlock:^(SKYMessage *_Nonnull obj, NSUInteger idx,
                                           BOOL *_Nonnull stop) {
        [recordIDs addObject:obj.recordID.recordName];
    }];
    [self callLambda:@"chat:mark_as_read" messageIDs:recordIDs completionHandler:completionHandler];
}

- (void)markReadMessagesWithID:(NSArray<NSString *> *)messageIDs
             completionHandler:(void (^)(NSError *error))completionHandler
{
    [self callLambda:@"chat:mark_as_read"
               messageIDs:messageIDs
        completionHandler:completionHandler];
}

- (void)markDeliveredMessages:(NSArray<SKYMessage *> *)messages
            completionHandler:(void (^)(NSError *error))completionHandler
{
    NSMutableArray *recordIDs = [NSMutableArray array];
    [messages enumerateObjectsUsingBlock:^(SKYMessage *_Nonnull obj, NSUInteger idx,
                                           BOOL *_Nonnull stop) {
        [recordIDs addObject:obj.recordID.recordName];
    }];
    [self callLambda:@"chat:mark_as_delivered"
               messageIDs:recordIDs
        completionHandler:completionHandler];
}

- (void)markDeliveredMessagesWithID:(NSArray<NSString *> *)messageIDs
                  completionHandler:(void (^)(NSError *error))completionHandler
{
    [self callLambda:@"chat:mark_as_delivered"
               messageIDs:messageIDs
        completionHandler:completionHandler];
}

- (void)fetchReceiptsWithMessage:(SKYMessage *)message
               completionHandler:
                   (void (^)(NSArray<SKYChatReceipt *> *, NSError *error))completionHandler
{
    [self.container callLambda:@"chat:get_receipt"
                     arguments:message.recordID.recordName
             completionHandler:^(NSDictionary *dict, NSError *error) {
                 if (!completionHandler) {
                     return;
                 }
                 if (error) {
                     completionHandler(nil, error);
                 }

                 NSMutableArray *receipts = [NSMutableArray array];
                 for (NSDictionary *receiptDict in dict[@"receipts"]) {
                     SKYChatReceipt *receipt =
                         [[SKYChatReceipt alloc] initWithReceiptDictionary:receiptDict];
                     [receipts addObject:receipt];
                 }

                 completionHandler(receipts, nil);
             }];
}

#pragma mark Message Markers

- (void)markLastReadMessage:(SKYMessage *)message
         inUserConversation:(SKYUserConversation *)userConversation
          completionHandler:(SKYChatUserConversationCompletion)completionHandler
{
    userConversation.lastReadMessageID = [SKYReference referenceWithRecord:message];

    SKYDatabase *database = self.container.publicCloudDatabase;
    [database saveRecord:userConversation
              completion:^(SKYRecord *record, NSError *error) {
                  SKYUserConversation *con = [SKYUserConversation recordWithRecord:record];
                  if (completionHandler) {
                      completionHandler(con, error);
                  }
              }];
}

- (void)fetchUnreadCountWithUserConversation:(SKYUserConversation *)userConversation
                           completionHandler:(SKYChatUnreadCountCompletion)completionHandler
{
    [self fetchUserConversationWithID:userConversation.recordID.recordName
                    completionHandler:^(SKYUserConversation *conversation, NSError *error) {
                        if (!completionHandler) {
                            return;
                        }
                        if (error) {
                            completionHandler(nil, error);
                            return;
                        }
                        NSDictionary *response = @{
                            SKYChatMessageUnreadCountKey : @(conversation.unreadCount),
                        };
                        completionHandler(response, nil);
                    }];
}

- (void)fetchTotalUnreadCount:(SKYChatUnreadCountCompletion)completionHandler
{
    [self.container callLambda:@"chat:total_unread"
             completionHandler:^(NSDictionary *response, NSError *error) {
                 if (!completionHandler) {
                     return;
                 }
                 if (error) {
                     completionHandler(nil, error);
                 }
                 completionHandler(response, error);

             }];
}

- (void)getOrCreateUserChannelCompletionHandler:(SKYChatChannelCompletion)completionHandler
{
    SKYQuery *query = [SKYQuery queryWithRecordType:@"user_channel" predicate:nil];
    [self.container.privateCloudDatabase
             performQuery:query
        completionHandler:^(NSArray *results, NSError *error) {
            if ([results count] > 0) {
                completionHandler([SKYUserChannel recordWithRecord:[results objectAtIndex:0]],
                                  error);
            } else {
                SKYUserChannel *userChannel = [SKYUserChannel recordWithRecordType:@"user_channel"];
                userChannel.name = [[NSUUID UUID] UUIDString];
                [self.container.privateCloudDatabase
                    saveRecord:userChannel
                    completion:^(SKYRecord *record, NSError *error) {
                        SKYUserChannel *channel = [SKYUserChannel recordWithRecord:record];
                        completionHandler(channel, error);
                    }];
            }
        }];
}

#pragma mark - Subscriptions

- (void)subscribeHandler:(void (^)(NSDictionary *))messageHandler
{
    [self getOrCreateUserChannelCompletionHandler:^(SKYUserChannel *userChannel, NSError *error) {
        if (!error) {
            NSLog(@"subscribeHandler :%@", userChannel.name);
            [self.container.pubsubClient subscribeTo:userChannel.name
                                             handler:^(NSDictionary *data) {
                                                 messageHandler(data);
                                             }];
        }
    }];
}

#pragma mark - Assets

- (NSString *)getAssetNameByType:(SKYChatMetaDataType)type
{
    switch (type) {
        case SKYChatMetaDataImage:
            return SKYChatMetaDataAssetNameImage;
            break;
        case SKYChatMetaDataVoice:
            return SKYChatMetaDataAssetNameVoice;
            break;
        case SKYChatMetaDataText:
            return SKYChatMetaDataAssetNameText;
            break;
    }
    return @"";
}

- (NSString *)getMimeTypeByType:(SKYChatMetaDataType)type
{
    switch (type) {
        case SKYChatMetaDataImage:
            return @"image/png";
            break;
        case SKYChatMetaDataVoice:
            return @"audio/aac";
            break;
        case SKYChatMetaDataText:
            return @"text/";
            break;
    }
    return @"";
}

- (void)fetchAssetsByRecordId:(NSString *)recordId
            CompletionHandler:(SKYChatGetAssetsListCompletion)completionHandler
{
    NSString *recordName = [@"" stringByAppendingString:recordId];
    NSLog(@"recordName :%@", recordName);
    [self.container.privateCloudDatabase
        fetchRecordWithID:[SKYRecordID recordIDWithCanonicalString:recordName]
        completionHandler:^(SKYRecord *record, NSError *error) {
            SKYAsset *asset = record[@"image"];
            completionHandler(asset, error);
        }];
}

@end
