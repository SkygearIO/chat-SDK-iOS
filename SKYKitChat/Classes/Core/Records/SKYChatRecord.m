//
//  SKYChatRecord.m
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
// Sorry...
#import <SKYKit/SKYRecord_Private.h>

@implementation SKYChatRecord
- (id)initWithRecordData:(SKYRecord *)record
{
    self = [super init];
    self.record = [[SKYRecord alloc] initWithRecordID:record.recordID data:record.dictionary];
    self.record.ownerUserRecordID = record.ownerUserRecordID;
    self.record.creationDate = record.creationDate;
    self.record.creatorUserRecordID = record.creatorUserRecordID;
    self.record.modificationDate = record.modificationDate;
    self.record.lastModifiedUserRecordID = record.lastModifiedUserRecordID;
    self.record.accessControl = record.accessControl;
    self.record.recordID = record.recordID;
    return self;
}

- (NSString *)creatorUserRecordID
{
    return self.record.creatorUserRecordID;
}

- (NSDate *)creationDate
{
    return self.record.creationDate;
}

- (NSDictionary *_Nonnull)dictionary
{
    return self.record.dictionary;
}

- (SKYRecordID *)recordID
{
    return self.record.recordID;
}

- (NSString *_Nonnull)recordType
{
    return self.record.recordType;
}

- (void)setCreatorUserRecordID:(NSString *_Nonnull)recordID
{
    self.record.creatorUserRecordID = recordID;
}

- (void)setCreationDate:(NSDate *_Nonnull)date
{
    self.record.creationDate = date;
}
@end
