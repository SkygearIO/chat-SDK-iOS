//
//  SKYChatCacheController.m
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

#import "SKYChatCacheController.h"
#import "SKYChatCacheController+Private.h"

#import "SKYMessageOperationCacheObject.h"
#import "SKYMessageOperation_Private.h"

static NSString *SKYChatCacheStoreName = @"SKYChatCache";

@implementation SKYChatCacheController

+ (instancetype)defaultController
{
    static dispatch_once_t onceToken;
    static SKYChatCacheController *controller;
    dispatch_once(&onceToken, ^{
        SKYChatCacheRealmStore *store =
            [[SKYChatCacheRealmStore alloc] initWithName:SKYChatCacheStoreName];
        controller = [[SKYChatCacheController alloc] initWithStore:store];

        // It is assumed that when the default cache controller is created,
        // the app is launched and we make use of this opportunity to clean
        // up the cache.
        [controller cleanUpOnLaunch];
    });

    return controller;
}

- (id)initWithStore:(SKYChatCacheRealmStore *)store
{
    self = [super init];
    if (!self)
        return nil;

    self.store = store;

    return self;
}

- (void)cleanUpOnLaunch
{
    // Mark pending message operations as failed.
    //
    // Message operations that is pending will not progress to failed/success
    // state because the app is just launched. Therefore we need to move them
    // to failed state so that the in the clean up.
    [self markPendingMessageOperationsAsFailed];
}

- (void)fetchMessagesWithPredicate:(NSPredicate *)predicate
                             limit:(NSInteger)limit
                             order:(NSString *)order
                        completion:(SKYChatFetchMessagesListCompletion)completion
{
    if (completion && predicate) {
        NSString *resolvedOrder = order;

        if ([resolvedOrder isEqualToString:@"edited_at"]) {
            resolvedOrder = @"editionDate";
        } else {
            resolvedOrder = @"creationDate";
        }

        NSArray<SKYMessage *> *messages =
            [self.store getMessagesWithPredicate:predicate limit:limit order:resolvedOrder];
        completion(messages, YES, nil);
    }
}

- (NSMutableArray *)messagesPredicateWithConversationID:(NSString *)conversationId
                                                  limit:(NSInteger)limit
{
    return [NSMutableArray arrayWithArray:@[
        [NSPredicate predicateWithFormat:@"conversationID LIKE %@", conversationId],
        [NSPredicate predicateWithFormat:@"deleted == FALSE"],
        [NSCompoundPredicate orPredicateWithSubpredicates:@[
            [NSPredicate predicateWithFormat:@"sendDate == nil"],
        ]],
    ]];
}

- (NSPredicate *)messagesPredicateWithConversationID:(NSString *)conversationId
                                               limit:(NSInteger)limit
                                          beforeTime:(NSDate *)beforeTime
{
    NSMutableArray *predicates =
        [self messagesPredicateWithConversationID:conversationId limit:limit];
    if (beforeTime) {
        [predicates addObject:[NSPredicate predicateWithFormat:@"creationDate < %@", beforeTime]];
    }

    return [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
}

- (NSPredicate *)messagesPredicateWithConversationID:(NSString *)conversationId
                                               limit:(NSInteger)limit
                                     beforeMessageId:(NSString *)beforeMessageId
{
    NSMutableArray *predicates =
        [self messagesPredicateWithConversationID:conversationId limit:limit];
    if (beforeMessageId) {
        SKYMessage *message = [self.store getMessageWithID:beforeMessageId];
        if (message) {
            [predicates addObject:[NSPredicate predicateWithFormat:@"seq < %d", message.seq]];
        } else {
            return nil;
        }
    }
    return [NSCompoundPredicate andPredicateWithSubpredicates:predicates];
}

- (void)fetchMessagesWithConversationID:(NSString *)conversationId
                                  limit:(NSInteger)limit
                             beforeTime:(NSDate *)beforeTime
                                  order:(NSString *)order
                             completion:(SKYChatFetchMessagesListCompletion)completion
{
    NSPredicate *predicate =
        [self messagesPredicateWithConversationID:conversationId limit:limit beforeTime:beforeTime];
    [self fetchMessagesWithPredicate:predicate limit:limit order:order completion:completion];
}

- (void)fetchMessagesWithConversationID:(NSString *)conversationId
                                  limit:(NSInteger)limit
                        beforeMessageId:(NSString *)beforeMessageId
                                  order:(NSString *)order
                             completion:(SKYChatFetchMessagesListCompletion)completion
{
    NSPredicate *predicate = [self messagesPredicateWithConversationID:conversationId
                                                                 limit:limit
                                                       beforeMessageId:beforeMessageId];
    [self fetchMessagesWithPredicate:predicate limit:limit order:order completion:completion];
}

- (void)fetchMessagesWithIDs:(NSArray<NSString *> *)messageIDs
                  completion:(SKYChatFetchMessagesListCompletion)completion
{
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[
        [NSPredicate predicateWithFormat:@"recordID IN %@", messageIDs],
        [NSPredicate predicateWithFormat:@"deleted == FALSE"]
    ]];

    if (completion) {
        NSArray<SKYMessage *> *messages = [self.store getMessagesWithPredicate:predicate
                                                                         limit:messageIDs.count
                                                                         order:@"creationDate"];
        completion(messages, YES, nil);
    }
}

