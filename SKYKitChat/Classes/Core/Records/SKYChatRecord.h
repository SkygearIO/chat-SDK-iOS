//
//  SKYChatRecord.h
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

NS_ASSUME_NONNULL_BEGIN

@interface SKYChatRecord : NSObject

- (id)initWithRecordData:(SKYRecord *)record;

@property (copy, nonatomic) SKYRecord *record;
@property (strong, nonatomic) NSString *creatorUserRecordID;
@property (strong, nonatomic) NSDate *creationDate;
@property (strong, nonatomic, readonly) SKYRecordID *recordID;
@property (strong, nonatomic, readonly) NSString *recordType;
@property (strong, nonatomic, readonly) NSString *recordName;
@property (strong, nonatomic, readonly) NSDictionary *dictionary;

@end

NS_ASSUME_NONNULL_END
