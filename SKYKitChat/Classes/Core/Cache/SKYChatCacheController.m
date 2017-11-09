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

#import "SKYMessageCacheObject.h"

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
    NSMutableArray *predicates = [NSMutableArray
        arrayWithArray:@[ [NSPredicate
                           predicateWithFormat:@"conversationID LIKE %@", conversationId] ]];
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
        completion(messages, nil);
    }
}

- (void)didFetchMessages:(NSArray<SKYMessage *> *)messages
{
    [self.store setMessages:messages];
}

- (void)saveMessage:(SKYMessage *)message completion:(SKYChatMessageCompletion)completion
{
    // TODO:
    // cache unsaved message

    if (completion) {
        completion(message, nil);
    }
}

- (void)didSaveMessage:(SKYMessage *)message error:(NSError *)error
{
    if (error) {
        // TODO:
        // invalidate unsaved message
        return;
    }

    message.alreadySyncToServer = true;
    message.fail = false;

    [self.store setMessages:@[ message ]];
}


@end
