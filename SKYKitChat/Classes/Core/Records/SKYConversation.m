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

NSString *const SKYConversationParticipantsKey = @"participant_ids";
NSString *const SKYConversationAdminsKey = @"admin_ids";
NSString *const SKYConversationTitleKey = @"title";
NSString *const SKYConversationDistinctByParticipantsKey = @"distinct_by_participants";
NSString *const SKYConversationMetadataKey = @"metadata";
NSString *const SKYConversationLastMessageKey = @"last_message";

@implementation SKYConversation : NSObject
+ (instancetype)recordWithRecord:(SKYRecord *)record
                 withUnreadCount:(NSInteger)unreadCount
           withLastReadMessageId:(NSString *)lastReadMessageID
{

    SKYConversation *conversation = [[SKYConversation alloc] init];
    conversation.record = record;
    conversation.unreadCount = unreadCount;
    conversation.lastReadMessageID = lastReadMessageID;
    return conversation;
}

- (void)setParticipantIds:(NSArray<NSString *> *)participantIds
{
    self.record[SKYConversationParticipantsKey] = [[NSSet setWithArray:participantIds] allObjects];
}

- (NSArray<NSString *> *)participantIds
{
    NSArray *admins = self.record[SKYConversationParticipantsKey];
    return admins ? admins : [NSArray array];
}

- (void)setAdminIds:(NSArray<NSString *> *)adminIds
{
    self.record[SKYConversationAdminsKey] = [[NSSet setWithArray:adminIds] allObjects];
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

- (void)setLastMessage:(SKYMessage *_Nullable)lastMessage
{
    _lastMessage = lastMessage;
}

- (NSString *)toString
{
    return [NSString stringWithFormat:@"SKYConversation Detail:\nparticipantIds: %@\nadminIds: "
                                      @"%@\ntitle: %@\nisDistinctByParticipant: %@\nupdatedAt: %@",
                                      self.participantIds, self.adminIds, self.title,
                                      self.distinctByParticipants ? @"YES" : @"NO",
                                      self.record.modificationDate];
}

- (void)addParticipantsWithUserIDs:(NSArray<NSString *> *)userIDs
{
    [self setParticipantIds:[self.participantIds arrayByAddingObjectsFromArray:userIDs]];
}

- (void)removeParticipantsWithUserIDs:(NSArray<NSString *> *)userIDs
{
    NSMutableArray *participants = [self.participantIds mutableCopy];
    [participants removeObjectsInArray:userIDs];
    [self setParticipantIds:participants];
}

- (void)addAdminsWithUserIDs:(NSArray<NSString *> *)userIDs
{
    [self setAdminIds:[self.adminIds arrayByAddingObjectsFromArray:userIDs]];
}

- (void)removeAdminsWithUserIDs:(NSArray<NSString *> *)userIDs
{
    NSMutableArray *admins = [self.adminIds mutableCopy];
    [admins removeObjectsInArray:userIDs];
    [self setAdminIds:admins];
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
