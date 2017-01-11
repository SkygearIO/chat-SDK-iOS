//
//  SKYChatReceipt.h
//  SKYKitChat
//
//  Copyright 2016 Oursky Ltd.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <Foundation/Foundation.h>

/**
 Message receipt status.
 */
typedef NS_ENUM(NSInteger, SKYChatReceiptStatus) {
    /**
     The messge is being delivered, it is not yet received by the other party.
     */
    SKYChatReceiptStatusDelivering,

    /**
     The messsage is delivered, but it is not read yet.
     */
    SKYChatReceiptStatusDelivered,

    /**
     The message is delivered and read.
     */
    SKYChatReceiptStatusRead,
};

/**
 SKYChatReceipt contains information about the receipt status of a message for each user. Receipt
 contains date and time for delivery and read status.
 */
@interface SKYChatReceipt : NSObject

/**
 The User ID of the user to whom the message is delivered or read.
 */
@property (nonatomic, readonly, nonnull) NSString *userID;

/**
 Gets date and time the message is delivered to the user.
 */
@property (nonatomic, readonly, nullable) NSDate *deliveredAt;

/**
 Gets date and time the message is read by the user.
 */
@property (nonatomic, readonly, nullable) NSDate *readAt;

/**
 Gets the receipt status.

 The receipt status is calculated from the date of delivery and read of the message.
 */
@property (nonatomic, readonly) SKYChatReceiptStatus status;

/**
 Instantiates an instance of SKYChatReceipt.

 Most developer do not need to create an instance of SKYChatReceipt. The SDK creates instances
 of this class to provide information of message receipt.
 */
- (instancetype _Nullable)initWithReceiptDictionary:(NSDictionary<NSString *, id> *_Nonnull)dict;

@end
