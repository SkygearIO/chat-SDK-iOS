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
#import "SKYContainer_Private.h"
#import "SKYConversation.h"
#import "SKYConversationChange.h"
#import "SKYKit.h"
#import "SKYLastMessageRead.h"
#import "SKYMessage.h"
#import "SKYPubsub.h"
#import "SKYReference.h"
#import "SKYUserChannel.h"
#import "SKYUserConversation.h"

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

- (void)createConversationWithParticipantIDs:(NSArray<NSString *> *)participantIds
                                adminIDs:(NSArray<NSString *> *)adminIds
                                   title:(NSString *)title
                           completionHandler:
                               (SKYContainerConversationOperationActionCompletion)completionHandler
{

    SKYConversation *conv = [SKYConversation recordWithRecordType:@"conversation"];
    conv.participantIds = participantIds;
    if (![adminIds containsObject:self.container.currentUserRecordID]) {
        NSMutableArray *array = [adminIds mutableCopy];
        [array addObject:self.container.currentUserRecordID];
        adminIds = [array copy];
    }
    conv.adminIds = adminIds;
    conv.title = title;
    [self saveConversation:conv
         completionHandler:completionHandler];
}

- (void)fetchOrCreateDirectConversationWithUserId:(NSString *)userId
                               completionHandler:(SKYContainerConversationOperationActionCompletion)
                                                     completionHandler
{
    NSPredicate *pred1 = [NSPredicate predicateWithFormat:@"%@ in participant_ids", userId];
    NSPredicate *pred2 = [NSPredicate
        predicateWithFormat:@"%@ in participant_ids", self.container.currentUserRecordID];
    NSPredicate *pred3 = [NSPredicate predicateWithFormat:@"is_direct_message = %@", @YES];

    NSCompoundPredicate *predicate =
        [NSCompoundPredicate andPredicateWithSubpredicates:@[ pred1, pred2, pred3 ]];
    SKYQuery *query = [SKYQuery queryWithRecordType:@"conversation" predicate:predicate];
    query.limit = 1;

    [self.container.publicCloudDatabase
             performQuery:query
        completionHandler:^(NSArray *results, NSError *error) {
            if ([results count] > 0) {
                SKYConversation *con = [SKYConversation recordWithRecord:results.firstObject];
                if (completionHandler) {
                    completionHandler(con, error);
                }
            } else {
                SKYConversation *conv = [SKYConversation recordWithRecordType:@"conversation"];
                conv.participantIds = @[ userId, self.container.currentUserRecordID ];
                conv.adminIds = @[ userId, self.container.currentUserRecordID ];
                conv.isDirectMessage = YES;
                
                [self saveConversation:conv completionHandler:completionHandler];
            }
        }];
}

- (void)deleteConversation:(SKYConversation *)conversation
                           completionHandler:
                               (SKYContainerConversationOperationActionCompletion)completionHandler
{
    [self deleteConversationWithID:conversation.recordID.recordName
                 completionHandler:completionHandler];
}

- (void)deleteConversationWithID:(NSString *)conversationId
               completionHandler:(SKYContainerConversationOperationActionCompletion)completionHandler
{
    SKYRecordID *recordID = [SKYRecordID recordIDWithRecordType:@"conversation"
                                                           name:conversationId];
    [self.container.publicCloudDatabase deleteRecordWithID:recordID
                                         completionHandler:^(SKYRecordID *recordID,
                                                             NSError *error) {
                                             if (completionHandler != nil) {
                                                 completionHandler(nil, error);
                                             }
                                         }];
}

- (void)saveConversation:(SKYConversation *)conversation
                           completionHandler:
                               (SKYContainerConversationOperationActionCompletion)completionHandler
{
    [self.container.publicCloudDatabase
      saveRecord:conversation
      completion:^(SKYRecord *record, NSError *error) {
          SKYConversation *newConversation = [SKYConversation recordWithRecord:record];
          completionHandler(newConversation, error);
      }];
}

#pragma mark Fetching User Conversations

