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

@implementation SKYConversation

+ (instancetype)recordWithRecord:(SKYRecord *)record
{
    return [super recordWithRecord:record];
}

- (void)setParticipantIds:(NSArray<NSString *> *)participantIds
{
    self[SKYConversationParticipantsKey] = [[NSSet setWithArray:participantIds] allObjects];
}

- (NSArray<NSString *> *)participantIds
{
    NSArray *admins = self[SKYConversationParticipantsKey];
    return admins ? admins : [NSArray array];
}

- (void)setAdminIds:(NSArray<NSString *> *)adminIds
{
    self[SKYConversationAdminsKey] = [[NSSet setWithArray:adminIds] allObjects];
}

- (NSArray<NSString *> *)adminIds
{
    NSArray *admins = self[SKYConversationAdminsKey];
    return admins ? admins : [NSArray array];
}

- (void)setTitle:(NSString *)title
{
    self[SKYConversationTitleKey] = [title copy];
}

- (NSString *)title
{
    return self[SKYConversationTitleKey];
}

- (void)setMetadata:(NSDictionary<NSString *, id> *)metadata
{
    self[SKYConversationMetadataKey] = [metadata copy];
}

- (NSDictionary<NSString *, id> *)metadata
{
    return self[SKYConversationMetadataKey];
}

- (void)setDistinctByParticipants:(BOOL)distinctByParticipants
{
    self[SKYConversationDistinctByParticipantsKey] = @(distinctByParticipants);
}

- (BOOL)isDistinctByParticipants
{
    return [self[SKYConversationDistinctByParticipantsKey] boolValue];
}

- (NSString *)lastMessageID {
    return [[self[SKYConversationLastMessageKey] recordID] recordName];
}

- (void)setLastMessage:(SKYMessage * _Nullable)lastMessage {
    _lastMessage = lastMessage;
}

- (NSString *)toString
{
    return [NSString stringWithFormat:@"SKYConversation Detail:\nparticipantIds: %@\nadminIds: "
                                      @"%@\ntitle: %@\nisDistinctByParticipant: %@\nupdatedAt: %@",
                                      self.participantIds, self.adminIds, self.title,
                                      self.distinctByParticipants ? @"YES" : @"NO",
                                      self.modificationDate];
}

- (void)addParticipantsWithUserIDs:(NSString *)userIDs
{
    [self setParticipantIds:[self.participantIds arrayByAddingObjectsFromArray:userIDs]];
}

- (void)removeParticipantsWithUserIDs:(NSString *)userIDs
{
    NSMutableArray *participants = [self.participantIds mutableCopy];
    [participants removeObjectsInArray:userIDs];
    [self setParticipantIds:participants];
}

- (void)addAdminsWithUserIDs:(NSString *)userIDs
{
    [self setAdminIds:[self.adminIds arrayByAddingObjectsFromArray:userIDs]];
}

- (void)removeAdminsWithUserIDs:(NSString *)userIDs
{
    NSMutableArray *admins = [self.adminIds mutableCopy];
    [admins removeObjectsInArray:userIDs];
    [self setAdminIds:admins];
}

@end
