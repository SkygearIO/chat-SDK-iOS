//
//  SKYMessageOperation.m
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

#import "SKYMessageOperation.h"
#import "SKYMessageOperation_Private.h"

@implementation SKYMessageOperation

- (instancetype)initWithOperationID:(NSString *)operationID
                            message:(SKYMessage *)message
                     conversationID:(NSString *)conversationID
                               type:(SKYMessageOperationType)type
                             status:(SKYMessageOperationStatus)status
                           sendDate:(NSDate *)sendDate
                              error:(NSError *)error
{
    if ((self = [super init])) {
        _operationID = [operationID copy];
        _message = message;
        _conversationID = [conversationID copy];
        _type = type;
        _status = status;
        _sendDate = [sendDate copy];
        _error = [error copy];
    }
    return self;
}

- (instancetype)initWithMessage:(SKYMessage *)message
                 conversationID:(NSString *)conversationID
                           type:(SKYMessageOperationType)type
{
    return [self initWithOperationID:[[NSUUID UUID] UUIDString]
                             message:message
                      conversationID:conversationID
                                type:type
                              status:SKYMessageOperationStatusPending
                            sendDate:[NSDate date]
                               error:nil];
}

- (id)init
{
    @throw [NSException exceptionWithName:NSInvalidArgumentException
                                   reason:@"message is required"
                                 userInfo:nil];
}

@end