- (void)fetchUserConversationsWithQuery:(SKYQuery *)query
                           completionHandler:(SKYContainerGetUserConversationListActionCompletion)completionHandler
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
                 SKYUserConversation *con =
                 [SKYUserConversation recordWithRecord:record];
                 [resultArray addObject:con];
             }
             
             if (completionHandler) {
                 completionHandler(resultArray, error);
             }
         }];

}

- (void)fetchUserConversationsCompletionHandler:
    (SKYContainerGetUserConversationListActionCompletion)completionHandler
{
    NSPredicate *predicate =
        [NSPredicate predicateWithFormat:@"user = %@", self.container.currentUserRecordID];
    SKYQuery *query = [SKYQuery queryWithRecordType:@"user_conversation" predicate:predicate];
    [self fetchUserConversationsWithQuery:query
                        completionHandler:completionHandler];
}

- (void)fetchUserConversationWithID:(NSString *)conversationId
                            completionHandler:
                                (SKYContainerUserConversationOperationActionCompletion)
                                    completionHandler
{
    NSPredicate *pred1 =
        [NSPredicate predicateWithFormat:@"user = %@", self.container.currentUserRecordID];
    NSPredicate *pred2 = [NSPredicate predicateWithFormat:@"conversation = %@", conversationId];
    NSCompoundPredicate *predicate =
        [NSCompoundPredicate andPredicateWithSubpredicates:@[ pred1, pred2 ]];
    SKYQuery *query = [SKYQuery queryWithRecordType:@"user_conversation" predicate:predicate];
    query.limit = 1;
    [self fetchUserConversationsWithQuery:query
                        completionHandler:^(NSArray<SKYUserConversation *> *conversationList, NSError *error) {
                            if (!completionHandler) {
                                return;
                            }
                            
                            if (!conversationList.count) {
                                NSError *error =  [NSError errorWithDomain:SKYOperationErrorDomain
                                                                      code:SKYErrorResourceNotFound
                                                                  userInfo:nil];
                                completionHandler(@[], error);
                            }
                            
                            SKYUserConversation *con = [SKYUserConversation
                                                        recordWithRecord:conversationList.firstObject];
                            completionHandler(con, nil);
                        }];
}

#pragma mark Conversation Memberships

- (void)addParticipantsWithIDs:(NSArray<NSString *> *)participantIDs
                toConversation:(SKYConversation *)conversation
             completionHandler:
(SKYContainerConversationOperationActionCompletion)completionHandler
{
    [conversation addParticipantsWithIDs:participantIDs];
    [self saveConversation:conversation completionHandler:completionHandler];
}

- (void)removeParticipantsWithIDs:(NSArray<NSString *> *)participantIDs
                 fromConversation:(SKYConversation *)conversation
                completionHandler:
(SKYContainerConversationOperationActionCompletion)completionHandler
{
    [conversation removeParticipantsWithIDs:participantIDs];
    [self saveConversation:conversation completionHandler:completionHandler];
}

- (void)addAdminsWithIDs:(NSArray<NSString *> *)adminIDs
                toConversation:(SKYConversation *)conversation
             completionHandler:
(SKYContainerConversationOperationActionCompletion)completionHandler
{
    [conversation addAdminsWithIDs:adminIDs];
    [self saveConversation:conversation completionHandler:completionHandler];
}

- (void)removeAdminsWithIDs:(NSArray<NSString *> *)adminIDs
                 fromConversation:(SKYConversation *)conversation
                completionHandler:
(SKYContainerConversationOperationActionCompletion)completionHandler
{
    [conversation removeAdminsWithIDs:adminIDs];
    [self saveConversation:conversation completionHandler:completionHandler];
}

#pragma mark - Messages

- (void)createMessageWithConversation:(SKYConversation *)conversation
                               body:(NSString *)body
                             metadata:(NSDictionary *)metadata
                      completionHandler:
                          (SKYContainerMessageOperationActionCompletion)completionHandler
{
    SKYMessage *message = [SKYMessage recordWithMessageRecordType];
    if (body) {
        message.body = body;
    }
    if (metadata) {
        message.metadata = metadata;
    }
    [self addMessage:message
             toConversation:conversation
   completionHandler:completionHandler];
}

- (void)createMessageWithConversation:(SKYConversation *)conversation
                                 body:(NSString *)body
                                image:(UIImage *)image
                    completionHandler:
