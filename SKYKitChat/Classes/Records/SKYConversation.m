//
//  Conversation.m
//  Pods
//
//  Created by Andrew Chung on 6/1/16.
//
//

#import "SKYConversation.h"

NSString *const SKYConversationParticipantsKey = @"participant_ids";
NSString *const SKYConversationAdminsKey = @"admin_ids";
NSString *const SKYConversationTitleKey = @"title";
NSString *const SKYConversationDistinctByParticipantsKey = @"distinct_by_participants";
NSString *const SKYConversationMetadataKey = @"metadata";

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

- (NSString *)toString
{
    return [NSString stringWithFormat:@"SKYConversation Detail:\nparticipantIds: %@\nadminIds: "
                                      @"%@\ntitle: %@\nisDistinctByParticipant: %@\nupdatedAt: %@",
                                      self.participantIds, self.adminIds, self.title,
                                      self.distinctByParticipants ? @"YES" : @"NO",
                                      self.modificationDate];
}

- (void)addParticipantsWithIDs:(NSString *)participantIDs
{
    [self setParticipantIds:[self.participantIds arrayByAddingObjectsFromArray:participantIDs]];
}

- (void)removeParticipantsWithIDs:(NSString *)participantIDs
{
    NSMutableArray *participants = [self.participantIds mutableCopy];
    [participants removeObjectsInArray:participantIDs];
    [self setParticipantIds:participants];
}

- (void)addAdminsWithIDs:(NSString *)adminIDs
{
    [self setAdminIds:[self.adminIds arrayByAddingObjectsFromArray:adminIDs]];
}

- (void)removeAdminsWithIDs:(NSString *)adminIDs
{
    NSMutableArray *admins = [self.adminIds mutableCopy];
    [admins removeObjectsInArray:adminIDs];
    [self setAdminIds:admins];
}

@end
