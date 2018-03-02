//
//  SKYChatCacheRealmStore.h
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

#import <Realm/Realm.h>

#import "SKYMessage.h"
#import "SKYMessageOperation.h"
#import "SKYParticipant.h"

NS_ASSUME_NONNULL_BEGIN

@interface SKYChatCacheRealmStore : NSObject

- (instancetype)initWithName:(NSString *)name;

- (instancetype)initInMemoryWithName:(NSString *)name;

- (NSArray<SKYParticipant *> *)getParticipantsWithPredicate:(NSPredicate *)predicate;

- (void)setParticipants:(NSArray<SKYParticipant *> *)participants;

- (NSArray<SKYMessage *> *)getMessagesWithPredicate:(NSPredicate *)predicate
                                              limit:(NSInteger)limit
                                              order:(NSString *)order;

- (SKYMessage *)getMessageWithID:(NSString *)messageID;

- (void)setMessages:(NSArray<SKYMessage *> *)messages;

- (void)deleteMessages:(NSArray<SKYMessage *> *)messages;

- (NSArray<SKYMessageOperation *> *)getMessageOperationsWithPredicate:(NSPredicate *)predicate
                                                                limit:(NSInteger)limit
                                                                order:(NSString *)order;

- (SKYMessageOperation *)getMessageOperationWithID:(NSString *)operationID;

- (void)setMessageOperations:(NSArray<SKYMessageOperation *> *)messageOperations;

- (void)deleteMessageOperations:(NSArray<SKYMessageOperation *> *)messageOperations;

- (void)failMessageOperationsWithPredicate:(NSPredicate *)predicate error:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
