//
//  SKYUserConversation.m
//  Pods
//
//  Created by Andrew Chung on 7/26/16.
//
//

#import "SKYUserConversation.h"
#import "SKYConversation.h"
#import "SKYMessage.h"

NSString *const SKYUserConversationLastReadMessageKey = @"last_read_message";
NSString *const SKYUserConversationUnreadCountKey = @"unread_count";

@implementation SKYUserConversation

+ (instancetype)recordWithRecord:(SKYRecord *)record
{
    SKYUserConversation *newRecord = [self recordWithRecord:record];
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
