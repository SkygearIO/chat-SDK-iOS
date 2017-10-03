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

fileprivate let MAX_DISPLAY_SIZE: CGFloat = 240
fileprivate let MIN_DISPLAY_SIZE: CGFloat = 80

class SKYChatConversationImageItem: NSObject, JSQMessageMediaData {

    var imageName: String? = nil
    var image: UIImage? = nil
    var displaySize: CGSize = CGSize.zero
    var thumbnailImage: UIImage? = nil

    var getImageData: (() -> Data?)? = nil

    func mediaView() -> UIView? {
        if self.image != nil {
            return UIImageView(image: self.image)
        }

        let imageView = UIImageView(image: self.thumbnailImage)
        DispatchQueue.global().async {
            let data = self.getImageData!()
            DispatchQueue.main.sync {
                if data != nil {
                    imageView.image = UIImage(data: data!)
                }
            }
        }

        let rect = CGRect.init(origin: CGPoint.zero, size: self.displaySize)
        imageView.frame = rect
        return JSQMessagesMediaPlaceholderView(frame: rect, backgroundColor: UIColor.lightGray, imageView: imageView)
    }

    func mediaViewDisplaySize() -> CGSize {
        return self.displaySize
    }

    func mediaPlaceholderView() -> UIView {
        return UIView()
    }

    func mediaHash() -> UInt {
        return UInt(abs((self.imageName ?? "").hash))
    }

}

// MARK: SKYMessage

extension SKYChatConversationImageItem {

    convenience init(withMessage: SKYMessage) {
        self.init()
        let asset = withMessage.attachment
        let metadata = withMessage.metadata ?? [String: Any]()

        var thumbnailImage: UIImage? = nil
        if let thumbnailImageString = metadata["thumbnail"] as! String! {
            let thumbnailImageData = Data(base64Encoded: thumbnailImageString)
            thumbnailImage = UIImage(data: thumbnailImageData!)
        }
        self.thumbnailImage = thumbnailImage

        self.imageName = asset!.name
        if let width = metadata["width"] as! CGFloat?, let height = metadata["height"] as! CGFloat? {
            let imageSize = CGSize.init(width: width, height: height)
            self.displaySize = SKYChatConversationImageItem.calculateDisplaySize(from: imageSize)
        } else {
            self.displaySize = SKYChatConversationImageItem.getDefaultDisplaySize()
        }

        self.getImageData = {
            let assetUrl = (asset?.url)!
            return try? Data(contentsOf: assetUrl)
        }
    }

    fileprivate static func calculateDisplaySize(from imageSize: CGSize) -> CGSize {
        let width = imageSize.width
        let height = imageSize.height
        if width > MAX_DISPLAY_SIZE || height > MAX_DISPLAY_SIZE {
            return scaleSize(from: imageSize, toMax: MAX_DISPLAY_SIZE)
        } else if width < MIN_DISPLAY_SIZE || height < MIN_DISPLAY_SIZE {
            return scaleSize(from: imageSize, toMin: MIN_DISPLAY_SIZE)
        }

        return imageSize
    }

    fileprivate static func getDefaultDisplaySize() -> CGSize {
        return CGSize.init(width: 100, height: 100)
    }

}
