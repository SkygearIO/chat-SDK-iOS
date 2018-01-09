//
//  SKYMessageOperationCacheObject.h
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
#import <Realm/Realm.h>
#import <SKYKit/SKYKit.h>

#import "SKYMessageOperation.h"

NS_ASSUME_NONNULL_BEGIN

@interface SKYMessageOperationCacheObject : RLMObject

@property NSString *operationID;
@property NSString *recordID;
@property NSString *conversationID;
@property NSString *type;
@property NSString *status;
@property NSDate *sendDate;
@property NSData *recordData;
@property NSData *errorData;

@end

@interface SKYMessageOperationCacheObject (SKYMessageOperation)

+ (SKYMessageOperationStatus)messageOperationStatusWithKey:(NSString *)statusKey;
+ (NSString *)messageOperationStatusKeyWithStatus:(SKYMessageOperationStatus)status;
+ (SKYMessageOperationType)messageOperationTypeWithKey:(NSString *)typeKey;
+ (NSString *)messageOperationTypeKeyWithType:(SKYMessageOperationType)type;

- (SKYMessageOperation *)messageOperation;
+ (SKYMessageOperationCacheObject *)cacheObjectFromMessageOperation:
    (SKYMessageOperation *)messageOperation;

@end

NS_ASSUME_NONNULL_END

RLM_ARRAY_TYPE(SKYMessageOperationCache)
