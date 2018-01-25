//
//  SKYChatExtensionTests.m
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
#import "SKYChatExtension.h"
#import "SKYChatExtension_Private.h"
#import <OHHTTPStubs/OHHTTPStubs.h>

#import "SKYConversation.h"
#import "SKYMessageCacheObject.h"
#import "SKYMessageOperationCacheObject.h"
#import "SKYMessageOperation_Private.h"

SpecBegin(SKYChatExtension)

    describe(@"Conversation messages", ^{
        __block SKYChatCacheController *cacheController = nil;
        __block SKYChatExtension *chatExtension = nil;
        __block NSDate *baseDate = nil;

        beforeEach(^{
            cacheController = [[SKYChatCacheController alloc]
                initWithStore:[[SKYChatCacheRealmStore alloc] initInMemoryWithName:@"ChatTest"]];
            baseDate = [NSDate dateWithTimeIntervalSince1970:0];
            [SKYContainer defaultContainer].endPointAddress =
                [NSURL URLWithString:@"https://test.skygeario.com/"];
            chatExtension =
                [[SKYChatExtension alloc] initWithContainer:[SKYContainer defaultContainer]
                                            cacheController:cacheController];

            // Setup cache
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
                    referenceWithRecordID:[SKYRecordID recordIDWithRecordType:@"conversation"
                                                                         name:@"c0"]];
                message.creationDate = [baseDate dateByAddingTimeInterval:i * 1000];
                message.record[@"edited_at"] = [baseDate dateByAddingTimeInterval:i * 2000];
                message.record[@"seq"] = @(i);

                SKYMessageCacheObject *messageCacheObject =
                    [SKYMessageCacheObject cacheObjectFromMessage:message];
                [messages addObject:messageCacheObject];
            }

            RLMRealm *realm = cacheController.store.realmInstance;
            [realm transactionWithBlock:^{
                [realm addObjects:messages];
            }];

            // Setup network stub
            [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
                NSArray<NSString *> *components = request.URL.pathComponents;
                return [components[components.count - 2] isEqualToString:@"chat"] &&
                       [components.lastObject isEqualToString:@"get_messages"];
            }
                withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
                    NSInteger messageCount = 10;
                    NSMutableArray *results = [NSMutableArray arrayWithCapacity:messageCount];
                    for (NSInteger i = 0; i < messageCount; i++) {
                        NSDictionary *result = @{
                            @"_access" : [NSNull null],
                            @"_created_at" :
                                [NSString stringWithFormat:@"2017-12-%ldT00:00:00.000000Z", 9 - i],
                            @"_created_by" : @"u1",
                            @"_id" : [NSString stringWithFormat:@"message/m%ld", 19 - i],
                            @"_ownerID" : @"u1",
                            @"_updated_at" :
                                [NSString stringWithFormat:@"2017-12-%ldT00:00:00.000000Z", 9 - i],
                            @"_updated_by" : @"u1",
                            @"body" : [NSString stringWithFormat:@"message %ld", 9 - i],
                            @"conversation" : @{@"$id" : @"conversation/c0", @"$type" : @"ref"},
                            @"deleted" : @NO,
                            @"edited_at" : @{
                                @"$date" : [NSString
                                    stringWithFormat:@"2017-12-%ldT00:00:00.000000Z", 9 - i],
                                @"$type" : @"date"
                            },
                            @"edited_by" : @{@"$id" : @"user/u1", @"$type" : @"ref"},
                            @"revision" : @1,
                            @"seq" : @(19 - i),
                        };
                        [results addObject:result];
                    }

                    NSDictionary *parameters = @{
                        @"result" : @{
                            @"results" : results,
                        },
                    };
                    NSData *payload =
                        [NSJSONSerialization dataWithJSONObject:parameters options:0 error:nil];

                    return
                        [OHHTTPStubsResponse responseWithData:payload statusCode:200 headers:@{}];
                }];

            [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
                NSArray<NSString *> *components = request.URL.pathComponents;
                return [components[components.count - 2] isEqualToString:@"record"] &&
                       [components.lastObject isEqualToString:@"save"];
            }
                withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
                    NSDictionary *result = @{
                        @"_type" : @"record",
                        @"_access" : [NSNull null],
                        @"_created_at" : @"2017-12-25T00:00:00.000000Z",
                        @"_created_by" : @"u1",
                        @"_id" : @"message/mm1",
                        @"_ownerID" : @"u1",
                        @"_updated_at" : @"2017-12-25T00:00:00.000000Z",
                        @"_updated_by" : @"u1",
                        @"body" : @"new message 1",
                        @"conversation" : @{@"$id" : @"conversation/c0", @"$type" : @"ref"},
                        @"deleted" : @NO,
                        @"edited_at" :
                            @{@"$date" : @"2017-12-25T00:00:00.000000Z", @"$type" : @"date"},
                        @"edited_by" : @{@"$id" : @"user/u1", @"$type" : @"ref"},
                        @"revision" : @1,
                        @"seq" : @25,
                    };

                    NSDictionary *parameters =
                        @{ @"database_id" : @"_public",
                           @"result" : @[ result ] };
                    NSData *payload =
                        [NSJSONSerialization dataWithJSONObject:parameters options:0 error:nil];

                    return
                        [OHHTTPStubsResponse responseWithData:payload statusCode:200 headers:@{}];
                }];

            [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
                NSArray<NSString *> *components = request.URL.pathComponents;
                return [components[components.count - 2] isEqualToString:@"chat"] &&
                       [components.lastObject isEqualToString:@"delete_message"];
            }
                withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
                    NSDictionary *result = @{
                        @"_access" : [NSNull null],
                        @"_created_at" : @"2017-12-01T00:00:00.000000Z",
                        @"_created_by" : @"u1",
                        @"_id" : @"message/m1",
                        @"_ownerID" : @"u1",
                        @"_updated_at" : @"2017-12-01T00:00:00.000000Z",
                        @"_updated_by" : @"u1",
                        @"conversation" : @{@"$id" : @"conversation/c0", @"$type" : @"ref"},
                        @"deleted" : @YES,
                        @"edited_at" :
                            @{@"$date" : @"2017-12-01T00:00:00.000000Z", @"$type" : @"date"},
                        @"edited_by" : @{@"$id" : @"user/u1", @"$type" : @"ref"},
                        @"revision" : @1,
                        @"seq" : @1,
                    };

                    NSDictionary *parameters = @{ @"result" : result };
                    NSData *payload =
                        [NSJSONSerialization dataWithJSONObject:parameters options:0 error:nil];

                    return
                        [OHHTTPStubsResponse responseWithData:payload statusCode:200 headers:@{}];
                }];
        });

        afterEach(^{
            RLMRealm *realm = cacheController.store.realmInstance;
            [realm transactionWithBlock:^{
                [realm deleteAllObjects];
            }];

            [OHHTTPStubs removeAllStubs];
        });

        it(@"fetch messages", ^{
            __block NSInteger checkPoint = 0;
            SKYConversation *conversation = [SKYConversation
                recordWithRecord:[SKYRecord recordWithRecordType:@"conversation" name:@"c0"]];

            void (^checkRealm)() = ^{
                RLMRealm *realm = cacheController.store.realmInstance;
                RLMResults<SKYMessageCacheObject *> *results =
                    [SKYMessageCacheObject allObjectsInRealm:realm];
                expect(results.count).to.equal(20);
            };

            waitUntil(^(DoneCallback done) {
                [chatExtension
                    fetchMessagesWithConversation:conversation
                                            limit:100
                                       beforeTime:nil
                                            order:nil
                                       completion:^(NSArray<SKYMessage *> *_Nullable messageList,
                                                    BOOL isCached, NSError *_Nullable error) {
                                           expect(error).to.beNil();

                                           SKYMessage *message;
                                           if (isCached) {
                                               expect(messageList.count).to.equal(10);
                                               for (NSInteger i = 0; i < 10; i++) {
                                                   message = messageList[9 - i];
                                                   NSString *recordID =
                                                       [NSString stringWithFormat:@"m%ld", i];
                                                   expect(message.recordID.recordName)
                                                       .to.equal(recordID);
                                                   expect(message.record[@"seq"]).to.equal(@(i));
                                               }
                                               checkPoint++;
                                           } else {
                                               expect(messageList.count).to.equal(10);
                                               for (NSInteger i = 0; i < 10; i++) {
                                                   message = messageList[9 - i];
                                                   NSString *recordID =
                                                       [NSString stringWithFormat:@"m%ld", 10 + i];
                                                   expect(message.recordID.recordName)
                                                       .to.equal(recordID);
                                                   expect(message.record[@"seq"])
                                                       .to.equal(@(10 + i));
                                               }
                                               checkPoint++;
                                           }

                                           if (checkPoint == 2) {
                                               checkRealm();
                                               done();
                                           }
                                       }];
            });
        });

        it(@"save message", ^{
            SKYMessage *message = [SKYMessage
                recordWithRecord:[SKYRecord recordWithRecordType:@"message" name:@"mm1"]];
            SKYConversation *conversation = [SKYConversation
                recordWithRecord:[SKYRecord recordWithRecordType:@"conversation" name:@"c0"]];

            void (^checkRealm)() = ^{
                RLMRealm *realm = cacheController.store.realmInstance;
                RLMResults<SKYMessageCacheObject *> *results =
                    [SKYMessageCacheObject allObjectsInRealm:realm];
                expect(results.count).to.equal(11);
            };

            waitUntil(^(DoneCallback done) {
                [chatExtension
                        addMessage:message
                    toConversation:conversation
                        completion:^(SKYMessage *_Nullable message, NSError *_Nullable error) {
                            expect(error).to.beNil();
                            expect(message.recordID.recordName).to.equal(@"mm1");
                            expect(message.creationDate).toNot.beNil();
                            expect(message.sendDate).to.beNil();
                            checkRealm();
                            done();
                        }];
            });
        });

        it(@"delete message", ^{
            SKYMessage *message = [SKYMessage
                recordWithRecord:[SKYRecord recordWithRecordType:@"message" name:@"m1"]];
            SKYConversation *conversation = [SKYConversation
                recordWithRecord:[SKYRecord recordWithRecordType:@"conversation" name:@"c0"]];

            waitUntil(^(DoneCallback done) {
                [chatExtension deleteMessage:message
                              inConversation:conversation
                                  completion:^(SKYConversation *_Nullable conversation,
                                               NSError *_Nullable error) {
                                      expect(error).to.beNil();

                                      RLMRealm *realm = cacheController.store.realmInstance;
                                      RLMResults<SKYMessageCacheObject *> *results =
                                          [SKYMessageCacheObject allObjectsInRealm:realm];
                                      expect(results.count).to.equal(10);

                                      results = [SKYMessageCacheObject
                                          objectsInRealm:realm
                                                   where:@"deleted == %@", @YES];
                                      expect(results.count).to.equal(1);
                                      done();
                                  }];
            });
        });
    });

