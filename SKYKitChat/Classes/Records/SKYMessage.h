//
//  Message.h
//  Pods
//
//  Created by Andrew Chung on 6/2/16.
//
//

#import "SKYChatRecord.h"
#import <SKYKit/SKYKit.h>

@class SKYReference;

@interface SKYMessage : SKYChatRecord

@property (strong, nonatomic, nullable) SKYRecordID *conversationID;
@property (copy, nonatomic, nullable) NSString *body;
@property (copy, nonatomic, nullable) NSDictionary<NSString *, id> *metadata;
@property (strong, nonatomic) SKYAsset *attachment;

@property (assign, nonatomic) bool syncingToServer;
@property (assign, nonatomic) bool alreadySyncToServer;
@property (assign, nonatomic) bool fail;

+ (instancetype)message;

- (NSInteger)getMsgType;
- (NSString *_Null_unspecified)getAssetURLForImage;
- (NSString *_Null_unspecified)getAssetURLForVoice;
- (float)getVoiceDuration;
@end
