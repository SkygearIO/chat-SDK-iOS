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
#import <Realm/Realm.h>

#import "SKYMessageCacheObject.h"

static NSString *SKYChatCacheStoreName = @"SKYChatCache";

@class SKYChatCacheRealmStore;

@interface SKYChatCacheController ()

@property SKYChatCacheRealmStore *store;

@end

@interface SKYChatCacheRealmStore : NSObject

@property RLMRealm *realm;

- (instancetype)initWithName:(NSString *)name;

- (NSArray<SKYMessage *> *)getMessagesWithPredicate:(NSPredicate *)predicate
                                              limit:(NSInteger)limit
                                              order:(NSString *)order;

- (void)setMessages:(NSArray<SKYMessage *> *)messages;

@end

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

- (void)setMessages:(NSArray<SKYMessage *> *)messages
{
    [self.store setMessages:messages];
}

@end

@implementation SKYChatCacheRealmStore

- (instancetype)initWithName:(NSString *)name
{
    self = [super init];
    if (!self)
        return nil;

    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];

    NSString *dir =
        NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSURL *url = [NSURL URLWithString:[dir stringByAppendingPathComponent:name]];
    config.fileURL = url;

    self.realm = [RLMRealm realmWithConfiguration:config error:nil];

    return self;
}

- (NSArray<SKYMessage *> *)getMessagesWithPredicate:(NSPredicate *)predicate
                                              limit:(NSInteger)limit
                                              order:(NSString *)order
{
    RLMResults<SKYMessageCacheObject *> *results =
        [[SKYMessageCacheObject objectsInRealm:self.realm withPredicate:predicate]
            sortedResultsUsingKeyPath:order
                            ascending:NO];
    NSMutableArray<SKYMessage *> *messages = [NSMutableArray arrayWithCapacity:results.count];

    NSUInteger resultCount = results.count;

    for (NSInteger i = 0; i < limit && i < resultCount; i++) {
        SKYMessageCacheObject *cacheObject = results[i];
        SKYMessage *message = [cacheObject messageRecord];
        [messages addObject:message];
    }

    return [messages copy];
}

- (void)setMessages:(NSArray<SKYMessage *> *)messages
{
    [self.realm beginWriteTransaction];

    for (SKYMessage *message in messages) {
        SKYMessageCacheObject *cacheObject = [SKYMessageCacheObject cacheObjectFromMessage:message];
        [self.realm addOrUpdateObject:cacheObject];
    }

    [self.realm commitWriteTransaction];
}

@end
