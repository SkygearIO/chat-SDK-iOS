//
//  SKYParticipantCacheObject.m
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

#import "SKYParticipantCacheObject.h"

@implementation SKYParticipantCacheObject

+ (NSString *)primaryKey
{
    return @"recordID";
}

+ (SKYParticipantCacheObject *)cacheObjectFromParticipant:(SKYParticipant *)participantRecord
{
    SKYParticipantCacheObject *cacheObject = [[SKYParticipantCacheObject alloc] init];
    [cacheObject setRecordID:participantRecord.recordName];
    [cacheObject
        setRecordData:[NSKeyedArchiver archivedDataWithRootObject:participantRecord.record]];

    return cacheObject;
}

- (SKYParticipant *)participantRecord
{
    SKYRecord *record = [NSKeyedUnarchiver unarchiveObjectWithData:self.recordData];
    SKYParticipant *participant = [SKYParticipant recordWithRecord:record];

    return participant;
}

@end
