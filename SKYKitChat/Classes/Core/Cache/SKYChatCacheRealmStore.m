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
#import "SKYChatCacheRealmStore+Private.h"

#import "SKYMessageCacheObject.h"
#import "SKYMessageOperationCacheObject.h"
#import "SKYParticipantCacheObject.h"

@implementation SKYChatCacheRealmStore

- (instancetype)initWithName:(NSString *)name
{
    self = [super init];
    if (!self)
        return nil;

    NSString *dir =
        NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSURL *url = [NSURL URLWithString:[dir stringByAppendingPathComponent:name]];

    self.realmConfig = [RLMRealmConfiguration defaultConfiguration];
    self.realmConfig.schemaVersion = 2;
    self.realmConfig.migrationBlock = ^(RLMMigration *migration, uint64_t oldSchemaVersion) {
    };
    self.realmConfig.fileURL = url;
    return self;
}

- (instancetype)initInMemoryWithName:(NSString *)name
{
    self = [super init];
    if (!self)
        return nil;

    self.realmConfig = [RLMRealmConfiguration defaultConfiguration];
    self.realmConfig.inMemoryIdentifier = name;

    return self;
}

- (RLMRealm *)realmInstance
{
    // create realm instance for each access, prevent cross thread access
    NSError *error = nil;
    RLMRealm *realmInstance = [RLMRealm realmWithConfiguration:self.realmConfig error:&error];

    if (error) {
        NSLog(@"Failed to create Realm instance: %@", error.localizedDescription);
        return nil;
    }

    return realmInstance;
}

- (NSArray<SKYParticipant *> *)getParticipantsWithPredicate:(NSPredicate *)predicate
{
    RLMRealm *realmInstance = self.realmInstance;
    RLMResults<SKYParticipantCacheObject *> *results =
        [SKYParticipantCacheObject objectsInRealm:realmInstance withPredicate:predicate];

    NSMutableArray<SKYParticipant *> *participants = [@[] mutableCopy];
    NSUInteger resultCount = results.count;
    for (NSUInteger i = 0; i < resultCount; i++) {
        SKYParticipantCacheObject *eachCacheObject = results[i];
        SKYParticipant *eachParticipant = [eachCacheObject participantRecord];
        [participants addObject:eachParticipant];
    }

    return participants;
}

- (void)setParticipants:(NSArray<SKYParticipant *> *)participants
{
    RLMRealm *realmInstance = self.realmInstance;
    [realmInstance beginWriteTransaction];

    for (SKYParticipant *eachParticipant in participants) {
        SKYParticipantCacheObject *eachCacheObject =
            [SKYParticipantCacheObject cacheObjectFromParticipant:eachParticipant];
        [realmInstance addOrUpdateObject:eachCacheObject];
    }

    [realmInstance commitWriteTransaction];
}

- (NSArray<SKYMessage *> *)getMessagesWithPredicate:(NSPredicate *)predicate
                                              limit:(NSInteger)limit
                                              order:(NSString *)order
{
    RLMRealm *realmInstance = self.realmInstance;
    RLMResults<SKYMessageCacheObject *> *results =
        [[SKYMessageCacheObject objectsInRealm:realmInstance withPredicate:predicate]
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
    RLMRealm *realmInstance = self.realmInstance;
    SKYMessageCacheObject *cacheObject =
        [SKYMessageCacheObject objectInRealm:realmInstance forPrimaryKey:messageID];
    return [cacheObject messageRecord];
}

- (void)setMessages:(NSArray<SKYMessage *> *)messages
{
    RLMRealm *realmInstance = self.realmInstance;
    [realmInstance beginWriteTransaction];

    for (SKYMessage *message in messages) {
        SKYMessageCacheObject *cacheObject = [SKYMessageCacheObject cacheObjectFromMessage:message];
        [realmInstance addOrUpdateObject:cacheObject];
    }

    [realmInstance commitWriteTransaction];
}

- (void)deleteMessages:(NSArray<SKYMessage *> *)messages
{
    RLMRealm *realmInstance = self.realmInstance;
    [realmInstance beginWriteTransaction];

    for (SKYMessage *message in messages) {
        SKYMessageCacheObject *cacheObject =
            [SKYMessageCacheObject objectInRealm:realmInstance
                                   forPrimaryKey:message.recordID.recordName];

        if (cacheObject) {
            [realmInstance deleteObject:cacheObject];
        }
    }

    [realmInstance commitWriteTransaction];
}

#pragma mark - Message Operations

- (NSArray<SKYMessageOperation *> *)getMessageOperationsWithPredicate:(NSPredicate *)predicate
                                                                limit:(NSInteger)limit
                                                                order:(NSString *)order
{
    RLMRealm *realmInstance = self.realmInstance;
    RLMResults<SKYMessageOperationCacheObject *> *results =
        [[SKYMessageOperationCacheObject objectsInRealm:realmInstance withPredicate:predicate]
            sortedResultsUsingKeyPath:order
                            ascending:NO];
    NSMutableArray<SKYMessageOperation *> *operations =
        [NSMutableArray arrayWithCapacity:results.count];

    NSUInteger resultCount = results.count;

    for (NSInteger i = 0; (limit == -1 || i < limit) && i < resultCount; i++) {
        SKYMessageOperationCacheObject *cacheObject = results[i];
        SKYMessageOperation *operation = [cacheObject messageOperation];
        [operations addObject:operation];
    }

    return [operations copy];
}

- (SKYMessageOperation *)getMessageOperationWithID:(NSString *)operationID
{
    RLMRealm *realmInstance = self.realmInstance;
    SKYMessageOperationCacheObject *cacheObject =
        [SKYMessageOperationCacheObject objectInRealm:realmInstance forPrimaryKey:operationID];
    return [cacheObject messageOperation];
}

- (void)setMessageOperations:(NSArray<SKYMessageOperation *> *)messageOperations
{
    RLMRealm *realmInstance = self.realmInstance;
    [realmInstance beginWriteTransaction];

    for (SKYMessageOperation *operation in messageOperations) {
        SKYMessageOperationCacheObject *cacheObject =
            [SKYMessageOperationCacheObject cacheObjectFromMessageOperation:operation];
        [realmInstance addOrUpdateObject:cacheObject];
    }

    [realmInstance commitWriteTransaction];
}

- (void)deleteMessageOperations:(NSArray<SKYMessageOperation *> *)messageOperations
{
    RLMRealm *realmInstance = self.realmInstance;
    [realmInstance beginWriteTransaction];

    for (SKYMessageOperation *operation in messageOperations) {
        SKYMessageOperationCacheObject *cacheObject =
            [SKYMessageOperationCacheObject objectInRealm:realmInstance
                                            forPrimaryKey:operation.operationID];

        if (cacheObject) {
            [realmInstance deleteObject:cacheObject];
        }
    }

    [realmInstance commitWriteTransaction];
}

- (void)failMessageOperationsWithPredicate:(NSPredicate *)predicate error:(NSError *)error
{
    RLMRealm *realmInstance = self.realmInstance;
    [realmInstance beginWriteTransaction];

    RLMResults<SKYMessageCacheObject *> *results =
        [SKYMessageOperationCacheObject objectsInRealm:realmInstance withPredicate:predicate];
    [results setValuesForKeysWithDictionary:@{
        @"status" : @"failed",
        @"errorData" : [NSKeyedArchiver archivedDataWithRootObject:error],
    }];

    [realmInstance commitWriteTransaction];
}

@end
