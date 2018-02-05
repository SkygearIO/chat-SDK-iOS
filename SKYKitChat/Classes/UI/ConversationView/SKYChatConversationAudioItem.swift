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
    var asset: SKYAsset?

    convenience init(withMessage message: SKYMessage, maskAsOutgoing isOutGoing: Bool) {
        self.init(withMessage: message, assetCache: nil, maskAsOutgoing: isOutGoing)
    }

    init(withMessage message: SKYMessage,
         assetCache: SKYAssetCache?,
         maskAsOutgoing isOutGoing: Bool) {
        super.init(data: nil, audioViewAttributes: JSQAudioMediaViewAttributes())

        guard let asset = message.attachment else {
            // nothing to do if asset is nil
            return
        }

        self.appliesMediaViewMaskAsOutgoing = isOutGoing

        let size = self.mediaViewDisplaySize()
        self.view = UIView(frame: CGRect(x: 0.0,
                                         y: 0.0,
                                         width: size.width,
                                         height: size.height))

        self.assetCache = assetCache
        self.asset = asset

        if let data = self.assetCache?.get(asset: asset) {
            self.audioData = data
        } else {
            DispatchQueue.global().async { [weak self] in
                guard let myself = self else {
                    return
                }

                guard let data = try? Data(contentsOf: asset.url) else {
                    return
                }

                myself.audioData = data
                myself.assetCache?.set(data: data, for: asset)

                DispatchQueue.main.sync {  [weak self] in
                    guard let myself = self else {
                        return
                    }

                    if myself.audioData != nil {
                        myself.childView?.removeFromSuperview()
                        myself.childView = myself.mediaView()
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
