//
//  SKYChatReceipt.h
//  Pods
//
//  Created by atwork on 26/11/2016.
//
//

#import <Foundation/Foundation.h>

typedef enum {
    SKYChatReceiptDeliveringStatus,
    SKYChatReceiptDeliveredStatus,
    SKYChatReceiptReadStatus,
} SKYChatReceiptStatus;

@interface SKYChatReceipt : NSObject

@property (nonatomic, readonly, nonnull) NSString *userID;
@property (nonatomic, readonly, nullable) NSDate *deliveredAt;
@property (nonatomic, readonly, nullable) NSDate *readAt;
@property (nonatomic, readonly) SKYChatReceiptStatus status;

- (instancetype)initWithReceiptDictionary:(NSDictionary<NSString *, id> *_Nonnull)dict;

@end
