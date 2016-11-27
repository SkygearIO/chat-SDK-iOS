//
//  Message.h
//  Pods
//
//  Created by Andrew Chung on 6/2/16.
//
//

#import <SKYKit/SKYKit.h>

#import "SKYChatRecord.h"

@class SKYReference;

typedef NS_ENUM(NSInteger, SKYChatConversationStatus) {
    SKYChatConversationStatusDelivering,
    SKYChatConversationStatusDelivered,
    SKYChatConversationStatusSomeRead,
    SKYChatConversationStatusAllRead
};

@interface SKYMessage : SKYChatRecord

@property (strong, nonatomic, nullable) SKYRecordID *conversationID;
@property (copy, nonatomic, nullable) NSString *body;
@property (copy, nonatomic, nullable) NSDictionary<NSString *, id> *metadata;
@property (strong, nonatomic) SKYAsset *attachment;

@property (assign, nonatomic) bool syncingToServer;
@property (assign, nonatomic) bool alreadySyncToServer;
@property (assign, nonatomic) bool fail;
@property (assign, nonatomic, readonly) SKYChatConversationStatus conversationStatus;

+ (instancetype)message;

- (NSInteger)getMsgType;
- (NSString *_Null_unspecified)getAssetURLForImage;
- (NSString *_Null_unspecified)getAssetURLForVoice;
- (float)getVoiceDuration;
@end