(SKYContainerMessageOperationActionCompletion)completionHandler
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
                      completionHandler:
(SKYContainerMessageOperationActionCompletion)completionHandler
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
 completionHandler:(SKYContainerMessageOperationActionCompletion)completionHandler
{
    message.conversationId = [SKYReference referenceWithRecord:conversation];
    SKYDatabase *database = self.container.publicCloudDatabase;
    [database saveRecord:message
              completion:^(SKYRecord *record, NSError *error) {
                  SKYMessage *msg = nil;
                  if (error) {
                      message.isAlreadySyncToServer = false;
                      message.isFail = true;
                  } else {
                      msg = [SKYMessage recordWithRecord:record];
                      msg.isAlreadySyncToServer = true;
                      msg.isFail = false;
                  }
                  if (completionHandler) {
                      completionHandler(msg, error);
                  }
              }];
}

- (void)addMessage:(SKYMessage *)message
          andAsset:(SKYAsset *)asset
    toConversation:(SKYConversation *)conversation
    completionHandler:(SKYContainerMessageOperationActionCompletion)completionHandler
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
    completionHandler:(SKYContainerMessageOperationActionCompletion)completionHandler
{
    [self deleteMessageWithID:message.recordID.recordName
            completionHandler:completionHandler];
}

- (void)deleteMessageWithID:(NSString *)messageID
    completionHandler:(SKYContainerMessageOperationActionCompletion)completionHandler
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
                                  limit:(NSString *)limit
                             beforeTime:(NSDate *)beforeTime
                      completionHandler:(SKYContainerGetMessagesActionCompletion)completionHandler
{
    [self fetchMessagesWithConversationID:conversation.recordID.recordName
                                    limit:limit
                               beforeTime:beforeTime
                        completionHandler:completionHandler];
}

