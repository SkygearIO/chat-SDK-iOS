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

        it(@"didFetch messages, update the cache", ^{
            NSInteger messageCount = 5;
            NSMutableArray<SKYMessage *> *messages =
                [NSMutableArray arrayWithCapacity:messageCount];

            for (NSInteger i = 0; i < messageCount; i++) {
                SKYMessage *message = [[SKYMessage alloc]
                    initWithRecordData:[SKYRecord
                                           recordWithRecordType:@"message"
                                                           name:[NSString
                                                                    stringWithFormat:@"m%ld",
                                                                                     (i + 3) * 2]]];
                message.conversationRef = [SKYReference
                    referenceWithRecordID:[SKYRecordID recordIDWithRecordType:@"conversation"
                                                                         name:@"c0"]];
                message.creationDate = [baseDate dateByAddingTimeInterval:(i + 3) * 2000];
                message.record[@"edited_at"] = [baseDate dateByAddingTimeInterval:50000];
                message.body = @"fetched message";
                [messages addObject:message];
            }

            [cacheController didFetchMessages:messages];

            SKYChatCacheRealmStore *store = cacheController.store;
            RLMResults<SKYMessageCacheObject *> *results =
                [SKYMessageCacheObject objectsInRealm:store.realm
                                                where:@"conversationID == %@", @"c0"];
            expect(results.count).to.equal(8);

            results = [SKYMessageCacheObject
                objectsInRealm:store.realm
                         where:@"editionDate == %@", [baseDate dateByAddingTimeInterval:50000]];
            expect(results.count).to.equal(5);

            // simulate next time fetch result from cache
            [cacheController
                fetchMessagesWithConversationID:@"c0"
                                          limit:100
                                     beforeTime:nil
                                          order:nil
                                     completion:^(NSArray<SKYMessage *> *_Nullable messageList,
                                                  NSError *_Nullable error) {
                                         expect(messageList.count).to.equal(8);
                                         for (NSInteger i = 0; i < 8; i++) {
                                             SKYMessage *message = messageList[7 - i];
                                             expect(message.creationDate)
                                                 .to.equal(
                                                     [baseDate dateByAddingTimeInterval:i * 2000]);
                                             if (i >= 3) {
                                                 expect(message.body).to.equal(@"fetched message");
                                                 expect(message.record[@"edited_at"])
                                                     .to.equal(
                                                         [baseDate dateByAddingTimeInterval:50000]);
                                             } else {
                                                 expect(message.body).to.beNil();
                                                 expect(message.record[@"edited_at"])
                                                     .to.equal([baseDate
                                                         dateByAddingTimeInterval:i * 4000]);
                                             }
                                         }
                                     }];
        });

        it(@"save message, update the cache", ^{
            SKYMessage *messageToSave = [[SKYMessage alloc]
                initWithRecordData:[SKYRecord recordWithRecordType:@"message" name:@"mm1"]];
            messageToSave.conversationRef = [SKYReference
                referenceWithRecordID:[SKYRecordID recordIDWithRecordType:@"conversation"
                                                                     name:@"c0"]];
            messageToSave.creationDate = [baseDate dateByAddingTimeInterval:50000];
            messageToSave.record[@"edited_at"] = [baseDate dateByAddingTimeInterval:50000];
            messageToSave.body = @"new message";

            // assume that the save message to cache operation is sync
            RLMRealm *realm = cacheController.store.realm;

            [cacheController didSaveMessage:messageToSave error:nil];

            RLMResults<SKYMessageCacheObject *> *results =
                [SKYMessageCacheObject objectsInRealm:realm where:@"recordID == %@", @"mm1"];
            expect(results.count).to.equal(1);

            SKYMessage *newMessage = [[results objectAtIndex:0] messageRecord];
            expect(newMessage.body).to.equal(messageToSave.body);
            expect(newMessage.alreadySyncToServer).to.equal(YES);
            expect(newMessage.fail).to.equal(NO);
        });

        it(@"delete message, update the cache", ^{
            SKYMessage *message = [[SKYMessage alloc]
                initWithRecordData:[SKYRecord recordWithRecordType:@"message" name:@"m1"]];

            [cacheController didDeleteMessage:message];

            RLMRealm *realm = cacheController.store.realm;
            RLMResults<SKYMessageCacheObject *> *results =
                [SKYMessageCacheObject objectsInRealm:realm where:@"recordID == %@", @"m1"];
            expect(results.count).to.equal(0);
        });

        it(@"delete non-existed message", ^{
            SKYMessage *message = [[SKYMessage alloc]
                initWithRecordData:[SKYRecord recordWithRecordType:@"message" name:@"hello"]];

            [cacheController didDeleteMessage:message];

            RLMRealm *realm = cacheController.store.realm;
            RLMResults<SKYMessageCacheObject *> *results =
                [SKYMessageCacheObject allObjectsInRealm:realm];
            expect(results.count).to.equal(10);
        });
    });

