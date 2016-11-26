//
//  SKYUserConversation.h
//  Pods
//
//  Created by Andrew Chung on 7/26/16.
//
//

#import <SKYKit/SKYKit.h>

#import "SKYChatRecord.h"

@class SKYMessage, SKYConversation;

@interface SKYUserConversation : SKYChatRecord

@property (nonatomic, readonly, nullable) SKYRecord *userRecord;
@property (nonatomic, readonly, nullable) SKYConversation *conversation;
@property (nonatomic, readonly, nullable) SKYMessage *lastReadMessage;
@property (copy, nonatomic, nullable) NSString *lastReadMessageID;
@property (nonatomic, readonly) NSInteger unreadCount;

@end
