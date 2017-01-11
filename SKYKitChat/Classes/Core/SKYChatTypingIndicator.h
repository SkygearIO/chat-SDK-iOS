//
//  SKYChatTypingIndicator.h
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
 Typing Event.
 */
typedef NS_ENUM(NSInteger, SKYChatTypingEvent) {
    /**
     The user began typing.
     */
    SKYChatTypingEventBegin,

    /**
     The user stopped typing.
     */
    SKYChatTypingEventPause,

    /**
     The user stopped typing and the message is sent.
     */
    SKYChatTypingEventFinished,
};

/**
 Returns the string representation of the typing event.
 */
extern NSString *_Nonnull SKYChatTypingEventToString(SKYChatTypingEvent event);

/**
 Returns the typing event with string representation.
 */
extern SKYChatTypingEvent SKYChatTypingEventFromString(NSString *_Nonnull eventString);

/**
 SKYChatTypingIndicator contains information about the typing event of the user in a conversation.
 */
@interface SKYChatTypingIndicator : NSObject

/**
 Gets the ID of all users who currently have typing indicator event.
 */
@property (nonatomic, readonly, nonnull) NSArray<NSString *> *userIDs;

/**
 Gets the ID of all users who are typing.
 */
@property (nonatomic, readonly, nonnull) NSArray<NSString *> *typingUserIDs;

/**
 Returns the conversation ID for the typing event.
 */
@property (nonatomic, readonly, nullable) NSString *conversationID;

/**
 Returns a copy of this typing indicator with updates applied from another typing indicator.
 */
- (SKYChatTypingIndicator *_Nullable)typingIndicatorWithUpdatesFromTypingIndicator:
    (SKYChatTypingIndicator *_Nonnull)indicator NS_SWIFT_NAME(typingIndicatorWithUpdates(_:));

/**
 Returns the last event type of the user.
 */
- (SKYChatTypingEvent)lastEventWithUserID:(NSString *_Nonnull)userID
    NS_SWIFT_NAME(lastEvent(userID:));

/**
 Returns the last event date of the user.
 */
- (NSDate *_Nullable)lastEventDateWithUserID:(NSString *_Nonnull)userID
    NS_SWIFT_NAME(lastEventDate(userID:));

/**
 Instantiate an instance of SKYChatTypingIndicator.

 Most developer do not need to create an instance of SKYChatTypingIndicator. The SDK creates
 instances
 of this class to provide information of typing event.
 */
- (instancetype _Nullable)initWithDictionary:(NSDictionary<NSString *, id> *_Nullable)dict
                              conversationID:(NSString *_Nullable)conversationID;

@end
