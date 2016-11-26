//
//  SKYChatReceipt.m
//  Pods
//
//  Created by atwork on 26/11/2016.
//
//

#import "SKYChatReceipt.h"
#import <SKYKit/SKYKit.h>

@implementation SKYChatReceipt

- (instancetype)initWithReceiptDictionary:(NSDictionary<NSString *, id> *_Nonnull)dict
{
    if ((self = [super init])) {
        _userID = dict[@"user_id"];

        NSString *deliveredAt = dict[@"delivered_at"];
        if (deliveredAt) {
            _deliveredAt = [SKYDataSerialization dateFromString:deliveredAt];
        }
        NSString *readAt = dict[@"read_at"];
        if (readAt) {
            readAt = [SKYDataSerialization dateFromString:readAt];
        }
    }
    return self;
}

- (SKYChatReceiptStatus)status
{
    if (self.readAt) {
        return SKYChatReceiptReadStatus;
    } else if (self.deliveredAt) {
        return SKYChatReceiptDeliveredStatus;
    } else {
        return SKYChatReceiptDeliveringStatus;
    }
}

@end
