//
//  SKYConversation+Display.swift
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

public extension SKYConversation {
    /**
     Generate a name list from a list of participant. The title will be concatenating all
     participant names.
     */
    public func nameList(fromParticipants participants: [SKYParticipant]) -> String? {
        let userNameField = SKYChatUIModelCustomization.default().userNameField
        let participantNames = participants.flatMap { (eachParticipant) -> String? in
            return eachParticipant.record.object(forKey: userNameField) as? String
        }

        guard participantNames.count > 0 else {
            return nil
        }

        return participantNames.sorted().joined(separator: ", ")
    }

    /**
     Generate a name list from a list of participant. The title will be concatenating all
     participant names and ignoring some of the users.
     */
    public func nameList(fromParticipants participants: [SKYParticipant],
                         ignoringUserIDs: [String]) -> String? {
        let filtered = participants.filter { !ignoringUserIDs.contains($0.recordName) }
        return self.nameList(fromParticipants: filtered)
    }

    /**
     Generate a name list from a list of participant. The title will be concatenating all
     participant names and current user name will be shown as "You".
     */
    public func nameList(fromParticipants participants: [SKYParticipant],
                         currentUserID: String) -> String? {

        guard participants.contains(where: { $0.recordName == currentUserID }) else {
            return self.nameList(fromParticipants: participants)
        }

        if let nameList = self.nameList(fromParticipants: participants,
                                        ignoringUserIDs: [currentUserID]) {
            return String.localizedStringWithFormat("%@ and You", nameList)
        } else {
            return nil
        }
    }
}
