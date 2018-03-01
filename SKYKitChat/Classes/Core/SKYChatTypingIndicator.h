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

NS_ASSUME_NONNULL_BEGIN

/**
 Typing Event.
 */
typedef NS_ENUM(NSInteger, SKYChatTypingEvent) {
    /**
     The participant began typing.
     */
    SKYChatTypingEventBegin,

    /**
     The participant stopped typing.
     */
    SKYChatTypingEventPause,

    /**
     The participant stopped typing and the message is sent.
     */
    SKYChatTypingEventFinished,
};

/**
 Returns the string representation of the typing event.
 */
extern NSString *SKYChatTypingEventToString(SKYChatTypingEvent event);

/**
 Returns the typing event with string representation.
 */
extern SKYChatTypingEvent SKYChatTypingEventFromString(NSString *eventString);

/**
 SKYChatTypingIndicator contains information about the typing event of
 the participant in a conversation.
 */
@interface SKYChatTypingIndicator : NSObject

/**
 Gets the ID of all participants who currently have typing indicator event.
 */
@property (nonatomic, readonly) NSArray<NSString *> *participantIDs;

/**
 Gets the ID of all participants who are typing.
 */
@property (nonatomic, readonly) NSArray<NSString *> *typingParticipantIDs;

/**
 Returns the conversation ID for the typing event.
 */
@property (nonatomic, readonly, nullable) NSString *conversationID;

/**
 Returns a copy of this typing indicator with updates applied from another typing indicator.
 */
- (SKYChatTypingIndicator *_Nullable)typingIndicatorWithUpdatesFromTypingIndicator:
    (SKYChatTypingIndicator *)indicator NS_SWIFT_NAME(typingIndicatorWithUpdates(_:));

/**
 Returns the last event type of the participant.
 */
- (SKYChatTypingEvent)lastEventWithParticipantID:(NSString *)participantID
    NS_SWIFT_NAME(lastEvent(participantID:));

/**
 Returns the last event date of the participant.
 */
- (NSDate *_Nullable)lastEventDateWithParticipantID:(NSString *)participantID
    NS_SWIFT_NAME(lastEventDate(participantID:));

/**
 Instantiate an instance of SKYChatTypingIndicator.

 Most developer do not need to create an instance of SKYChatTypingIndicator. The SDK creates
 instances
 of this class to provide information of typing event.
 */
- (instancetype _Nullable)initWithDictionary:(NSDictionary<NSString *, id> *_Nullable)dict
                              conversationID:(NSString *_Nullable)conversationID;

@end

NS_ASSUME_NONNULL_END
