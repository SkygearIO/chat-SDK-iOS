//
//  SKYChatExtension_Private.h
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

#import "SKYChatExtension.h"

@interface SKYChatExtension ()

/**
 Gets an instance of SKYContainer used by this SKYChatExtension.
 */
@property (assign, nonatomic, readonly, nonnull)
    SKYContainer *container; // SKYContainer will keep a strong reference of this object.

/**
 Creates an instance of SKYChatExtension.

 For most user of the chat extension, get an instance of SKYChatExtension by using the category
 method called `-[SKYContainer chatExtension]`.

 @param container the SKYContainer that contains user credentials and server configuration
 @return an instance of SKYChatExtension
 */
- (nullable instancetype)initWithContainer:(nonnull SKYContainer *)container;

@end