describe(@"Conversation messages, with error response", ^{
    __block SKYChatCacheController *cacheController = nil;
    __block SKYChatExtension *chatExtension = nil;
    __block NSDate *baseDate = nil;

    beforeEach(^{
        cacheController = [[SKYChatCacheController alloc]
            initWithStore:[[SKYChatCacheRealmStore alloc] initInMemoryWithName:@"ChatTest"]];
        baseDate = [NSDate dateWithTimeIntervalSince1970:0];
        [SKYContainer defaultContainer].endPointAddress =
            [NSURL URLWithString:@"https://test.skygeario.com/"];
        chatExtension = [[SKYChatExtension alloc] initWithContainer:[SKYContainer defaultContainer]
                                                    cacheController:cacheController];

        // Setup cache
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
                referenceWithRecordID:[SKYRecordID recordIDWithRecordType:@"conversation"
                                                                     name:@"c0"]];
            message.creationDate = [baseDate dateByAddingTimeInterval:i * 1000];
            message.record[@"edited_at"] = [baseDate dateByAddingTimeInterval:i * 2000];
            message.record[@"seq"] = @(i);

            SKYMessageCacheObject *messageCacheObject =
                [SKYMessageCacheObject cacheObjectFromMessage:message];
            [messages addObject:messageCacheObject];
        }

        RLMRealm *realm = cacheController.store.realmInstance;
        [realm transactionWithBlock:^{
            [realm addObjects:messages];
        }];

        // Setup network stub
        [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
            return YES;
        }
            withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
                return
                    [OHHTTPStubsResponse responseWithError:[NSError errorWithDomain:NSURLErrorDomain
                                                                               code:0
                                                                           userInfo:nil]];
            }];
    });

    afterEach(^{
        RLMRealm *realm = cacheController.store.realmInstance;
        [realm transactionWithBlock:^{
            [realm deleteAllObjects];
        }];
    });

    it(@"fetch messages", ^{
        __block NSInteger checkPoint = 0;
        SKYConversation *conversation = [SKYConversation
            recordWithRecord:[SKYRecord recordWithRecordType:@"conversation" name:@"c0"]];

        void (^checkRealm)() = ^{
            RLMRealm *realm = cacheController.store.realmInstance;
            RLMResults<SKYMessageCacheObject *> *results =
                [SKYMessageCacheObject allObjectsInRealm:realm];
            expect(results.count).to.equal(10);
        };

        waitUntil(^(DoneCallback done) {
            [chatExtension
                fetchMessagesWithConversation:conversation
                                        limit:100
                                   beforeTime:nil
                                        order:nil
                                   completion:^(NSArray<SKYMessage *> *_Nullable messageList,
                                                BOOL isCached, NSError *_Nullable error) {
                                       SKYMessage *message;
                                       if (isCached) {
                                           expect(error).to.beNil();
                                           expect(messageList.count).to.equal(10);
                                           for (NSInteger i = 0; i < 10; i++) {
                                               message = messageList[9 - i];
                                               NSString *recordID =
                                                   [NSString stringWithFormat:@"m%ld", i];
                                               expect(message.recordID.recordName)
                                                   .to.equal(recordID);
                                               expect(message.record[@"seq"]).to.equal(@(i));
                                           }
                                           checkPoint++;
                                       } else {
                                           expect(messageList.count).to.equal(0);
                                           expect(error).toNot.beNil();
                                           checkPoint++;
                                       }

                                       if (checkPoint == 2) {
                                           checkRealm();
                                           done();
                                       }
                                   }];
        });
    });

    it(@"save message", ^{
        SKYMessage *message =
            [SKYMessage recordWithRecord:[SKYRecord recordWithRecordType:@"message" name:@"mm1"]];
        SKYConversation *conversation = [SKYConversation
            recordWithRecord:[SKYRecord recordWithRecordType:@"conversation" name:@"c0"]];

        waitUntil(^(DoneCallback done) {
            RLMRealm *realm = cacheController.store.realmInstance;

            [chatExtension addMessage:message
                       toConversation:conversation
                           completion:^(SKYMessage *_Nullable message, NSError *_Nullable error) {
                               expect(message).to.beNil();
                               expect(error).toNot.beNil();

                               RLMResults<SKYMessageOperationCacheObject *> *results =
                                   [SKYMessageOperationCacheObject allObjectsInRealm:realm];
                               expect(results.count).to.equal(1);
                               SKYMessageOperation *operation = results[0].messageOperation;
                               expect(operation.status).to.equal(SKYMessageOperationStatusFailed);
                               expect(operation.error).toNot.beNil();
                               done();
                           }];

            RLMResults<SKYMessageOperationCacheObject *> *results =
                [SKYMessageOperationCacheObject allObjectsInRealm:realm];
            expect(results.count).to.equal(1);
            expect(results[0].conversationID).to.equal(@"c0");
            SKYMessageOperation *operation = results[0].messageOperation;
            expect(operation.message.recordID).to.equal(message.recordID);
            expect(operation.status).to.equal(SKYMessageOperationStatusPending);
            expect(operation.type).to.equal(SKYMessageOperationTypeAdd);
        });
    });

    it(@"delete message", ^{
        SKYMessage *message =
            [SKYMessage recordWithRecord:[SKYRecord recordWithRecordType:@"message" name:@"m1"]];
        SKYConversation *conversation = [SKYConversation
            recordWithRecord:[SKYRecord recordWithRecordType:@"conversation" name:@"c0"]];

        waitUntil(^(DoneCallback done) {
            RLMRealm *realm = cacheController.store.realmInstance;

            [chatExtension
                 deleteMessage:message
                inConversation:conversation
                    completion:^(SKYConversation *_Nullable conversation,
                                 NSError *_Nullable error) {
                        expect(error).toNot.beNil();

                        RLMResults<SKYMessageOperationCacheObject *> *results =
                            [SKYMessageOperationCacheObject allObjectsInRealm:realm];
                        expect(results.count).to.equal(1);
                        SKYMessageOperation *operation = results[0].messageOperation;
                        expect(operation.status).to.equal(SKYMessageOperationStatusFailed);
                        expect(operation.error).toNot.beNil();
                        done();
                    }];

            RLMResults<SKYMessageOperationCacheObject *> *results =
                [SKYMessageOperationCacheObject allObjectsInRealm:realm];
            expect(results.count).to.equal(1);
            expect(results[0].conversationID).to.equal(@"c0");
            SKYMessageOperation *operation = results[0].messageOperation;
            expect(operation.message.recordID).to.equal(message.recordID);
            expect(operation.status).to.equal(SKYMessageOperationStatusPending);
            expect(operation.type).to.equal(SKYMessageOperationTypeDelete);
        });
    });
});

