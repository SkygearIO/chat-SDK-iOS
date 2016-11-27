//
//  Message.h
//  Pods
//
//  Created by Andrew Chung on 6/2/16.
//
//

#import <SKYKit/SKYKit.h>

#import "SKYChatRecord.h"

extern NSString *const SKYMessageTypeMetadataKey;

@class SKYReference;

typedef NS_ENUM(NSInteger, SKYMessageConversationStatus) {
    SKYMessageConversationStatusDelivering,
    SKYMessageConversationStatusDelivered,
    SKYMessageConversationStatusSomeRead,
    SKYMessageConversationStatusAllRead
};

@interface SKYMessage : SKYChatRecord

@property (strong, nonatomic, nullable) SKYRecordID *conversationID;
@property (copy, nonatomic, nullable) NSString *body;
@property (copy, nonatomic, nullable) NSDictionary<NSString *, id> *metadata;
@property (strong, nonatomic, readwrite, nullable) SKYAsset *attachment;

@property (assign, nonatomic) bool syncingToServer;
@property (assign, nonatomic) bool alreadySyncToServer;
@property (assign, nonatomic) bool fail;
@property (assign, nonatomic, readonly) SKYMessageConversationStatus conversationStatus;

+ (instancetype)message;

@end
