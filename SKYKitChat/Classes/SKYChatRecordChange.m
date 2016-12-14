//
//  SKYChatRecordChange.m
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

#import "SKYChatRecordChange.h"

#import <SKYKit/SKYKit.h>

@implementation SKYChatRecordChange

+ (BOOL)isRecordChangeEventType:(NSString *)eventType
{
    return [@[ @"update", @"create", @"delete" ] containsObject:eventType];
}

- (instancetype)initWithDictionary:(NSDictionary<NSString *, id> *)dict
                         eventType:(NSString *)eventType
{
    if ((self = [super init])) {
        if ([eventType isEqualToString:@"create"]) {
            _event = SKYChatRecordChangeEventCreate;
        } else if ([eventType isEqualToString:@"update"]) {
            _event = SKYChatRecordChangeEventUpdate;
        } else if ([eventType isEqualToString:@"delete"]) {
            _event = SKYChatRecordChangeEventDelete;
        } else {
            return nil;
        }

        _recordType = dict[@"record_type"];
        if (_recordType == nil) {
            return nil;
        }

        _record = [[SKYRecordDeserializer deserializer] recordWithDictionary:dict[@"record"]];
        if (_record == nil) {
            return nil;
        }
    }
    return self;
}

@end
