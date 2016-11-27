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

- (SKYChatConversationStatus)conversationStatus
{
    NSString *stringStatus = self[SKYMessageConversationStatusKey];
    if ([stringStatus isEqualToString:@"all_read"]) {
        return SKYChatConversationStatusAllRead;
    } else if ([stringStatus isEqualToString:@"some_read"]) {
        return SKYChatConversationStatusSomeRead;
    } else if ([stringStatus isEqualToString:@"delivered"]) {
        return SKYChatConversationStatusDelivered;
    } else {
        return SKYChatConversationStatusDelivering;
    }
}

- (NSInteger)getMsgType
{
    if (!self.attachment) {
        return 2;
    }
    NSString *name = self.attachment.name;
    NSLog(@"getMsgType name:%@", name);
    if (!name || name.length < 1) {
        return 2;
    }
    if ([name containsString:@"message-image"]) {
        return 0;
    } else if ([name containsString:@"message-voice"]) {
        return 1;
    }
    return 2;
}

- (NSString *)getAssetURLForImage
{
    if (!self.attachment) {
        return @"";
    }
    if (![self.attachment.name containsString:@"message-image"]) {
        return @"";
    }
    NSString *metaDataString = self.attachment.url.absoluteString;
    return metaDataString;
}

- (NSString *)getAssetURLForVoice
{
    if (!self.attachment) {
        return @"";
    }
    if (![self.attachment.name containsString:@"message-voice"]) {
        return @"";
    }
    NSString *metaDataString = self.attachment.url.absoluteString;
    NSLog(@"getAssetURLForVoice :%@", metaDataString);
    return metaDataString;
    //    NSString *recordID = @"";
    //    NSString *metaDataString = [self.metadata valueForKey:@"message-voice"];
    //    NSArray *splitString = [metaDataString
    //    componentsSeparatedByString:@"-message-voice"];
    //    if (splitString.count > 0) {
    //        recordID = [splitString objectAtIndex:0];
    //    }
    //    return recordID;
}

- (float)getVoiceDuration
{
    if (!self.attachment) {
        return 0.0;
    }
    if (![self.attachment.name containsString:@"message-voice"]) {
        return 0.0;
    }
    NSArray *splitArray = [self.attachment.name componentsSeparatedByString:@"duration"];
    if (splitArray.count > 1) {
        NSString *time = [splitArray objectAtIndex:1];
        return time.floatValue;
    }
    return 0.0;
}

@end
