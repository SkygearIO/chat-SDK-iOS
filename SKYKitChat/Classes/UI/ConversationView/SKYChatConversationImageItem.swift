//
//  SKYChatConversationImageItem.swift
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

protocol SKYChatConversationImageItemDelegate: class {
    func imageDidTap(_ url: URL?)
}

class SKYChatConversationImageItem: JSQMediaItem {

    var imageName: String?
    var image: UIImage?
    var displaySize: CGSize = CGSize.zero
    var thumbnailImage: UIImage?
    var tap: UITapGestureRecognizer?
    weak var delegate: SKYChatConversationImageItemDelegate?
    var assetUrl: URL?

    var getImage: (() -> UIImage?)?

    var assetCache: SKYAssetCache?

    override func mediaView() -> UIView? {
        if self.image != nil {
            return UIImageView(image: self.image)
        }

        let imageView = UIImageView(image: self.thumbnailImage)
        DispatchQueue.global().async {
            let image = self.getImage!()
            DispatchQueue.main.sync {
                if image != nil {
                    imageView.image = image
                }
            }
        }

        let rect = CGRect.init(origin: CGPoint.zero, size: self.displaySize)
        imageView.frame = rect

        let placeHolderView = JSQMessagesMediaPlaceholderView(frame: rect, backgroundColor: UIColor.lightGray, imageView: imageView)
        placeHolderView!.isUserInteractionEnabled = true
        placeHolderView!.addGestureRecognizer(self.tap!)
        return placeHolderView
    }

    override func mediaViewDisplaySize() -> CGSize {
        return self.displaySize
    }

    override func mediaPlaceholderView() -> UIView {
        return UIView()
    }

    override func mediaHash() -> UInt {
        return UInt(abs((self.imageName ?? "").hash))
    }

}

// MARK: SKYMessage

extension SKYChatConversationImageItem {

    convenience init(withMessage message: SKYMessage, maskAsOutgoing isOutGoing: Bool) {
        self.init(withMessage: message, assetCache: nil, maskAsOutgoing: isOutGoing)
    }

    convenience init(withMessage message: SKYMessage,
                     assetCache: SKYAssetCache?,
                     maskAsOutgoing isOutGoing: Bool) {

        self.init(maskAsOutgoing: isOutGoing)
        self.assetCache = assetCache

        self.tap = UITapGestureRecognizer(target: self, action: #selector(imageDidTap))
        self.tap?.numberOfTapsRequired = 1

        let asset = message.attachment
        self.assetUrl = asset?.url
        let metadata = message.metadata ?? [String: Any]()

        var thumbnailImage: UIImage? = nil
        if let thumbnailImageString = metadata["thumbnail"] as? String {
            let thumbnailImageData =
                Data(base64Encoded: thumbnailImageString, options: .ignoreUnknownCharacters)
            thumbnailImage = UIImage(data: thumbnailImageData!)
        }
        self.thumbnailImage = thumbnailImage

        self.imageName = asset!.name
        if let width = metadata["width"] as? CGFloat, let height = metadata["height"] as? CGFloat {
            let imageSize = CGSize.init(width: width, height: height)
            self.displaySize = SKYChatConversationImageItem.calculateDisplaySize(from: imageSize)
        } else {
            self.displaySize = SKYChatConversationImageItem.getDefaultDisplaySize()
        }

        self.getImage = {
            return self.getImage(fromAsset: asset)
        }
    }

    @objc func imageDidTap() {
        if let delegate = self.delegate {
            delegate.imageDidTap(self.assetUrl)
        }
    }

    func getImage(fromAsset asset: SKYAsset?) -> UIImage? {
        if asset == nil {
            return nil
        }

        if let cache = self.assetCache {
            if let cachedImageData = cache.get(asset: asset!) {
                return UIImage(data: cachedImageData)
            }
        }

        let assetUrl = (asset?.url)!
        guard let data = try? Data(contentsOf: assetUrl) else {
            return nil
        }

        self.assetCache?.set(data: data, for: asset!)
        return UIImage(data: data)
    }

    fileprivate static func calculateDisplaySize(from imageSize: CGSize) -> CGSize {
        let width = imageSize.width
        let height = imageSize.height
        if width > maxDisplaySize || height > maxDisplaySize {
            return scaleSize(from: imageSize, toMax: maxDisplaySize)
        } else if width < minDisplaySize || height < minDisplaySize {
            return scaleSize(from: imageSize, toMin: minDisplaySize)
        }

        return imageSize
    }

    fileprivate static func getDefaultDisplaySize() -> CGSize {
        return CGSize.init(width: 100, height: 100)
    }

}
