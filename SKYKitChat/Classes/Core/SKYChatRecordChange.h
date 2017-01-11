//
//  SKYChatRecordChange.h
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

@class SKYRecord;

/**
 Record change event.
 */
typedef NS_ENUM(NSInteger, SKYChatRecordChangeEvent) {
    /**
     Record is created.
     */
    SKYChatRecordChangeEventCreate,

    /**
     Record is updated.
     */
    SKYChatRecordChangeEventUpdate,

    /**
     Record is deleted.
     */
    SKYChatRecordChangeEventDelete,
};

/**
 SKYChatRecordChange contains information of record change event for the chat extension.

 Record change event occurs when data of a chat object such as conversation or message
 is created, updated and deleted.

 You do not need to instantiate an instance of this class. This object is provided
 when you subscribe to record change notification.
 */
@interface SKYChatRecordChange : NSObject

/**
 Gets the record change event type.
 */
@property (nonatomic, readonly) SKYChatRecordChangeEvent event;

/**
 Gets the name of the record type of the changed record.
 */
@property (nonatomic, readonly, nonnull) NSString *recordType;

/**
 Gets the record.
 */
@property (nonatomic, readonly, nonnull) SKYRecord *record;

/**
 Instantiates an instance of SKYChatRecordChange.
 */
- (instancetype _Nullable)initWithDictionary:(NSDictionary<NSString *, id> *_Nonnull)dict
                                   eventType:(NSString *_Nullable)eventType;

@end
