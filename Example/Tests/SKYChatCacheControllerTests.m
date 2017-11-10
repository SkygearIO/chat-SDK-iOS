//
//  SKYChatCacheControllerTests.m
//  SKYKitChatTests
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

#import "SKYChatCacheController+Private.h"
#import "SKYChatCacheController.h"

#import "SKYMessageCacheObject.h"

SpecBegin(SKYChatCacheController)

    describe(@"Cache Controller", ^{
        __block SKYChatCacheController *cacheController = nil;
        __block NSDate *baseDate = nil;

        /**
         *  Fixture:
         *  10 messages in total
         *  odds in conversation c0, evens in conversation c1
         */
        beforeEach(^{
            cacheController = [[SKYChatCacheController alloc]
                initWithStore:[[SKYChatCacheRealmStore alloc] initInMemoryWithName:@"ChatTest"]];
            baseDate = [NSDate dateWithTimeIntervalSince1970:0];

            NSInteger messageCount = 10;
            NSMutableArray<SKYMessageCacheObject *> *messages =
                [NSMutableArray arrayWithCapacity:messageCount];

            for (NSInteger i = 0; i < messageCount; i++) {
                SKYMessage *message = [[SKYMessage alloc]
                    initWithRecordData:[SKYRecord
                                           recordWithRecordType:@"message"
                                                           name:[NSString
                                                                    stringWithFormat:@"m%ld", i]]];
                message.conversationRef = [SKYReference
                    referenceWithRecordID:[SKYRecordID
                                              recordIDWithRecordType:@"conversation"
                                                                name:[NSString
                                                                         stringWithFormat:@"c%ld",
                                                                                          i % 2]]];
                message.creationDate = [baseDate dateByAddingTimeInterval:i * 1000];
                message.record[@"edited_at"] = [baseDate dateByAddingTimeInterval:i * 2000];

                SKYMessageCacheObject *messageCacheObject =
                    [SKYMessageCacheObject cacheObjectFromMessage:message];
                [messages addObject:messageCacheObject];
            }

            RLMRealm *realm = cacheController.store.realm;
            [realm transactionWithBlock:^{
                [realm addObjects:messages];
            }];
        });

        afterEach(^{
            RLMRealm *realm = cacheController.store.realm;
            [realm transactionWithBlock:^{
                [realm deleteAllObjects];
            }];
        });

        it(@"store insert new record for new record id", ^{
            SKYChatCacheRealmStore *store = cacheController.store;

            SKYMessage *message = [[SKYMessage alloc]
                initWithRecordData:[SKYRecord recordWithRecordType:@"message" name:@"mm1"]];
            message.conversationRef = [SKYReference
                referenceWithRecordID:[SKYRecordID recordIDWithRecordType:@"conversation"
                                                                     name:@"c1"]];
            message.creationDate = [baseDate dateByAddingTimeInterval:8000];
            message.record[@"edited_at"] = [baseDate dateByAddingTimeInterval:8000];

            [store setMessages:@[ message ]];

            RLMResults<SKYMessageCacheObject *> *results =
                [SKYMessageCacheObject allObjectsInRealm:store.realm];
            expect(results.count).to.equal(11);
            expect([results objectsWhere:@"recordID == %@", @"mm1"].count).to.equal(1);
        });

        it(@"store update old record for existing record id", ^{
            SKYChatCacheRealmStore *store = cacheController.store;

            SKYMessage *message = [[SKYMessage alloc]
                initWithRecordData:[SKYRecord recordWithRecordType:@"message" name:@"m2"]];
            message.conversationRef = [SKYReference
                referenceWithRecordID:[SKYRecordID recordIDWithRecordType:@"conversation"
                                                                     name:@"c0"]];
            message.creationDate = [baseDate dateByAddingTimeInterval:8000];
            message.record[@"edited_at"] = [baseDate dateByAddingTimeInterval:8000];

            [store setMessages:@[ message ]];

            RLMResults<SKYMessageCacheObject *> *results =
                [SKYMessageCacheObject allObjectsInRealm:store.realm];
            expect(results.count).to.equal(10);

            RLMResults<SKYMessageCacheObject *> *updatedResults =
                [results objectsWhere:@"recordID == %@", @"m2"];
            expect(updatedResults.count).to.equal(1);

            SKYMessageCacheObject *updatedMessage = [updatedResults objectAtIndex:0];
            expect(updatedMessage.creationDate).to.equal([baseDate dateByAddingTimeInterval:8000]);
            expect(updatedMessage.editionDate).to.equal([baseDate dateByAddingTimeInterval:8000]);
        });

        it(@"fetch all messages of conversation, sorted by creationDate", ^{
            [cacheController
                fetchMessagesWithConversationID:@"c0"
                                          limit:100
                                     beforeTime:nil
                                          order:nil
                                     completion:^(NSArray<SKYMessage *> *_Nullable messageList,
                                                  NSError *_Nullable error) {
                                         expect(messageList.count).to.equal(5);
                                         for (NSInteger i = 0; i < 5; i++) {
                                             SKYMessage *message = messageList[4 - i];
                                             expect(message.creationDate)
                                                 .to.equal(
                                                     [baseDate dateByAddingTimeInterval:i * 2000]);
                                         }
                                     }];
        });

        it(@"fetch messages of conversation, filtered by time and sorted by creationDate", ^{
            [cacheController
                fetchMessagesWithConversationID:@"c0"
                                          limit:100
                                     beforeTime:[baseDate dateByAddingTimeInterval:4000]
                                          order:nil
                                     completion:^(NSArray<SKYMessage *> *_Nullable messageList,
                                                  NSError *_Nullable error) {
                                         expect(messageList.count).to.equal(2);
                                         for (NSInteger i = 0; i < 2; i++) {
                                             SKYMessage *message = messageList[1 - i];
                                             expect(message.creationDate)
                                                 .to.equal(
                                                     [baseDate dateByAddingTimeInterval:i * 2000]);
                                         }
                                     }];
        });
    });

SpecEnd
