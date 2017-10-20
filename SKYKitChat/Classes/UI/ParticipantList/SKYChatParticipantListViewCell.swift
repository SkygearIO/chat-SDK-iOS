//
//  SKYChatParticipantListViewCell.swift
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

open class SKYChatParticipantListViewCell: UITableViewCell {
    let unnamedParticipant: String = "Unnamed Participant"

    public var participantRecord: SKYRecord?
    public var participantInformation: String?
    public var avatarImage: UIImage?

    @IBOutlet public weak var avatarImageView: UIImageView!
    @IBOutlet public weak var participantNameLabel: UILabel!
    @IBOutlet public weak var participantInfoLabel: UILabel!

    public class var nib: UINib {
        return UINib(nibName: "SKYChatParticipantListViewCell",
                     bundle: Bundle(for: SKYChatParticipantListViewCell.self))
    }

    open override func awakeFromNib() {
        if let img = self.avatarImageView {
            img.layer.cornerRadius = CGFloat(0.5 * img.frame.height)
        }
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        if let img = self.avatarImage {
            self.avatarImageView?.image = img
        } else {
            self.avatarImageView?.removeFromSuperview()
        }

        if let record = self.participantRecord {
            self.layoutSubviews(participant: record)
        } else {
            self.participantNameLabel?.text = unnamedParticipant
            self.participantNameLabel?.textColor = UIColor.lightGray
        }
    }

    /**
     * Layout subviews according to the participant record. Subclasses can override this method
     * to implement a custom layout.
     **/
    open func layoutSubviews(participant: SKYRecord) {
        // name
        if let name = participant.object(forKey: "username") as? String {
            self.participantNameLabel?.text = name
            self.participantNameLabel?.textColor = self.participantNameLabel?.tintColor
        } else {
            self.participantNameLabel?.text = unnamedParticipant
            self.participantNameLabel?.textColor = UIColor.lightGray
        }

        // extra info
        if let info = self.participantInformation {
            self.participantInfoLabel?.text = info
        } else {
            self.participantInfoLabel?.text = nil
        }
    }
}
