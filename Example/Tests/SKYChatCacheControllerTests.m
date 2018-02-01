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
#import "SKYChatCacheRealmStore+Private.h"
#import "SKYChatRecordChange_Private.h"

#import "SKYMessageCacheObject.h"
#import "SKYMessageOperationCacheObject.h"

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
                message.record[@"seq"] = [NSNumber numberWithLong:i];
                SKYMessageCacheObject *messageCacheObject =
                    [SKYMessageCacheObject cacheObjectFromMessage:message];
                [messages addObject:messageCacheObject];
            }

            RLMRealm *realm = cacheController.store.realmInstance;
            [realm transactionWithBlock:^{
                [realm addObjects:messages];
            }];
        });

        afterEach(^{
            RLMRealm *realm = cacheController.store.realmInstance;
            [realm transactionWithBlock:^{
                [realm deleteAllObjects];
            }];
        });

        it(@"fetch message by beforeMessage", ^{
            [cacheController
                fetchMessagesWithConversationID:@"c1"
                                          limit:100
                                beforeMessageID:@"m7"
                                          order:nil
                                     completion:^(NSArray<SKYMessage *> *_Nullable messageList,
                                                  BOOL isCached, NSError *_Nullable error) {
                                         expect(messageList).to.haveLength(3);
                                         expect(messageList[0].seq).to.equal(5);
                                         expect(messageList[1].seq).to.equal(3);
                                         expect(messageList[2].seq).to.equal(1);
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
                [SKYMessageCacheObject allObjectsInRealm:store.realmInstance];
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
                [SKYMessageCacheObject allObjectsInRealm:store.realmInstance];
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
                                     completion:^(NSArray<SKYMessage *> *messageList, BOOL isCached,
                                                  NSError *error) {
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
                                     completion:^(NSArray<SKYMessage *> *messageList, BOOL isCached,
                                                  NSError *error) {
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
                long j = (i + 3) * 2;
                SKYMessage *message = [[SKYMessage alloc]
                    initWithRecordData:[SKYRecord
                                           recordWithRecordType:@"message"
                                                           name:[NSString
                                                                    stringWithFormat:@"m%ld", j]]];
                message.conversationRef = [SKYReference
                    referenceWithRecordID:[SKYRecordID recordIDWithRecordType:@"conversation"
                                                                         name:@"c0"]];
                message.creationDate = [baseDate dateByAddingTimeInterval:(i + 3) * 2000];
                message.record[@"edited_at"] = [baseDate dateByAddingTimeInterval:50000];
                message.body = @"fetched message";
                message.record[@"seq"] = [NSNumber numberWithLong:j];
                [messages addObject:message];
            }

            SKYMessage *deletedMessage = [[SKYMessage alloc]
                initWithRecordData:[SKYRecord recordWithRecordType:@"message"
                                                              name:@"m0"
                                                              data:@{
                                                                  @"deleted" : @YES
                                                              }]];
            deletedMessage.conversationRef = [SKYReference
                referenceWithRecordID:[SKYRecordID recordIDWithRecordType:@"conversation"
                                                                     name:@"c0"]];

            [cacheController didFetchMessages:messages deletedMessages:@[ deletedMessage ]];

            SKYChatCacheRealmStore *store = cacheController.store;
            RLMResults<SKYMessageCacheObject *> *results =
                [SKYMessageCacheObject objectsInRealm:store.realmInstance
                                                where:@"conversationID == %@", @"c0"];
            expect(results.count).to.equal(8);

            results = [SKYMessageCacheObject
                objectsInRealm:store.realmInstance
                         where:@"editionDate == %@", [baseDate dateByAddingTimeInterval:50000]];
            expect(results.count).to.equal(5);

            // simulate next time fetch result from cache
            [cacheController
                fetchMessagesWithConversationID:@"c0"
                                          limit:100
                                     beforeTime:nil
                                          order:nil
                                     completion:^(NSArray<SKYMessage *> *messageList, BOOL isCached,
                                                  NSError *error) {
                                         expect(messageList.count).to.equal(7);
                                         for (NSInteger i = 1; i < 8; i++) {
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
            messageToSave.body = @"new message";
            messageToSave.sendDate = [baseDate dateByAddingTimeInterval:50000];

            [cacheController didSaveMessage:messageToSave];
            RLMRealm *realm = cacheController.store.realmInstance;
            RLMResults<SKYMessageCacheObject *> *results =
                [SKYMessageCacheObject objectsInRealm:realm where:@"recordID == %@", @"mm1"];
            expect(results.count).to.equal(1);
            expect(results[0].recordID).to.equal(messageToSave.recordID.recordName);
            expect(results[0].sendDate).to.equal(messageToSave.sendDate);

            results = [SKYMessageCacheObject allObjectsInRealm:realm];
            expect(results.count).to.equal(11);

            [cacheController
                fetchMessagesWithConversationID:@"c0"
                                          limit:100
                                     beforeTime:nil
                                          order:nil
                                     completion:^(NSArray<SKYMessage *> *messageList, BOOL isCached,
                                                  NSError *error) {
                                         expect(messageList.count).to.equal(5);
                                         for (NSInteger i = 1; i < 5; i++) {
                                             SKYMessage *message = messageList[4 - i];
                                             expect(message.creationDate)
                                                 .to.equal(
                                                     [baseDate dateByAddingTimeInterval:i * 2000]);
                                         }
                                     }];
        });

        it(@"didSave message, update the cache", ^{
            SKYMessage *messageToSave = [[SKYMessage alloc]
                initWithRecordData:[SKYRecord recordWithRecordType:@"message" name:@"mm1"]];
            messageToSave.conversationRef = [SKYReference
                referenceWithRecordID:[SKYRecordID recordIDWithRecordType:@"conversation"
                                                                     name:@"c0"]];
            messageToSave.creationDate = [baseDate dateByAddingTimeInterval:50000];
            messageToSave.record[@"edited_at"] = [baseDate dateByAddingTimeInterval:50000];
            messageToSave.body = @"new message";

            [cacheController didSaveMessage:messageToSave];

            RLMRealm *realm = cacheController.store.realmInstance;
            RLMResults<SKYMessageCacheObject *> *results =
                [SKYMessageCacheObject objectsInRealm:realm where:@"recordID == %@", @"mm1"];
            expect(results.count).to.equal(1);

            SKYMessage *newMessage = [[results objectAtIndex:0] messageRecord];
            expect(newMessage.body).to.equal(messageToSave.body);
        });

        it(@"delete message, update the cache", ^{
            SKYMessage *message = [[SKYMessage alloc]
                initWithRecordData:[SKYRecord recordWithRecordType:@"message"
                                                              name:@"m1"
                                                              data:@{
                                                                  @"deleted" : @YES
                                                              }]];

            [cacheController didDeleteMessage:message];

            RLMRealm *realm = cacheController.store.realmInstance;
            RLMResults<SKYMessageCacheObject *> *results =
                [SKYMessageCacheObject objectsInRealm:realm where:@"recordID == %@", @"m1"];
            expect(results.count).to.equal(1);
            expect(results[0].deleted).to.beTruthy();
        });

        it(@"delete non-existed message", ^{
            SKYMessage *message = [[SKYMessage alloc]
                initWithRecordData:[SKYRecord recordWithRecordType:@"message"
                                                              name:@"hello"
                                                              data:@{
                                                                  @"deleted" : @YES
                                                              }]];

            [cacheController didDeleteMessage:message];

            RLMRealm *realm = cacheController.store.realmInstance;
            RLMResults<SKYMessageCacheObject *> *results =
                [SKYMessageCacheObject allObjectsInRealm:realm];
            expect(results.count).to.equal(11);

            results = [results objectsWhere:@"deleted == TRUE"];
            expect(results.count).to.equal(1);
            expect(results[0].recordID).to.equal(@"hello");
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
        RLMRealm *realm = cacheController.store.realmInstance;
        [realm transactionWithBlock:^{
            [realm deleteAllObjects];
        }];
    });

    it(@"message create, update and delete", ^{
        RLMRealm *realm = cacheController.store.realmInstance;

        // create
        SKYRecord *messageRecord = [SKYRecord recordWithRecordType:@"message" name:@"m1"];
        messageRecord[@"edited_at"] = baseDate;
        [cacheController handleRecordChange:[[SKYChatRecordChange alloc]
                                                initWithEvent:SKYChatRecordChangeEventCreate
                                                       record:messageRecord]];

        RLMResults<SKYMessageCacheObject *> *results =
            [SKYMessageCacheObject allObjectsInRealm:realm];
        expect(results.count).to.equal(1);
        expect([results objectAtIndex:0].editionDate).to.equal(baseDate);

        // update
        messageRecord = [SKYRecord recordWithRecordType:@"message" name:@"m1"];
        messageRecord[@"edited_at"] = [baseDate dateByAddingTimeInterval:1000];
        [cacheController handleRecordChange:[[SKYChatRecordChange alloc]
                                                initWithEvent:SKYChatRecordChangeEventUpdate
                                                       record:messageRecord]];

        results = [SKYMessageCacheObject allObjectsInRealm:realm];
        expect(results.count).to.equal(1);
        expect([results objectAtIndex:0].editionDate)
            .to.equal([baseDate dateByAddingTimeInterval:1000]);

        // delete
        messageRecord =
            [SKYRecord recordWithRecordType:@"message" name:@"m1" data:@{
                @"deleted" : @YES
            }];
        [cacheController handleRecordChange:[[SKYChatRecordChange alloc]
                                                initWithEvent:SKYChatRecordChangeEventDelete
                                                       record:messageRecord]];

        results = [SKYMessageCacheObject allObjectsInRealm:realm];
        expect(results.count).to.equal(1);
        expect(results[0].deleted).to.beTruthy();
    });

    it(@"non-existing message updated", ^{
        RLMRealm *realm = cacheController.store.realmInstance;
        SKYRecord *messageRecord = [SKYRecord recordWithRecordType:@"message" name:@"m1"];
        messageRecord[@"edited_at"] = [baseDate dateByAddingTimeInterval:1000];
        [cacheController handleRecordChange:[[SKYChatRecordChange alloc]
                                                initWithEvent:SKYChatRecordChangeEventUpdate
                                                       record:messageRecord]];

        RLMResults<SKYMessageCacheObject *> *results =
            [SKYMessageCacheObject allObjectsInRealm:realm];
        expect(results.count).to.equal(1);
        expect([results objectAtIndex:0].editionDate)
            .to.equal([baseDate dateByAddingTimeInterval:1000]);
    });

    it(@"non-existing message deleted", ^{
        RLMRealm *realm = cacheController.store.realmInstance;
        SKYRecord *messageRecord =
            [SKYRecord recordWithRecordType:@"message" name:@"m1" data:@{
                @"deleted" : @YES
            }];
        [cacheController handleRecordChange:[[SKYChatRecordChange alloc]
                                                initWithEvent:SKYChatRecordChangeEventDelete
                                                       record:messageRecord]];

        // Nothing happened
        RLMResults<SKYMessageCacheObject *> *results =
            [SKYMessageCacheObject allObjectsInRealm:realm];
        expect(results.count).to.equal(1);
        expect(results[0].deleted).to.beTruthy();
    });
});

describe(@"Cache Controller handle message operations", ^{
    __block SKYChatCacheController *cacheController = nil;
    __block NSDate *baseDate = nil;

    beforeEach(^{
        cacheController = [[SKYChatCacheController alloc]
            initWithStore:[[SKYChatCacheRealmStore alloc] initInMemoryWithName:@"ChatTest"]];
        baseDate = [NSDate dateWithTimeIntervalSince1970:0];
    });

    afterEach(^{
        RLMRealm *realm = cacheController.store.realmInstance;
        [realm transactionWithBlock:^{
            [realm deleteAllObjects];
        }];
    });

    it(@"mark pending messages as failed", ^{
        RLMRealm *realm = cacheController.store.realmInstance;

        SKYMessage *message = [SKYMessage message];

        SKYMessageOperation *operation =
            [cacheController didStartMessage:message
                              conversationID:@"c0"
                               operationType:SKYMessageOperationTypeAdd];
        expect(operation.status).to.equal(SKYMessageOperationStatusPending);
    });

    it(@"start message will create a pending message operation in store", ^{
        RLMRealm *realm = cacheController.store.realmInstance;

        SKYMessage *message = [SKYMessage message];

        SKYMessageOperation *operation =
            [cacheController didStartMessage:message
                              conversationID:@"c0"
                               operationType:SKYMessageOperationTypeAdd];
        expect(operation.status).to.equal(SKYMessageOperationStatusPending);

        SKYMessageOperationCacheObject *cacheObject =
            [SKYMessageOperationCacheObject objectInRealm:realm
                                            forPrimaryKey:operation.operationID];
        SKYMessageOperation *operationInStore = [cacheObject messageOperation];
        expect(operationInStore.status).to.equal(SKYMessageOperationStatusPending);
        expect(operationInStore.type).to.equal(SKYMessageOperationTypeAdd);
        expect(operationInStore.message.recordID).to.equal(message.recordID);
    });

    it(@"start message will with different operation type", ^{
        RLMRealm *realm = cacheController.store.realmInstance;

        SKYMessage *message = [SKYMessage message];

        SKYMessageOperation *operation =
            [cacheController didStartMessage:message
                              conversationID:@"c0"
                               operationType:SKYMessageOperationTypeEdit];

        SKYMessageOperationCacheObject *cacheObject =
            [SKYMessageOperationCacheObject objectInRealm:realm
                                            forPrimaryKey:operation.operationID];
        SKYMessageOperation *operationInStore = [cacheObject messageOperation];
        expect(operationInStore.type).to.equal(SKYMessageOperationTypeEdit);
    });

    it(@"mark message operation as completed", ^{
        RLMRealm *realm = cacheController.store.realmInstance;

        SKYMessageOperation *operation =
            [cacheController didStartMessage:[SKYMessage message]
                              conversationID:@"c0"
                               operationType:SKYMessageOperationTypeAdd];

        [cacheController didCompleteMessageOperation:operation];
        expect(operation.status).to.equal(SKYMessageOperationStatusSuccess);

        SKYMessageOperationCacheObject *cacheObject =
            [SKYMessageOperationCacheObject objectInRealm:realm
                                            forPrimaryKey:operation.operationID];
        expect(cacheObject).to.beNil();
    });

    it(@"mark message operation as cancelled", ^{
        RLMRealm *realm = cacheController.store.realmInstance;

        SKYMessageOperation *operation =
            [cacheController didStartMessage:[SKYMessage message]
                              conversationID:@"c0"
                               operationType:SKYMessageOperationTypeAdd];

        [cacheController didCancelMessageOperation:operation];

        SKYMessageOperationCacheObject *cacheObject =
            [SKYMessageOperationCacheObject objectInRealm:realm
                                            forPrimaryKey:operation.operationID];
        expect(cacheObject).to.beNil();
    });

    it(@"mark message operation as failed", ^{
        RLMRealm *realm = cacheController.store.realmInstance;

        SKYMessageOperation *operation =
            [cacheController didStartMessage:[SKYMessage message]
                              conversationID:@"c0"
                               operationType:SKYMessageOperationTypeAdd];

        NSError *error = [NSError errorWithDomain:NSGenericException code:10000 userInfo:nil];
        [cacheController didFailMessageOperation:operation error:error];
        expect(operation.status).to.equal(SKYMessageOperationStatusFailed);

        SKYMessageOperationCacheObject *cacheObject =
            [SKYMessageOperationCacheObject objectInRealm:realm
                                            forPrimaryKey:operation.operationID];
        SKYMessageOperation *operationInStore = [cacheObject messageOperation];
        expect(operationInStore.status).to.equal(SKYMessageOperationStatusFailed);
        expect(operationInStore.error).to.equal(error);
    });

    it(@"fetch messages by type", ^{
        SKYRecordID *conversationID1 = [SKYRecordID recordIDWithRecordType:@"conversation"];
        SKYRecordID *conversationID2 = [SKYRecordID recordIDWithRecordType:@"conversation"];

        SKYMessage *message1 = [SKYMessage message];
        message1.conversationRef = [SKYReference referenceWithRecordID:conversationID1];
        SKYMessage *message2 = [SKYMessage message];
        message2.conversationRef = [SKYReference referenceWithRecordID:conversationID1];
        SKYMessage *message3 = [SKYMessage message];
        message3.conversationRef = [SKYReference referenceWithRecordID:conversationID2];
        SKYMessage *message4 = [SKYMessage message];
        message4.conversationRef = [SKYReference referenceWithRecordID:conversationID2];

        SKYMessageOperation *operation1 =
            [cacheController didStartMessage:message1
                              conversationID:message1.conversationRef.recordID.recordName
                               operationType:SKYMessageOperationTypeAdd];
        SKYMessageOperation *operation2 =
            [cacheController didStartMessage:message2
                              conversationID:message2.conversationRef.recordID.recordName
                               operationType:SKYMessageOperationTypeEdit];
        SKYMessageOperation *operation3 =
            [cacheController didStartMessage:message3
                              conversationID:message3.conversationRef.recordID.recordName
                               operationType:SKYMessageOperationTypeDelete];
        SKYMessageOperation *operation4 =
            [cacheController didStartMessage:message4
                              conversationID:message4.conversationRef.recordID.recordName
                               operationType:SKYMessageOperationTypeDelete];

        [cacheController
            fetchMessageOperationsWithConversationID:conversationID1.recordName
                                       operationType:SKYMessageOperationTypeAdd
                                          completion:^(NSArray<SKYMessageOperation *>
                                                           *_Nullable messageOperationList) {
                                              expect(messageOperationList).to.haveLength(1);
                                              expect(messageOperationList[0].operationID)
                                                  .to.equal(operation1.operationID);
                                              expect(messageOperationList[0].message.recordID)
                                                  .to.equal(message1.recordID);
                                          }];
        [cacheController
            fetchMessageOperationsWithConversationID:conversationID2.recordName
                                       operationType:SKYMessageOperationTypeAdd
                                          completion:^(NSArray<SKYMessageOperation *>
                                                           *_Nullable messageOperationList) {
                                              expect(messageOperationList).to.haveLength(0);
                                          }];
        [cacheController
            fetchMessageOperationsWithConversationID:conversationID1.recordName
                                       operationType:SKYMessageOperationTypeEdit
                                          completion:^(NSArray<SKYMessageOperation *>
                                                           *_Nullable messageOperationList) {
                                              expect(messageOperationList).to.haveLength(1);
                                              expect(messageOperationList[0].operationID)
                                                  .to.equal(operation2.operationID);
                                              expect(messageOperationList[0].message.recordID)
                                                  .to.equal(message2.recordID);
                                          }];
        [cacheController
            fetchMessageOperationsWithConversationID:conversationID2.recordName
                                       operationType:SKYMessageOperationTypeDelete
                                          completion:^(NSArray<SKYMessageOperation *>
                                                           *_Nullable messageOperationList) {
                                              expect(messageOperationList).to.haveLength(2);

                                              // fetchMessageOperationsWithConversationID:operationType:completion:
                                              // returns operation in descending order of sendDate.
                                              expect(messageOperationList[0].operationID)
                                                  .to.equal(operation4.operationID);
                                              expect(messageOperationList[0].message.recordID)
                                                  .to.equal(message4.recordID);
                                              expect(messageOperationList[1].operationID)
                                                  .to.equal(operation3.operationID);
                                              expect(messageOperationList[1].message.recordID)
                                                  .to.equal(message3.recordID);
                                          }];
    });
});

SpecEnd
