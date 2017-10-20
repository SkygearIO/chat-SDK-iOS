//
//  SKYChatConversationAudioItem.swift
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

private let maxDisplaySize: CGFloat = 240
private let minDisplaySize: CGFloat = 80


class SKYChatConversationAudioItem: JSQAudioMediaItem {
    var view: UIView?
    var childView: UIView?
    
    var assetCache: SKYAssetCache?
    var data: Data?
    var asset: SKYAsset?
    
    init(cache: SKYAssetCache?, asset: SKYAsset?) throws {
        self.assetCache = cache
        self.asset = asset
        if let audioCache = cache {
            if let cacheData = audioCache.get(asset: asset!) {
                self.data = cacheData as? Data
            }
        }
        super.init(data: self.data, audioViewAttributes: JSQAudioMediaViewAttributes())
        let size = super.mediaViewDisplaySize()
        self.view = UIView(frame: CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height))
        if self.data == nil {
            DispatchQueue.global().async { [weak self] in
                guard let item = self else {
                    return
                }
                
                self?.data = try? Data(contentsOf: item.asset!.url)
                if let audioCache = cache {
                    audioCache.set(value: self?.data, for: asset!)
                }
                
                DispatchQueue.main.sync {  [weak self] in
                    guard let item = self else {
                        return
                    }
                    if item.data != nil {
                        item.childView?.removeFromSuperview()
                        item.audioData = item.data
                        item.childView = item.mediaView()
                    }
                }
                
            }
        }

    }
    
    override func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        super.audioPlayerDidFinishPlaying(player, successfully: flag)
    }
    
    override func mediaView() -> UIView? {
        let view = super.mediaView()
        if view != nil {
            self.childView = view
            self.view?.addSubview(view!)
        } else {
            self.view?.addSubview(self.mediaPlaceholderView())
        }
        return self.view
    }
    
    open func stop() {
        self.clearCachedMediaViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
