//
//  SKYConversation.h
//  SKYKit
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

@interface SKYConversation : SKYChatRecord

@property (copy, nonatomic, nonnull) NSArray<NSString *> *participantIds;
@property (copy, nonatomic, nonnull) NSArray<NSString *> *adminIds;
@property (copy, nonatomic, nullable) NSString *title;
@property (copy, nonatomic, nullable) NSDictionary<NSString *, id> *metadata;
@property (assign, nonatomic) BOOL distinctByParticipants;

- (NSString *_Nonnull)toString;

- (void)addParticipantsWithUserIDs:(NSString *_Nonnull)userIDs NS_SWIFT_NAME(addParticipants(_:));
- (void)removeParticipantsWithUserIDs:(NSString *_Nonnull)userIDs
    NS_SWIFT_NAME(removeParticipants(_:));
- (void)addAdminsWithUserIDs:(NSString *_Nonnull)userIDs NS_SWIFT_NAME(addAdmins(_:));
- (void)removeAdminsWithUserIDs:(NSString *_Nonnull)userIDs NS_SWIFT_NAME(removeAdmins(_:));

@end
