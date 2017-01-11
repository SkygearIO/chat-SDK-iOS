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

@implementation SKYChatRecord
+ (instancetype)recordWithRecord:(SKYRecord *)record
{
    return [[[self alloc] initWithRecordID:record.recordID data:record.dictionary]
        initWithRecordData:record];
}

- (id)initWithRecordData:(SKYRecord *)record
{
    self.ownerUserRecordID = record.ownerUserRecordID;
    self.creationDate = record.creationDate;
    self.creatorUserRecordID = record.creatorUserRecordID;
    self.modificationDate = record.modificationDate;
    self.lastModifiedUserRecordID = record.lastModifiedUserRecordID;
    self.accessControl = record.accessControl;
    self.recordID = record.recordID;
    return self;
}
@end
