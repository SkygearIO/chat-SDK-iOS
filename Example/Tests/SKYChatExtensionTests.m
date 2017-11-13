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
#import "SKYChatExtension.h"
#import "SKYChatExtension_Private.h"
#import <OHHTTPStubs/OHHTTPStubs.h>

#import "SKYConversation.h"
#import "SKYMessageCacheObject.h"

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

            RLMRealm *realm = cacheController.store.realm;
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
        });

        afterEach(^{
            RLMRealm *realm = cacheController.store.realm;
            [realm transactionWithBlock:^{
                [realm deleteAllObjects];
            }];
        });

        it(@"fetch messages", ^{
            __block NSInteger checkPoint = 0;
            SKYConversation *conversation = [SKYConversation
                recordWithRecord:[SKYRecord recordWithRecordType:@"conversation" name:@"c0"]];

            void (^checkRealm)() = ^{
                RLMRealm *realm = cacheController.store.realm;
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
                                       completion:^(
                                           NSArray<SKYMessage *> *_Nullable messageList,
                                           NSArray<SKYMessage *> *_Nullable deletedMessageList,
                                           BOOL isCached, NSError *_Nullable error) {
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
    });

SpecEnd
