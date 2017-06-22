//
//  SKYUserChannel.h
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

#import "SKYChatRecord.h"
#import <SKYKit/SKYKit.h>

/**
 SKYUserChannel is a record containing information of the pubsub channel where
 server-side notifications are sent.
 */
@interface SKYUserChannel : SKYChatRecord

/**
 Gets or sets the name of the user channel.
 */
@property (copy, nonatomic, nullable) NSString *name;

/**
 Creates an instance of user channel.
 */
+ (instancetype _Nullable)userChannel;

- (id _Nonnull)init;
@end
