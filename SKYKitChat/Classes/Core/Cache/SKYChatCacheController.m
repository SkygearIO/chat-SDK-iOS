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

- (void)fetchMessagesWithConversationID:(NSString *)conversationId
                                  limit:(NSInteger)limit
                             beforeTime:(NSDate *)beforeTime
                                  order:(NSString *)order
                             completion:(SKYChatFetchMessagesListCompletion)completion
{
    NSMutableArray *predicates = [NSMutableArray arrayWithArray:@[
        [NSPredicate predicateWithFormat:@"conversationID LIKE %@", conversationId],
        [NSPredicate predicateWithFormat:@"deleted == FALSE"],
        [NSCompoundPredicate orPredicateWithSubpredicates:@[
            [NSPredicate predicateWithFormat:@"alreadySyncToServer != FALSE AND fail != TRUE"],
            [NSPredicate predicateWithFormat:@"sendDate == nil"],
        ]],
    ]];
    if (beforeTime) {
        [predicates addObject:[NSPredicate predicateWithFormat:@"creationDate < %@", beforeTime]];
    }
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];

    NSString *resolvedOrder = order;
    if ([resolvedOrder isEqualToString:@"edited_at"]) {
        resolvedOrder = @"editionDate";
    } else {
        resolvedOrder = @"creationDate";
    }

    if (completion) {
        NSArray<SKYMessage *> *messages =
            [self.store getMessagesWithPredicate:predicate limit:limit order:resolvedOrder];
        completion(messages, YES, nil);
    }
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

- (void)saveMessage:(SKYMessage *)message completion:(SKYChatMessageCompletion)completion
{
    // cache unsaved message
    [self.store setMessages:@[ message ]];

    if (completion) {
        completion(message, nil);
    }
}

- (void)didSaveMessage:(SKYMessage *)message error:(NSError *)error
{
    if (error) {
        // invalidate unsaved message
        message.alreadySyncToServer = false;
        message.fail = true;
        [self.store setMessages:@[ message ]];
        return;
    }

    message.alreadySyncToServer = true;
    message.fail = false;

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
            [self didSaveMessage:message error:nil];
            break;
        case SKYChatRecordChangeEventUpdate:
            [self didSaveMessage:message error:nil];
            break;
        case SKYChatRecordChangeEventDelete:
            [self didDeleteMessage:message];
            break;
        default:
            break;
    }
}

- (void)fetchUnsentMessagesWithConversationID:(NSString *)conversationId
                                   completion:(void (^_Nullable)(NSArray<SKYMessage *> *_Nonnull))
                                                  completion
{
    NSMutableArray *predicates = [NSMutableArray arrayWithArray:@[
        [NSPredicate predicateWithFormat:@"conversationID LIKE %@", conversationId],
        [NSPredicate predicateWithFormat:@"sendDate != nil"],
        [NSPredicate predicateWithFormat:@"alreadySyncToServer == FALSE OR fail == TRUE"],
    ]];
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:predicates];

    if (completion) {
        NSArray<SKYMessage *> *messages =
            [self.store getMessagesWithPredicate:predicate limit:-1 order:@"creationDate"];
        completion(messages);
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

@end
