//
//  SKYChatCacheRealmStore.m
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

#import "SKYChatCacheRealmStore.h"

#import "SKYMessageCacheObject.h"

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

    [self createRealmWithConfiguration:config];

    return self;
}

- (instancetype)initInMemoryWithName:(NSString *)name
{
    self = [super init];
    if (!self)
        return nil;

    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    config.inMemoryIdentifier = name;

    [self createRealmWithConfiguration:config];

    return self;
}

- (void)createRealmWithConfiguration:(RLMRealmConfiguration *)config
{
    void (^initializeRealm)() = ^() {
        self.realm = [RLMRealm realmWithConfiguration:config error:nil];
    };

    if ([NSThread isMainThread]) {
        initializeRealm();
    } else {
        dispatch_async(dispatch_get_main_queue(), initializeRealm);
    }
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

    for (NSInteger i = 0; (limit == -1 || i < limit) && i < resultCount; i++) {
        SKYMessageCacheObject *cacheObject = results[i];
        SKYMessage *message = [cacheObject messageRecord];
        [messages addObject:message];
    }

    return [messages copy];
}

- (SKYMessage *)getMessageWithID:(NSString *)messageID
{
    SKYMessageCacheObject *cacheObject =
        [SKYMessageCacheObject objectInRealm:self.realm forPrimaryKey:messageID];
    return [cacheObject messageRecord];
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

- (void)deleteMessages:(NSArray<SKYMessage *> *)messages
{
    [self.realm beginWriteTransaction];

    for (SKYMessage *message in messages) {
        SKYMessageCacheObject *cacheObject =
            [SKYMessageCacheObject objectInRealm:self.realm
                                   forPrimaryKey:message.recordID.recordName];

        if (cacheObject) {
            [self.realm deleteObject:cacheObject];
        }
    }

    [self.realm commitWriteTransaction];
}

@end
