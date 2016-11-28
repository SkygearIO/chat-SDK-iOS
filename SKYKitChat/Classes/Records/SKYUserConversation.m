//
//  SKYUserConversation.m
//  SKYKit
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

#import "SKYUserConversation.h"
#import "SKYConversation.h"
#import "SKYMessage.h"

NSString *const SKYUserConversationLastReadMessageKey = @"last_read_message";
NSString *const SKYUserConversationUnreadCountKey = @"unread_count";

@implementation SKYUserConversation

+ (instancetype)recordWithRecord:(SKYRecord *)record
{
    SKYUserConversation *newRecord = [super recordWithRecord:record];
    [newRecord assignVariableInTransientWithRecord:record];
    return newRecord;
}

- (void)assignVariableInTransientWithRecord:(SKYRecord *)record
{
    SKYRecord *userRecord = [record.transient valueForKey:@"user"];
    SKYRecord *conversationRecord = [record.transient valueForKey:@"conversation"];
    SKYRecord *lastReadMessage = [record.transient valueForKey:@"last_read_message"];
    if (userRecord != (id)[NSNull null]) {
        _userRecord = userRecord;
    }
    if (conversationRecord != (id)[NSNull null]) {
        _conversation = [SKYConversation recordWithRecord:conversationRecord];
    }
    if (lastReadMessage != (id)[NSNull null]) {
        _lastReadMessage = [SKYMessage recordWithRecord:lastReadMessage];
    }
}

- (NSString *)lastReadMessageID
{
    SKYReference *message = self[SKYUserConversationLastReadMessageKey];
    return message.recordID.recordName;
}

- (void)setLastReadMessageID:(NSString *)lastReadMessageID
{
    if (lastReadMessageID) {
        SKYRecordID *recordID =
            [SKYRecordID recordIDWithRecordType:@"message" name:lastReadMessageID];
        self[SKYUserConversationLastReadMessageKey] = [SKYReference referenceWithRecordID:recordID];
    } else {
        self[SKYUserConversationLastReadMessageKey] = nil;
    }

    _lastReadMessage = nil;
}

- (NSInteger)unreadCount
{
    return [self[SKYUserConversationUnreadCountKey] integerValue];
}

@end
