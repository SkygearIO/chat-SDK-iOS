//
//  Message.m
//  Pods
//
//  Created by Andrew Chung on 6/2/16.
//
//

#import "SKYMessage.h"

NSString *const SKYMessageConversationKey = @"conversation_id";
NSString *const SKYMessageBodyKey = @"body";
NSString *const SKYMessageMetadataKey = @"metadata";
NSString *const SKYMessageAttachmentKey = @"attachment";
NSString *const SKYMessageConversationStatusKey = @"conversation_status";

@implementation SKYMessage

+ (instancetype)message
{
    return [[self alloc] initWithRecordType:@"message"];
}

- (void)setConversationID:(NSString *)conversationID
{
    if (conversationID) {
        SKYRecordID *recordID =
            [SKYRecordID recordIDWithRecordType:@"conversation" name:conversationID];
        self[SKYMessageConversationKey] = [SKYReference referenceWithRecordID:recordID];
    } else {
        self[SKYMessageConversationKey] = nil;
    }
}

- (NSString *)conversationID
{
    SKYReference *conversation = self[SKYMessageConversationKey];
    return conversation.recordID.recordName;
}

- (void)setBody:(NSString *)body
{
    self[SKYMessageBodyKey] = [body copy];
}

- (NSString *)body
{
    return self[SKYMessageBodyKey];
}

- (void)setMetadata:(NSDictionary *)metadata
{
    self[SKYMessageMetadataKey] = [metadata copy];
}

- (NSDictionary *)metadata
{
    return self[SKYMessageMetadataKey];
}

- (SKYAsset *)attachment
{
    return self[SKYMessageAttachmentKey];
}

- (void)setAttachment:(SKYAsset *)attachment
{
    self[SKYMessageAttachmentKey] = attachment;
}

- (SKYMessageConversationStatus)conversationStatus
{
    NSString *stringStatus = self[SKYMessageConversationStatusKey];
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