describe(@"Message Operations", ^{
    __block SKYChatCacheController *cacheController = nil;
    __block SKYChatExtension *chatExtension = nil;
    __block NSDate *baseDate = nil;

    beforeEach(^{
        cacheController = [[SKYChatCacheController alloc]
            initWithStore:[[SKYChatCacheRealmStore alloc] initInMemoryWithName:@"ChatTest"]];
        baseDate = [NSDate dateWithTimeIntervalSince1970:0];
        [SKYContainer defaultContainer].endPointAddress =
            [NSURL URLWithString:@"https://test.skygeario.com/"];
        chatExtension = [[SKYChatExtension alloc] initWithContainer:[SKYContainer defaultContainer]
                                                    cacheController:cacheController];

        // Setup cache
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
                referenceWithRecordID:[SKYRecordID recordIDWithRecordType:@"conversation"
                                                                     name:@"c0"]];
            message.creationDate = [baseDate dateByAddingTimeInterval:i * 1000];
            message.record[@"edited_at"] = [baseDate dateByAddingTimeInterval:i * 2000];
            message.record[@"seq"] = @(i);

            SKYMessageCacheObject *messageCacheObject =
                [SKYMessageCacheObject cacheObjectFromMessage:message];
            [messages addObject:messageCacheObject];
        }

        RLMRealm *realm = cacheController.store.realmInstance;
        [realm transactionWithBlock:^{
            [realm addObjects:messages];
        }];

        // Setup network stub
        [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
            return YES;
        }
            withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
                return
                    [OHHTTPStubsResponse responseWithError:[NSError errorWithDomain:NSURLErrorDomain
                                                                               code:0
                                                                           userInfo:nil]];
            }];
    });

    afterEach(^{
        RLMRealm *realm = cacheController.store.realmInstance;
        [realm transactionWithBlock:^{
            [realm deleteAllObjects];
        }];

        [OHHTTPStubs removeAllStubs];
    });

    it(@"fetch message operations", ^{
        SKYMessageOperation *operation =
            [[SKYMessageOperation alloc] initWithMessage:[SKYMessage message]
                                          conversationID:@"c0"
                                                    type:SKYMessageOperationTypeAdd];
        operation.status = SKYMessageOperationStatusFailed;
        [cacheController.store setMessageOperations:@[ operation ]];

        waitUntil(^(DoneCallback done) {
            [chatExtension
                fetchOutstandingMessageOperationsWithConverstionID:@"c0"
                                                     operationType:SKYMessageOperationTypeAdd
                                                        completion:^(NSArray<SKYMessageOperation *>
                                                                         *messageOperations) {
                                                            expect(messageOperations)
                                                                .to.haveCount(1);
                                                            expect(messageOperations[0].operationID)
                                                                .to.equal(operation.operationID);
                                                            done();
                                                        }];
        });
    });

    it(@"cancel message operations", ^{
        SKYMessageOperation *operation =
            [[SKYMessageOperation alloc] initWithMessage:[SKYMessage message]
                                          conversationID:@"c0"
                                                    type:SKYMessageOperationTypeAdd];
        operation.status = SKYMessageOperationStatusFailed;
        [cacheController.store setMessageOperations:@[ operation ]];

        [chatExtension cancelMessageOperation:operation];
        RLMRealm *realm = cacheController.store.realmInstance;
        expect([SKYMessageOperationCacheObject allObjectsInRealm:realm]).to.haveCount(0);
    });

    it(@"retry save message operations", ^{
        SKYMessageOperation *operation =
            [[SKYMessageOperation alloc] initWithMessage:[SKYMessage message]
                                          conversationID:@"c0"
                                                    type:SKYMessageOperationTypeAdd];
        operation.status = SKYMessageOperationStatusFailed;
        [cacheController.store setMessageOperations:@[ operation ]];

        [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
            NSArray<NSString *> *components = request.URL.pathComponents;
            return [components[components.count - 2] isEqualToString:@"record"] &&
                   [components.lastObject isEqualToString:@"save"];
        }
            withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
                NSDictionary *result = @{
                    @"_type" : @"record",
                    @"_access" : [NSNull null],
                    @"_created_at" : @"2017-12-25T00:00:00.000000Z",
                    @"_created_by" : @"u1",
                    @"_id" : @"message/mm1",
                    @"_ownerID" : @"u1",
                    @"_updated_at" : @"2017-12-25T00:00:00.000000Z",
                    @"_updated_by" : @"u1",
                    @"body" : @"new message 1",
                    @"conversation" : @{@"$id" : @"conversation/c0", @"$type" : @"ref"},
                    @"deleted" : @NO,
                    @"edited_at" : @{@"$date" : @"2017-12-25T00:00:00.000000Z", @"$type" : @"date"},
                    @"edited_by" : @{@"$id" : @"user/u1", @"$type" : @"ref"},
                    @"revision" : @1,
                    @"seq" : @25,
                };

                NSDictionary *parameters =
                    @{ @"database_id" : @"_public",
                       @"result" : @[ result ] };
                NSData *payload =
                    [NSJSONSerialization dataWithJSONObject:parameters options:0 error:nil];

                return [OHHTTPStubsResponse responseWithData:payload statusCode:200 headers:@{}];
            }];

        waitUntil(^(DoneCallback done) {
            [chatExtension
                retryMessageOperation:operation
                           completion:^(SKYMessageOperation *messageOperation, SKYMessage *message,
                                        NSError *error) {
                               RLMRealm *realm = cacheController.store.realmInstance;
                               expect([SKYMessageOperationCacheObject allObjectsInRealm:realm])
                                   .to.haveCount(0);
                               done();
                           }];
        });
    });

    it(@"retry delete message operations", ^{
        SKYMessageOperation *operation =
            [[SKYMessageOperation alloc] initWithMessage:[SKYMessage message]
                                          conversationID:@"c0"
                                                    type:SKYMessageOperationTypeDelete];
        operation.status = SKYMessageOperationStatusFailed;
        [cacheController.store setMessageOperations:@[ operation ]];

        [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
            NSArray<NSString *> *components = request.URL.pathComponents;
            return [components[components.count - 2] isEqualToString:@"chat"] &&
                   [components.lastObject isEqualToString:@"delete_message"];
        }
            withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
                NSDictionary *result = @{
                    @"_access" : [NSNull null],
                    @"_created_at" : @"2017-12-01T00:00:00.000000Z",
                    @"_created_by" : @"u1",
                    @"_id" : @"message/m1",
                    @"_ownerID" : @"u1",
                    @"_updated_at" : @"2017-12-01T00:00:00.000000Z",
                    @"_updated_by" : @"u1",
                    @"conversation" : @{@"$id" : @"conversation/c0", @"$type" : @"ref"},
                    @"deleted" : @YES,
                    @"edited_at" : @{@"$date" : @"2017-12-01T00:00:00.000000Z", @"$type" : @"date"},
                    @"edited_by" : @{@"$id" : @"user/u1", @"$type" : @"ref"},
                    @"revision" : @1,
                    @"seq" : @1,
                };

                NSDictionary *parameters = @{ @"result" : result };
                NSData *payload =
                    [NSJSONSerialization dataWithJSONObject:parameters options:0 error:nil];

                return [OHHTTPStubsResponse responseWithData:payload statusCode:200 headers:@{}];
            }];

        waitUntil(^(DoneCallback done) {
            [chatExtension
                retryMessageOperation:operation
                           completion:^(SKYMessageOperation *messageOperation, SKYMessage *message,
                                        NSError *error) {
                               RLMRealm *realm = cacheController.store.realmInstance;
                               expect([SKYMessageOperationCacheObject allObjectsInRealm:realm])
                                   .to.haveCount(0);
                               done();
                           }];
        });
    });
});

SpecEnd
