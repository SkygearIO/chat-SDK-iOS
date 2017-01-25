//
//  SKYConversation.h
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
#import "SKYMessage.h"

/**
 SKYConversation contains information of a conversation that is shared among all participants.

 Changing the value of the property in this object does not automatically save the changes
 to the server. To change the corresponding record on the server, use methods defined in
 SKYChatExtension.

 User-specific information such as unread count are available in SKYUserConversation.
 */
@interface SKYConversation : SKYChatRecord

/**
 Gets or sets the user ID of the participants of this conversation.
 */
@property (copy, nonatomic, nonnull) NSArray<NSString *> *participantIds;

/**
 Gets or sets the user ID of the admins of this conversation.
 */
@property (copy, nonatomic, nonnull) NSArray<NSString *> *adminIds;

/**
 Gets or sets the title of this conversation.
 */
@property (copy, nonatomic, nullable) NSString *title;

/**
 Gets or sets application-dependent metadata for this conversation.
 */
@property (copy, nonatomic, nullable) NSDictionary<NSString *, id> *metadata;

/**
 Gets or sets whether this conversation is distinct. A distinct conversation will
 be returned whenever a conversation is needed with the same participant list.
 */
@property (assign, nonatomic, getter=isDistinctByParticipants) BOOL distinctByParticipants;

/**
 The ID of the last message in this conversation.
 */
@property (readonly, nonatomic, nullable) NSString *lastMessageID;
@property (readonly, nonatomic, nullable) SKYMessage *lastMessage;

- (NSString *_Nonnull)toString;

/**
 Add participants to the conversation.
 */
- (void)addParticipantsWithUserIDs:(NSString *_Nonnull)userIDs NS_SWIFT_NAME(addParticipants(_:));

/**
 Remove participants from the conversation.
 */
- (void)removeParticipantsWithUserIDs:(NSString *_Nonnull)userIDs
    NS_SWIFT_NAME(removeParticipants(_:));

/**
 Add admins to the conversation.
 */
- (void)addAdminsWithUserIDs:(NSString *_Nonnull)userIDs NS_SWIFT_NAME(addAdmins(_:));

/**
 Remove admins from the conversation.
 */
- (void)removeAdminsWithUserIDs:(NSString *_Nonnull)userIDs NS_SWIFT_NAME(removeAdmins(_:));

@end
