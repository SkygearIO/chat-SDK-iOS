//
//  SKYMessageOperationCacheObject.m
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

#import "SKYMessageOperationCacheObject.h"
#import "SKYMessage.h"
#import "SKYMessageOperation.h"

NSString *const SKYMessageOperationStatusPendingKey = @"pending";
NSString *const SKYMessageOperationStatusFailedKey = @"failed";
NSString *const SKYMessageOperationTypeAddKey = @"add";
NSString *const SKYMessageOperationTypeEditKey = @"edit";
NSString *const SKYMessageOperationTypeDeleteKey = @"delete";

@implementation SKYMessageOperationCacheObject

+ (NSString *)primaryKey
{
    return @"operationID";
}

@end

@implementation SKYMessageOperationCacheObject (SKYMessageOperation)

+ (SKYMessageOperationStatus)messageOperationStatusWithKey:(NSString *)statusKey
{
    if ([statusKey isEqualToString:SKYMessageOperationStatusPendingKey]) {
        return SKYMessageOperationStatusPending;
    } else {
        return SKYMessageOperationStatusFailed;
    }
}

+ (NSString *)messageOperationStatusKeyWithStatus:(SKYMessageOperationStatus)status
{
    switch (status) {
        case SKYMessageOperationStatusPending:
            return SKYMessageOperationStatusPendingKey;
        default:
            return SKYMessageOperationStatusFailedKey;
    }
}

+ (SKYMessageOperationType)messageOperationTypeWithKey:(NSString *)typeKey
{
    if ([typeKey isEqualToString:SKYMessageOperationTypeDeleteKey]) {
        return SKYMessageOperationTypeDelete;
    } else if ([typeKey isEqualToString:SKYMessageOperationTypeEditKey]) {
        return SKYMessageOperationTypeEdit;
    } else {
        return SKYMessageOperationTypeAdd;
    }
}

+ (NSString *)messageOperationTypeKeyWithType:(SKYMessageOperationType)type
{
    switch (type) {
        case SKYMessageOperationTypeEdit:
            return SKYMessageOperationTypeEditKey;
        case SKYMessageOperationTypeDelete:
            return SKYMessageOperationTypeDeleteKey;
        default:
            return SKYMessageOperationTypeAddKey;
    }
}

- (SKYMessageOperation *)messageOperation
{
    SKYRecord *record = [NSKeyedUnarchiver unarchiveObjectWithData:self.recordData];
    SKYMessage *message = [SKYMessage recordWithRecord:record];
    NSError *error = [NSKeyedUnarchiver unarchiveObjectWithData:self.errorData];
    return [[SKYMessageOperation alloc]
        initWithOperationID:self.operationID
                    message:message
             conversationID:self.conversationID
                       type:[[self class] messageOperationTypeWithKey:self.type]
                     status:[[self class] messageOperationStatusWithKey:self.status]
                   sendDate:self.sendDate
                      error:error];
}

+ (SKYMessageOperationCacheObject *)cacheObjectFromMessageOperation:
    (SKYMessageOperation *)messageOperation
{
    SKYMessageOperationCacheObject *cacheObject = [[SKYMessageOperationCacheObject alloc] init];

    cacheObject.operationID = messageOperation.operationID;
    cacheObject.recordID = messageOperation.message.recordID.recordName;
    cacheObject.conversationID = messageOperation.conversationID;
    cacheObject.type = [self messageOperationTypeKeyWithType:messageOperation.type];
    cacheObject.status = [self messageOperationStatusKeyWithStatus:messageOperation.status];
    cacheObject.recordData =
        [NSKeyedArchiver archivedDataWithRootObject:messageOperation.message.record];
    cacheObject.errorData = [NSKeyedArchiver archivedDataWithRootObject:messageOperation.error];
    cacheObject.sendDate = messageOperation.sendDate;
    return cacheObject;
}

@end
