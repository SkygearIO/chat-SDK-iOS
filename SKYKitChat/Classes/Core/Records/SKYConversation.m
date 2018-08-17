//
//  SKYConversation.m
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

#import "SKYConversation.h"
#import "SKYChatRecord.h"
#import "SKYMessage.h"

NSString *const SKYConversationParticipantsKey = @"participant_ids";
NSString *const SKYConversationAdminsKey = @"admin_ids";
NSString *const SKYConversationTitleKey = @"title";
NSString *const SKYConversationDistinctByParticipantsKey = @"distinct_by_participants";
NSString *const SKYConversationMetadataKey = @"metadata";
NSString *const SKYConversationLastMessageIDKey = @"last_message_ref";
NSString *const SKYConversationLastReadMessageIDKey = @"last_read_message_ref";
NSString *const SKYConversationLastMessageKey = @"last_message";
NSString *const SKYConversationLastReadMessageKey = @"last_read_message";
NSString *const SKYConversationUnreadCountKey = @"unread_count";

@implementation SKYConversation : SKYChatRecord
+ (instancetype)recordWithRecord:(SKYRecord *)record
{
    SKYConversation *conversation = [[SKYConversation alloc] initWithRecordData:record];
    SKYRecordDeserializer *deserializer = [SKYRecordDeserializer deserializer];

    // type of lastMessage maybe SKYReference or NSDictionary, only deserialize
    // when it is NSDictionary
    id lastMessage = conversation.record[SKYConversationLastMessageKey];
    if ([lastMessage isKindOfClass:[NSDictionary class]]) {
        conversation.lastMessage =
            [SKYMessage recordWithRecord:[deserializer recordWithDictionary:lastMessage]];
    }

    // type of lastReadMessage maybe SKYReference or NSDictionary, only deserialize
    // when it is NSDictionary
    id lastReadMessage = conversation.record[SKYConversationLastReadMessageKey];
    if ([lastReadMessage isKindOfClass:[NSDictionary class]]) {
        conversation.lastReadMessage =
            [SKYMessage recordWithRecord:[deserializer recordWithDictionary:lastReadMessage]];
    }

    return conversation;
}

+ (NSArray<NSString *> *)restrictedFieldKeys
{
    static NSArray<NSString *> *_restrictedFieldKeys;
    if (!_restrictedFieldKeys) {
        // this list is retrieved from:
        //   https://github.com/SkygearIO/chat/blob/1.6.0-3/chat/conversation_handlers.py#L211
        _restrictedFieldKeys = @[
            SKYConversationLastReadMessageIDKey, SKYConversationLastMessageKey,
            SKYConversationAdminsKey, SKYConversationLastReadMessageKey,
            SKYConversationUnreadCountKey, SKYConversationLastMessageIDKey,
            SKYConversationParticipantsKey
        ];
    }

    return _restrictedFieldKeys;
}

- (SKYRecord *)recordForSave
{
    NSMutableDictionary<NSString *, id> *recordDict =
        [[[SKYRecordSerializer serializer] dictionaryWithRecord:self.record] mutableCopy];
    [recordDict removeObjectsForKeys:[SKYConversation restrictedFieldKeys]];

    return [[SKYRecordDeserializer deserializer] recordWithDictionary:recordDict];
}

- (NSArray<NSString *> *)participantIds
{
    NSArray *admins = self.record[SKYConversationParticipantsKey];
    return admins ? admins : [NSArray array];
}

- (NSArray<NSString *> *)adminIds
{
    NSArray *admins = self.record[SKYConversationAdminsKey];
    return admins ? admins : [NSArray array];
}

- (void)setTitle:(NSString *)title
{
    self.record[SKYConversationTitleKey] = [title copy];
}

- (NSString *)title
{
    return self.record[SKYConversationTitleKey];
}

- (void)setMetadata:(NSDictionary<NSString *, id> *)metadata
{
    self.record[SKYConversationMetadataKey] = [metadata copy];
}

- (NSDictionary<NSString *, id> *)metadata
{
    return self.record[SKYConversationMetadataKey];
}

- (void)setDistinctByParticipants:(BOOL)distinctByParticipants
{
    self.record[SKYConversationDistinctByParticipantsKey] = @(distinctByParticipants);
}

- (BOOL)isDistinctByParticipants
{
    return [self.record[SKYConversationDistinctByParticipantsKey] boolValue];
}

- (NSString *)lastMessageID
{
    return [[self.record[SKYConversationLastMessageKey] recordID] recordName];
}

- (NSString *)lastReadMessageID
{
    return [[self.record[SKYConversationLastMessageKey] recordID] recordName];
}

- (NSInteger)unreadCount
{
    return [self.record[SKYConversationUnreadCountKey] integerValue];
}

- (NSString *)toString
{
    return [NSString stringWithFormat:@"SKYConversation Detail:\nparticipantIds: %@\nadminIds: "
                                      @"%@\ntitle: %@\nisDistinctByParticipant: %@\nupdatedAt: %@",
                                      self.participantIds, self.adminIds, self.title,
                                      self.distinctByParticipants ? @"YES" : @"NO",
                                      self.record.modificationDate];
}

- (NSString *)recordName
{
    return self.record.recordID.recordName;
}

- (SKYRecordID *)recordID
{
    return self.record.recordID;
}
@end
