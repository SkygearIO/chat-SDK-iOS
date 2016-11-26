//
//  Conversation.h
//  Pods
//
//  Created by Andrew Chung on 6/1/16.
//
//

#import <SKYKit/SKYKit.h>

#import "SKYChatRecord.h"

@interface SKYConversation : SKYChatRecord

@property (copy, nonatomic, nonnull) NSArray<NSString *> *participantIds;
@property (copy, nonatomic, nonnull) NSArray<NSString *> *adminIds;
@property (copy, nonatomic, nullable) NSString *title;
@property (copy, nonatomic, nullable) NSDictionary<NSString *, id> *metadata;
@property (assign, nonatomic) BOOL distinctByParticipants;

- (NSString *_Nonnull)toString;

- (void)addParticipantsWithIDs:(NSString *_Nonnull)participantIDs;
- (void)removeParticipantsWithIDs:(NSString *_Nonnull)participantIDs;
- (void)addAdminsWithIDs:(NSString *_Nonnull)adminIDs;
- (void)removeAdminsWithIDs:(NSString *_Nonnull)adminIDs;

@end
