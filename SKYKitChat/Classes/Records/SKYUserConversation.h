//
//  SKYUserConversation.h
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

#import <SKYKit/SKYKit.h>

#import "SKYChatRecord.h"

@class SKYMessage, SKYConversation;

@interface SKYUserConversation : SKYChatRecord

@property (nonatomic, readonly, nonnull) SKYRecord *userRecord;
@property (nonatomic, readonly, nonnull) SKYConversation *conversation;
@property (nonatomic, readonly, nullable) SKYMessage *lastReadMessage;
@property (copy, nonatomic, nullable) NSString *lastReadMessageID;
@property (nonatomic, readonly) NSInteger unreadCount;

@end
