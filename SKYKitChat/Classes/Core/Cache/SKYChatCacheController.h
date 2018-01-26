//
//  SKYChatCacheController.h
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

#import <Foundation/Foundation.h>

#import "SKYChatExtension.h"
#import "SKYMessage.h"
#import "SKYMessageOperation.h"

@interface SKYChatCacheController : NSObject

+ (instancetype)defaultController;

- (void)fetchMessagesWithConversationID:(NSString *)conversationId
                                  limit:(NSInteger)limit
                             beforeTime:(NSDate *)beforeTime
                                  order:(NSString *)order
                             completion:(SKYChatFetchMessagesListCompletion)completion;

- (void)fetchMessagesWithConversationID:(NSString *)conversationId
                                  limit:(NSInteger)limit
                        beforeMessageID:(NSString *)beforeMessageID
                                  order:(NSString *)order
                             completion:(SKYChatFetchMessagesListCompletion)completion;

- (void)fetchMessagesWithIDs:(NSArray<NSString *> *)messageIDs
                  completion:(SKYChatFetchMessagesListCompletion)completion;

- (void)didFetchMessages:(NSArray<SKYMessage *> *)messages
         deletedMessages:(NSArray<SKYMessage *> *)deletedMessages;

- (void)didSaveMessage:(SKYMessage *)message;

- (void)didDeleteMessage:(SKYMessage *)message;

- (void)handleRecordChange:(SKYChatRecordChange *)recordChange;

NS_ASSUME_NONNULL_BEGIN

- (void)fetchMessageOperationsWithConversationID:(NSString *)conversationId
                                   operationType:(SKYMessageOperationType)type
                                      completion:
                                          (SKYChatFetchMessageOperationsListCompletion)completion;

- (void)fetchMessageOperationsWithMessageID:(NSString *)messageId
                              operationType:(SKYMessageOperationType)type
                                 completion:(SKYChatFetchMessageOperationsListCompletion)completion;

- (SKYMessageOperation *)didStartMessage:(SKYMessage *)message
                          conversationID:(NSString *)conversationID
                           operationType:(SKYMessageOperationType)operationType;

- (void)didCompleteMessageOperation:(SKYMessageOperation *)messageOperation;

- (void)didFailMessageOperation:(SKYMessageOperation *)messageOperation error:(NSError *)error;

- (void)didCancelMessageOperation:(SKYMessageOperation *)messageOperation;

NS_ASSUME_NONNULL_END
@end