- (void)fetchMessagesWithConversationID:(NSString *)conversationId
                                  limit:(NSString *)limit
                             beforeTime:(NSDate *)beforeTime
                      completionHandler:(SKYContainerGetMessagesActionCompletion)completionHandler
{
    NSString *dateString = @"";
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ"];
    dateString = [formatter stringFromDate:beforeTime];
    NSLog(@"dateString :%@", dateString);
    [self.container callLambda:@"chat:get_messages"
                     arguments:@[ conversationId, limit, dateString ]
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
                         msg.isAlreadySyncToServer = true;
                         msg.isFail = false;
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
 completionHandler:(void(^)(NSError *error))completionHandler
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
       completionHandler:(void(^)(NSError *error))completionHandler
{
    NSMutableArray *recordIDs = [NSMutableArray array];
    [messages enumerateObjectsUsingBlock:^(SKYMessage * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [recordIDs addObject:obj.recordID.recordName];
    }];
    [self callLambda:@"chat:mark_as_read" messageIDs:recordIDs completionHandler:completionHandler];
}

- (void)markReadMessagesWithID:(NSArray<NSString *> *)messageIDs
       completionHandler:(void(^)(NSError *error))completionHandler
{
    [self callLambda:@"chat:mark_as_read" messageIDs:messageIDs completionHandler:completionHandler];
}

- (void)markDeliveredMessages:(NSArray<SKYMessage *> *)messages
            completionHandler:(void(^)(NSError *error))completionHandler
{
    NSMutableArray *recordIDs = [NSMutableArray array];
    [messages enumerateObjectsUsingBlock:^(SKYMessage * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [recordIDs addObject:obj.recordID.recordName];
    }];
    [self callLambda:@"chat:mark_as_delivered" messageIDs:recordIDs completionHandler:completionHandler];
}

- (void)markDeliveredMessagesWithID:(NSArray<NSString *> *)messageIDs
                  completionHandler:(void(^)(NSError *error))completionHandler
{
    [self callLambda:@"chat:mark_as_delivered" messageIDs:messageIDs completionHandler:completionHandler];
}


#pragma mark Message Markers

- (void)getOrCreateLastMessageReadithConversationId:(NSString *)conversationId
                                  completionHandler:
                                      (SKYContainerLastMessageReadOperationActionCompletion)
                                          completionHandler
{
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"conversation_id = %@", conversationId];
    SKYQuery *query = [SKYQuery queryWithRecordType:@"last_message_read" predicate:pred];
    query.limit = 1;

    [self.container.privateCloudDatabase
             performQuery:query
        completionHandler:^(NSArray *results, NSError *error) {
            if ([results count] > 0) {
                if (error) {
                    completionHandler(nil, error);

                } else {
                    SKYLastMessageRead *msg =
                        [SKYLastMessageRead recordWithRecord:[results objectAtIndex:0]];
                    completionHandler(msg, error);
                }
            } else {
                SKYLastMessageRead *lmr =
                    [SKYLastMessageRead recordWithRecordType:@"last_message_read"];
                lmr.conversationId = conversationId;
                [self.container.publicCloudDatabase
                    saveRecord:lmr
                    completion:^(SKYRecord *record, NSError *error) {
                        SKYLastMessageRead *msg = [SKYLastMessageRead recordWithRecord:record];
                        completionHandler(msg, error);
                    }];
            }
        }];
}

- (void)markAsLastMessageReadWithConversationId:(NSString *)conversationId
                                  withMessageId:(NSString *)messageId
                              completionHandler:
                                  (SKYContainerMarkLastMessageReadOperationActionCompletion)
                                      completionHandler
{

    NSPredicate *pred1 =
        [NSPredicate predicateWithFormat:@"user = %@", self.container.currentUserRecordID];
    NSPredicate *pred2 = [NSPredicate predicateWithFormat:@"conversation = %@", conversationId];
    NSCompoundPredicate *predicate =
        [NSCompoundPredicate andPredicateWithSubpredicates:@[ pred1, pred2 ]];
    SKYQuery *query = [SKYQuery queryWithRecordType:@"user_conversation" predicate:predicate];
    query.limit = 1;

    [self.container.publicCloudDatabase
             performQuery:query
        completionHandler:^(NSArray *results, NSError *error) {
            if ([results count] > 0) {
                SKYUserConversation *con =
                    [SKYUserConversation recordWithRecord:[results objectAtIndex:0]];
                con[@"last_read_message"] = [SKYReference
                    referenceWithRecordID:[SKYRecordID recordIDWithRecordType:@"message"
                                                                         name:messageId]];

                [self.container.publicCloudDatabase
                    saveRecord:con
                    completion:^(SKYRecord *record, NSError *error) {
                        if (error) {
                            NSLog(@"error saving userConversation: %@", error);
                        }
                        SKYUserConversation *con = [SKYUserConversation recordWithRecord:record];
                        completionHandler(con, error);
                    }];
            } else {
                completionHandler(nil, error);
            }
        }];
}

- (void)getTotalUnreadCount:(SKYContainerTotalUnreadCountOperationActionCompletion)completionHandler
{
    [self.container callLambda:@"chat:total_unread"
             completionHandler:^(NSDictionary *response, NSError *error) {
                 if (error) {
                     NSLog(@"error calling chat:total_unread: %@", error);
                 }

                 NSLog(@"Received response = %@", response);
                 completionHandler(response, error);

             }];
}

// FIXME: chat plugin don't have chat:get_unread_message_count lambda function,
// use this will only
// get error
- (void)getUnreadMessageCountWithConversationId:(NSString *)conversationId
                              completionHandler:(SKYContainerUnreadCountOperationActionCompletion)
                                                    completionHandler
{
    [self.container callLambda:@"chat:get_unread_message_count"
                     arguments:@[ conversationId ]
             completionHandler:^(NSDictionary *response, NSError *error) {
                 if (error) {
                     NSLog(@"error calling hello:someone: %@", error);
                 }

                 NSLog(@"Received response = %@", response);
                 NSNumber *count = [response objectForKey:@"count"];
                 if (count) {
                     completionHandler([count integerValue], error);
                 } else {
                     completionHandler(0, error);
                 }

             }];
}

- (void)getOrCreateUserChannelCompletionHandler:
    (SKYContainerChannelOperationActionCompletion)completionHandler
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
            CompletionHandler:(SKYContainerGetAssetsActionCompletion)completionHandler
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
