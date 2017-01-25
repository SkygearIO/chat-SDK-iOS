//
//  UIImage+Avatar.swift
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

import UIKit

public extension UIImage {
    class func avatarImage(forInitialsOfName name: String) -> UIImage? {
        let defaultGradientColors = [
            UIColor(red: 0, green: 0.474509804, blue: 0.823529412, alpha: 1.0),
            UIColor(red: 0.011764706, green: 0.721568627, blue: 0.760784314, alpha: 1.0)
        ]
        return UIImage.avatarImage(forInitialsOfName: name, gradientColors: defaultGradientColors)
    }

    class func avatarImage(forInitialsOfName name: String, gradientColors colors: [UIColor]) -> UIImage? {
        return UIImage.avatarImage(forInitialsOfName: name, gradientColors: colors, size: CGSize(width: 100, height: 100))
    }

    class func avatarImage(forInitialsOfName name: String,
                           gradientColors colors: [UIColor],
                           size: CGSize) -> UIImage? {
        return UIImage.avatarImage(forInitialsOfName: name,
                                   gradientColors: colors,
                                   textColor: UIColor.white,
                                   size: size)
    }

    class func avatarImage(forInitialsOfName name: String,
                           gradientColors colors: [UIColor],
                           textColor: UIColor,
                           size: CGSize) -> UIImage? {
        let nameInitials = name.initials
        var joinedInitials = ""

        // maximum render 2 initials
        for idx in 0..<min(2, nameInitials.count) {
            joinedInitials.append(nameInitials[idx])
        }

        // convert to NSString in order to get the correct NSRange
        let str = joinedInitials as NSString
        let fullRange = NSRange(location: 0, length: str.length)

        let aString = NSMutableAttributedString(string: joinedInitials)
        aString.setAttributes([
            NSForegroundColorAttributeName: textColor,
            NSFontAttributeName: UIFont.boldSystemFont(ofSize: 34)
            ], range: fullRange)
        return UIImage.avatarImage(forAttributedString: aString, gradientColors: colors, size: size)
    }

    class func avatarImage(forAttributedString aString: NSAttributedString,
                           gradientColors colors: [UIColor],
                           size: CGSize) -> UIImage? {
        let layer = CAGradientLayer()
        layer.startPoint = CGPoint.zero
        layer.endPoint = CGPoint(x: 1.0, y: 1.0)
        layer.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: size)
        layer.colors = colors.map { $0.cgColor }

        var image: UIImage?

        UIGraphicsBeginImageContext(size)
        let ctx = UIGraphicsGetCurrentContext()
        if let c = ctx {
            layer.render(in: c)

            let fontRenderSize = aString.boundingRect(with: size,
                                                      options: [.usesLineFragmentOrigin, .usesFontLeading],
                                                      context: nil).size

            aString.draw(at: CGPoint(x: (size.width - fontRenderSize.width) / 2,
                                     y: (size.height - fontRenderSize.height) / 2))

            image = UIGraphicsGetImageFromCurrentImageContext()
        }

        UIGraphicsEndImageContext()

        return image
    }

    class func circleImage(fromImage image: UIImage) -> UIImage? {
        let size = image.size
        var result: UIImage?

        UIGraphicsBeginImageContext(size)

        if let ctx = UIGraphicsGetCurrentContext() {
            let radius = min(size.width, size.height) / 2
            let center = CGPoint(x: size.width / 2, y: size.height / 2)

            ctx.beginPath()
            ctx.addArc(center: center,
                       radius: radius,
                       startAngle: 0,
                       endAngle: 2 * CGFloat.pi,
                       clockwise: false)
            ctx.closePath()
            ctx.clip()

            image.draw(in: CGRect(origin: CGPoint.zero, size: size))

            result = UIGraphicsGetImageFromCurrentImageContext()
        }

        UIGraphicsEndImageContext()

        return result
    }
}
