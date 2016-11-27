//
//  SKYChatReceipt.h
//  Pods
//
//  Created by atwork on 26/11/2016.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, SKYChatReceiptStatus) {
    SKYChatReceiptStatusDelivering,
    SKYChatReceiptStatusDelivered,
    SKYChatReceiptStatusRead,
};

@interface SKYChatReceipt : NSObject

@property (nonatomic, readonly, nonnull) NSString *userID;
@property (nonatomic, readonly, nullable) NSDate *deliveredAt;
@property (nonatomic, readonly, nullable) NSDate *readAt;
@property (nonatomic, readonly) SKYChatReceiptStatus status;

- (instancetype)initWithReceiptDictionary:(NSDictionary<NSString *, id> *_Nonnull)dict;

@end
