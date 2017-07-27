//
//  SKYMessage.m
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

#import "SKYMessage.h"
#import "SKYConversation.h"

NSString *const SKYMessageConversationKey = @"conversation";
NSString *const SKYMessageBodyKey = @"body";
NSString *const SKYMessageMetadataKey = @"metadata";
NSString *const SKYMessageAttachmentKey = @"attachment";
NSString *const SKYMessageStatusKey = @"message_status";

@implementation SKYMessage

+ (instancetype)recordWithRecord:(SKYRecord *)record
{
    SKYMessage *new_record = [[SKYMessage alloc] initWithRecordData:record];
    return new_record;
}

+ (instancetype)message
{
    return [[self alloc] initWithRecordType:@"message"];
}

- (id)init
{
    self = [super init];
    self.record = [[SKYRecord alloc] initWithRecordType:@"message"];
    return self;
}

- (void)setConversationRef:(SKYReference *)ref
{
    self.record[SKYMessageConversationKey] = ref;
}

- (SKYReference *)conversationRef
{
    return self.record[SKYMessageConversationKey];
}

- (void)setBody:(NSString *)body
{
    self.record[SKYMessageBodyKey] = [body copy];
}

- (NSString *)body
{
    return self.record[SKYMessageBodyKey];
}

- (void)setMetadata:(NSDictionary *)metadata
{
    self.record[SKYMessageMetadataKey] = [metadata copy];
}

- (NSDictionary *)metadata
{
    return self.record[SKYMessageMetadataKey];
}

- (SKYAsset *)attachment
{
    return self.record[SKYMessageAttachmentKey];
}

- (void)setAttachment:(SKYAsset *)attachment
{
    self.record[SKYMessageAttachmentKey] = attachment;
}

- (SKYMessageConversationStatus)conversationStatus
{
    NSString *stringStatus = self.record[SKYMessageStatusKey];
    if ([stringStatus isEqualToString:@"all_read"]) {
        return SKYMessageConversationStatusAllRead;
    } else if ([stringStatus isEqualToString:@"some_read"]) {
        return SKYMessageConversationStatusSomeRead;
    } else if ([stringStatus isEqualToString:@"delivered"]) {
        return SKYMessageConversationStatusDelivered;
    } else {
        return SKYMessageConversationStatusDelivering;
    }
}

@end
