//
//  SKYMessage+JSQMessageMediaData.swift
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

import JSQMessagesViewController

extension SKYMessage {
    func messageMediaData(withCache cache: SKYAssetCache?) -> JSQMessageMediaData? {
        guard self.attachment != nil else {
            return nil
        }

        let asset = self.attachment!
        if asset.mimeType.hasPrefix("image/") {
            let imageItem = SKYChatConversationImageItem(withMessage: self)
            imageItem.assetCache = cache
            return imageItem
        }
        
        if asset.mimeType.hasPrefix("audio/") {
            do {
                let audioItem = try SKYChatConversationAudioItem(cache: cache, asset: self.attachment)
                return audioItem
            } catch let error {
                print("caught: \(error)")
            }
        }

        return nil
    }
}

public class JSQMessageMediaDataFactory {
    let assetCache: SKYAssetCache?

    public init(with assetCache: SKYAssetCache?) {
        self.assetCache = assetCache
    }

    public convenience init() {
        self.init(with: SKYAssetMemoryCache.shared())
    }

    public func mediaData(with message: SKYMessage) -> JSQMessageMediaData? {
        return message.messageMediaData(withCache: self.assetCache)
    }
}
