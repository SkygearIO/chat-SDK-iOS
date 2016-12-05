//
//  SKYChatTypingIndicator.m
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

#import "SKYChatTypingIndicator.h"
#import <SKYKit/SKYKit.h>

NSString *SKYChatTypingEventToString(SKYChatTypingEvent event)
{
    switch (event) {
        case SKYChatTypingEventBegin:
            return @"begin";
        case SKYChatTypingEventPause:
            return @"pause";
        case SKYChatTypingEventFinished:
            return @"finished";
    }
}

SKYChatTypingEvent SKYChatTypingEventFromString(NSString *eventString)
{
    if ([eventString isEqualToString:@"begin"]) {
        return SKYChatTypingEventBegin;
    } else if ([eventString isEqualToString:@"pause"]) {
        return SKYChatTypingEventPause;
    } else {
        return SKYChatTypingEventFinished;
    }
}

@implementation SKYChatTypingIndicator {
    NSDictionary *userTypingInfos;
}

+ (BOOL)isTypingIndicatorEventType:(NSString *)typingIndicator
{
    return [typingIndicator isEqualToString:@"typing"];
}

/**
{
    {
      "user/id": {
        "event": "begin",
        "at": "20161116T78:44:00Z"
      },
      "user/id2": {
        "event": "begin",
        "at": "20161116T78:44:00Z"
      }
    }
}
 */
- (instancetype)initWithDictionary:(NSDictionary<NSString *, id> *)dict
                    conversationID:(NSString *)conversationID
{
    if ((self = [super init])) {
        _conversationID = [conversationID copy];
        userTypingInfos = [dict copy];
    }
    return self;
}

- (NSArray *)userIDs
{
    return [userTypingInfos allKeys];
}

- (NSArray *)typingUserIDs
{
    NSMutableArray *typingUserIDs = [NSMutableArray array];
    [self.userIDs enumerateObjectsUsingBlock:^(NSString *_Nonnull userID, NSUInteger idx,
                                               BOOL *_Nonnull stop) {
        SKYChatTypingEvent event = [self lastEventWithUserID:userID];
        NSDate *date = [self lastEventDateWithUserID:userID];

        if (event == SKYChatTypingEventBegin && [date timeIntervalSinceNow] > -5.0) {
            // Last event is typing and the event is less than 5 seconds ago.
            [typingUserIDs addObject:userID];
        }
    }];
    return typingUserIDs;
}

- (NSDictionary *)userInfoWithUserID:(NSString *)userID
{
    return [userTypingInfos objectForKey:userID];
}

- (SKYChatTypingEvent)lastEventWithUserID:(NSString *)userID
{
    NSString *eventType = [[self userInfoWithUserID:userID] objectForKey:@"event"];
    return SKYChatTypingEventFromString(eventType);
}

- (NSDate *)lastEventDateWithUserID:(NSString *)userID
{
    NSString *eventDate = [[self userInfoWithUserID:userID] objectForKey:@"at"];
    if (![eventDate isKindOfClass:[NSString class]]) {
        return nil;
    }
    return [SKYDataSerialization dateFromString:eventDate];
}

- (SKYChatTypingIndicator *)typingIndicatorWithUpdatesFromTypingIndicator:
    (SKYChatTypingIndicator *)indicator
{
    NSString *conversationID =
        [indicator.conversationID isEqualToString:_conversationID] ? indicator : nil;
    NSMutableDictionary *infos = [userTypingInfos mutableCopy];
    [infos addEntriesFromDictionary:indicator->userTypingInfos];
    return [[SKYChatTypingIndicator alloc] initWithDictionary:infos conversationID:conversationID];
}

@end