describe(@"Cache Controller handle change event", ^{
    __block SKYChatCacheController *cacheController = nil;
    __block NSDate *baseDate = nil;

    beforeEach(^{
        cacheController = [[SKYChatCacheController alloc]
            initWithStore:[[SKYChatCacheRealmStore alloc] initInMemoryWithName:@"ChatTest"]];
        baseDate = [NSDate dateWithTimeIntervalSince1970:0];
    });

    afterEach(^{
        RLMRealm *realm = cacheController.store.realm;
        [realm transactionWithBlock:^{
            [realm deleteAllObjects];
        }];
    });

    it(@"message create, update and delete", ^{
        RLMRealm *realm = cacheController.store.realm;

        // create
        SKYMessage *message = [[SKYMessage alloc]
            initWithRecordData:[SKYRecord recordWithRecordType:@"message" name:@"m1"]];
        message.record[@"edited_at"] = baseDate;

        [cacheController handleChangeEvent:SKYChatRecordChangeEventCreate forMessage:message];

        RLMResults<SKYMessageCacheObject *> *results =
            [SKYMessageCacheObject allObjectsInRealm:realm];
        expect(results.count).to.equal(1);
        expect([results objectAtIndex:0].editionDate).to.equal(baseDate);

        // update
        message = [[SKYMessage alloc]
            initWithRecordData:[SKYRecord recordWithRecordType:@"message" name:@"m1"]];
        message.record[@"edited_at"] = [baseDate dateByAddingTimeInterval:1000];

        [cacheController handleChangeEvent:SKYChatRecordChangeEventUpdate forMessage:message];

        results = [SKYMessageCacheObject allObjectsInRealm:realm];
        expect(results.count).to.equal(1);
        expect([results objectAtIndex:0].editionDate)
            .to.equal([baseDate dateByAddingTimeInterval:1000]);

        // delete
        message = [[SKYMessage alloc]
            initWithRecordData:[SKYRecord recordWithRecordType:@"message" name:@"m1"]];

        [cacheController handleChangeEvent:SKYChatRecordChangeEventDelete forMessage:message];

        results = [SKYMessageCacheObject allObjectsInRealm:realm];
        expect(results.count).to.equal(0);
    });

    it(@"non-existing message updated", ^{
        RLMRealm *realm = cacheController.store.realm;
        SKYMessage *message = [[SKYMessage alloc]
            initWithRecordData:[SKYRecord recordWithRecordType:@"message" name:@"m1"]];
        message.record[@"edited_at"] = [baseDate dateByAddingTimeInterval:1000];

        [cacheController handleChangeEvent:SKYChatRecordChangeEventUpdate forMessage:message];

        RLMResults<SKYMessageCacheObject *> *results =
            [SKYMessageCacheObject allObjectsInRealm:realm];
        expect(results.count).to.equal(1);
        expect([results objectAtIndex:0].editionDate)
            .to.equal([baseDate dateByAddingTimeInterval:1000]);
    });

    it(@"non-existing message deleted", ^{
        RLMRealm *realm = cacheController.store.realm;
        SKYMessage *message = [[SKYMessage alloc]
            initWithRecordData:[SKYRecord recordWithRecordType:@"message" name:@"m1"]];

        [cacheController handleChangeEvent:SKYChatRecordChangeEventDelete forMessage:message];

        // Nothing happened
        RLMResults<SKYMessageCacheObject *> *results =
            [SKYMessageCacheObject allObjectsInRealm:realm];
        expect(results.count).to.equal(0);
    });
});

SpecEnd
