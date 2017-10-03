//
//  SKYMessage+UIImage.swift
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

fileprivate let MAX_IMAGE_SIZE: CGFloat = 1600
fileprivate let IMAGE_FORMAT: String = SKYMessageImageThumbnailFormatJPEG

fileprivate let THUMBNAIL_SIZE: CGFloat = 80
fileprivate let THUMBMAIL_FORMAT: String = SKYMessageImageThumbnailFormatJPEG

let SKYMessageImageMaxSizeAttributeName = "SKYMessageImageMaxSizeAttributeName"
let SKYMessageImageFormatAttributeName = "SKYMessageImageFormatAttributeName"

let SKYMessageImageThumbnailSizeAttributeName = "SKYMessageImageThumbnailSizeAttributeName"
let SKYMessageImageThumbnailFormatAttributeName = "SKYMessageImageThumbnailFormatAttributeName"

let SKYMessageImageThumbnailFormatPNG = "PNG"
let SKYMessageImageThumbnailFormatJPEG = "JPEG"

fileprivate let SKYMessageMetadataThumbnailAttributeName = "thumbnail"
fileprivate let SKYMessageMetadataWidthAttributeName = "width"
fileprivate let SKYMessageMetadataHeightAttributeName = "height"

extension SKYMessage {
    convenience init(withImage: UIImage) {
        self.init(withImage: withImage, options: nil)
    }

    convenience init(withImage: UIImage, options: [String: Any]?) {
        self.init()

        let parsedOptions = SKYMessage.parseOptions(options: options)

        self.body = ""
        self.attachment = SKYMessage.attachmentFor(image: withImage, options: parsedOptions)
        self.metadata = SKYMessage.metadataFor(image: withImage, options: parsedOptions)
    }

    fileprivate static func parseOptions(options: [String: Any]?) -> [String: Any] {
        var _options = options ?? [String: Any]()

        _options[SKYMessageImageMaxSizeAttributeName] = _options[SKYMessageImageMaxSizeAttributeName] ?? MAX_IMAGE_SIZE
        _options[SKYMessageImageFormatAttributeName] = _options[SKYMessageImageFormatAttributeName] ?? IMAGE_FORMAT
        _options[SKYMessageImageThumbnailSizeAttributeName] = _options[SKYMessageImageThumbnailSizeAttributeName] ?? THUMBNAIL_SIZE
        _options[SKYMessageImageThumbnailFormatAttributeName] = _options[SKYMessageImageThumbnailFormatAttributeName] ?? THUMBMAIL_FORMAT

        return _options
    }

    fileprivate static func attachmentFor(image: UIImage, options: [String: Any]) -> SKYAsset {
        let imageSize = scaleSize(from: image.size, toMax: options[SKYMessageImageMaxSizeAttributeName] as! CGFloat)
        let scaledImage = scale(image: image, toSize: imageSize)
        let format = options[SKYMessageImageFormatAttributeName] as! String
        let data = SKYMessage.convert(image: scaledImage!, format: format, quality: 0.7)
        return SKYAsset(name: UUID().uuidString, mimeType: SKYMessage.getMimeTypeFrom(format: format), data: data!)
    }

    fileprivate static func metadataFor(image: UIImage, options: [String: Any]) -> [String: Any] {
        var metadata = [String: Any]()

        let thumbnailSize = scaleSize(from: image.size, toMax: options[SKYMessageImageThumbnailSizeAttributeName] as! CGFloat)
        let thumbnailImage = scale(image: image, toSize: thumbnailSize)

        if let ti = thumbnailImage as UIImage? {
            let format = options[SKYMessageImageThumbnailFormatAttributeName] as! String
            metadata[SKYMessageMetadataThumbnailAttributeName] = SKYMessage.convert(image: ti, format: format, quality: 0.4)?.base64EncodedString()
        }

        let imageSize = scaleSize(from: image.size, toMax: options[SKYMessageImageMaxSizeAttributeName] as! CGFloat)
        metadata[SKYMessageMetadataWidthAttributeName] = imageSize.width
        metadata[SKYMessageMetadataHeightAttributeName] = imageSize.height

        return metadata
    }

    fileprivate static func convert(image: UIImage, format: String, quality: CGFloat) -> Data? {
        switch format {
        case SKYMessageImageThumbnailFormatPNG:
            return UIImagePNGRepresentation(image)
        case SKYMessageImageThumbnailFormatJPEG:
            return UIImageJPEGRepresentation(image, quality)
        default:
            fatalError("Unexpected image format")
        }
    }

    fileprivate static func getMimeTypeFrom(format: String) -> String {
        switch format {
        case SKYMessageImageThumbnailFormatPNG:
            return "image/png"
        case SKYMessageImageThumbnailFormatJPEG:
            return "image/jpeg"
        default:
            fatalError("Unexpected image format")
        }
    }
}

func scaleSize(from: CGSize, toMax: CGFloat) -> CGSize {
    if from.width <= toMax && from.height <= toMax {
        return from
    }

    let aspectWidth = from.width / from.height
    let aspectHeight = from.height / from.width

    var targetWidth: CGFloat = 0
    var targetHeight: CGFloat = 0

    if from.width > from.height {
        targetWidth = toMax
        targetHeight = targetWidth * aspectHeight
    } else {
        targetHeight = toMax
        targetWidth = targetHeight * aspectWidth
    }

    return CGSize.init(width: targetWidth, height: targetHeight)
}

func scaleSize(from: CGSize, toMin: CGFloat) -> CGSize {
    if from.width >= toMin && from.height >= toMin {
        return from
    }

    let aspectWidth = from.width / from.height
    let aspectHeight = from.height / from.width

    var targetWidth: CGFloat = 0
    var targetHeight: CGFloat = 0

    if from.width < from.height {
        targetWidth = toMin
        targetHeight = targetWidth * aspectHeight
    } else {
        targetHeight = toMin
        targetWidth = targetHeight * aspectWidth
    }

    return CGSize.init(width: targetWidth, height: targetHeight)
}

func scale(image: UIImage, toSize: CGSize) -> UIImage? {
    if __CGSizeEqualToSize(image.size, toSize) {
        return image
    }

    UIGraphicsBeginImageContextWithOptions(toSize, false, 1);
    image.draw(in: CGRect.init(x: 0, y: 0, width: toSize.width, height: toSize.height))
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return newImage
}
