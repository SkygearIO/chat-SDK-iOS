//
//  UserQueryViewController.swift
//  Swift-Example
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

import Foundation
import SKYKitChat
import Kingfisher

class UserQueryViewController: SKYChatParticipantListViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.queryMethod = .ByName
        self.dataSource = self
    }
}

extension UserQueryViewController: SKYChatParticipantListViewControllerDataSource {
    func listViewController(_ controller: SKYChatParticipantListViewController,
                            avatarImageForParticipant participant: SKYRecord,
                            atIndexPath indexPath: IndexPath) -> UIImage? {

        /*
         * If you want to use an remote image as the avatar image, you need to fetch the
         * image asynchronously and return a placeholder such that the UI can display something
         * right away. When the image is fetched, we call update function to update the avatar
         * image in the UITableViewCell.
         */

        var name = ""
        if let participantName = participant.object(forKey: "name") as? String {
            name = participantName
        }

        let placeholderImage =  UIImage.avatarImage(forInitialsOfName: name)

        if let url = URL(string: "http://thecatapi.com/api/images/get?size=small&_r=\(indexPath.row)") {
            ImageDownloader.default.downloadImage(with: url,
                                                  options: nil,
                                                  progressBlock: nil) { (downloadedImage, error, url, data) in
                                                    guard error == nil else {
                                                        print("Failed to download image: \(error?.localizedDescription ?? "")")
                                                        return
                                                    }

                                                    if let img = downloadedImage {
                                                        self.update(avatarImage: img,
                                                                    forCellAtIndexPath: indexPath,
                                                                    inTableView: controller.tableView!)
                                                    } else {
                                                        print("Get nil image")
                                                    }
            }
        }

        return placeholderImage
    }

    func update(avatarImage image: UIImage,
                forCellAtIndexPath indexPath: IndexPath,
                inTableView tableView: UITableView) {

        if let cell = tableView.cellForRow(at: indexPath) as? SKYChatParticipantListViewCell {
            cell.avatarImageView?.image = image
        }
    }
}