- (void)didFetchMessages:(NSArray<SKYMessage *> *)messages
         deletedMessages:(NSArray<SKYMessage *> *)deletedMessages
{
    [self.store setMessages:messages];

    // soft delete
    // so update the messages
    [self.store setMessages:deletedMessages];
}

- (void)didSaveMessage:(SKYMessage *)message
{
    // cache unsaved message
    [self.store setMessages:@[ message ]];
}

- (void)didDeleteMessage:(SKYMessage *)message
{
    // soft delete
    // so update the messages
    [self.store setMessages:@[ message ]];
}

- (void)handleRecordChange:(SKYChatRecordChange *)recordChange
{
    if ([recordChange.recordType isEqualToString:@"message"]) {
        [self handleChangeEvent:recordChange.event
                     forMessage:[[SKYMessage alloc] initWithRecordData:recordChange.record]];
    }
}

- (void)handleChangeEvent:(SKYChatRecordChangeEvent)event forMessage:(SKYMessage *)message
{
    switch (event) {
        case SKYChatRecordChangeEventCreate:
        case SKYChatRecordChangeEventUpdate:
            [self didSaveMessage:message];
            break;
        case SKYChatRecordChangeEventDelete:
            [self didDeleteMessage:message];
            break;
        default:
            break;
    }
}

#pragma mark - Message Operations

- (void)fetchMessageOperationsWithConversationID:(NSString *)conversationId
                                   operationType:(SKYMessageOperationType)type
                                      completion:
                                          (SKYChatFetchMessageOperationsListCompletion)completion
{
    NSString *operationTypeKey =
        [SKYMessageOperationCacheObject messageOperationTypeKeyWithType:type];
    NSMutableArray *predicates = [NSMutableArray arrayWithArray:@[
        [NSPredicate predicateWithFormat:@"conversationID == %@", conversationId],
        [NSPredicate predicateWithFormat:@"type == %@", operationTypeKey],
    ]];
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];

    if (completion) {
        NSArray<SKYMessageOperation *> *operations =
            [self.store getMessageOperationsWithPredicate:predicate limit:-1 order:@"sendDate"];
        completion(operations);
    }
}

- (void)fetchMessageOperationsWithMessageID:(NSString *)messageId
                              operationType:(SKYMessageOperationType)type
                                 completion:(SKYChatFetchMessageOperationsListCompletion)completion
{
    NSString *operationTypeKey =
        [SKYMessageOperationCacheObject messageOperationTypeKeyWithType:type];
    NSMutableArray *predicates = [NSMutableArray arrayWithArray:@[
        [NSPredicate predicateWithFormat:@"recordID == %@", messageId],
        [NSPredicate predicateWithFormat:@"type == %@", operationTypeKey],
    ]];
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];

    if (completion) {
        NSArray<SKYMessageOperation *> *operations =
            [self.store getMessageOperationsWithPredicate:predicate limit:-1 order:@"sendDate"];
        completion(operations);
    }
}

- (SKYMessageOperation *)didStartMessage:(SKYMessage *)message
                          conversationID:(NSString *)conversationID
                           operationType:(SKYMessageOperationType)operationType
{
    SKYMessageOperation *operation = [[SKYMessageOperation alloc] initWithMessage:message
                                                                   conversationID:conversationID
                                                                             type:operationType];
    [self.store setMessageOperations:@[ operation ]];
    return operation;
}

- (void)didCompleteMessageOperation:(SKYMessageOperation *)messageOperation
{
    // Completed message operation is removed from cache store.
    messageOperation.status = SKYMessageOperationStatusSuccess;
    [self.store deleteMessageOperations:@[ messageOperation ]];
}

- (void)didFailMessageOperation:(SKYMessageOperation *)messageOperation error:(NSError *)error
{
    messageOperation.status = SKYMessageOperationStatusFailed;
    messageOperation.error = [error copy];
    [self.store setMessageOperations:@[ messageOperation ]];
}

- (void)didCancelMessageOperation:(SKYMessageOperation *)messageOperation
{
    [self.store deleteMessageOperations:@[ messageOperation ]];
}

- (void)markPendingMessageOperationsAsFailed
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"status == %@", @"pending"];
    [self.store failMessageOperationsWithPredicate:predicate error:nil];
}

@end
