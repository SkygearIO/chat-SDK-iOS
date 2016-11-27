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

- (void)addParticipantsWithUserIDs:(NSString *_Nonnull)userIDs NS_SWIFT_NAME(addParticipants(_:));
- (void)removeParticipantsWithUserIDs:(NSString *_Nonnull)userIDs
    NS_SWIFT_NAME(removeParticipants(_:));
- (void)addAdminsWithUserIDs:(NSString *_Nonnull)userIDs NS_SWIFT_NAME(addAdmins(_:));
- (void)removeAdminsWithUserIDs:(NSString *_Nonnull)userIDs NS_SWIFT_NAME(removeAdmins(_:));

@end
