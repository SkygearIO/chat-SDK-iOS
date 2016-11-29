//
//  ConversationRoomViewController.swift
//  chat-demo
//
//  Created by Joey on 9/1/16.
//  Copyright © 2016 Oursky Ltd. All rights reserved.
//

import UIKit
import SKYKit
import SKYKitChat

class ConversationRoomViewController:
    UIViewController,
    UITableViewDelegate,
    UITableViewDataSource,
    UITextFieldDelegate,
    UIImagePickerControllerDelegate,
    UINavigationControllerDelegate {
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var bottomEdgeConstraint: NSLayoutConstraint!
    @IBOutlet var messaegBodyTextField: UITextField!
    @IBOutlet var messageMetadataTextField: UITextField!
    @IBOutlet var chosenAsseTexttLabel: UILabel!
    
    var userCon: SKYUserConversation!
    var messages = [SKYMessage]()
    var lastReadMessage:SKYMessage?
    var chosenAsset:SKYAsset?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = userCon.conversation.title
        self.lastReadMessage = userCon.lastReadMessage
        
        // listening keyboard event
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil, queue: nil) { (note) in
            let keyboardFrame: CGRect = (note.userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
            let animationDuration: TimeInterval = (note.userInfo![UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
            let animationCurve: UIViewAnimationCurve = UIViewAnimationCurve(rawValue: (note.userInfo![UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).intValue)!
            UIView.animate(withDuration: animationDuration, animations: {
                UIView.setAnimationCurve(animationCurve)
                self.bottomEdgeConstraint.constant = keyboardFrame.height
                self.view.layoutIfNeeded()
            })
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIKeyboardWillHide, object: nil, queue: nil) { (note) in
            let animationDuration: TimeInterval = (note.userInfo![UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
            
            UIView.animate(withDuration: animationDuration, animations: {
                self.bottomEdgeConstraint.constant = 0
                self.view.layoutIfNeeded()
            })
            
        }
        
        guard let chat = SKYContainer.default().chatExtension() else {
            NSLog("No chat extension")
            return
        }

        // subscribe chat messages
        // FIXME: SDK should help deserialize SKYMessage?
        chat.subscribeHandler({ (dict) in
            if let recordType = dict["record_type"] as? String, recordType == "message",
                let recordDic = dict["record"] as? [AnyHashable: Any],
                let record = SKYRecordDeserializer().record(with: recordDic),
                let message = SKYMessage(record: record), message.conversationID == self.userCon.conversation.recordID {
                
                self.messages.insert(message, at: 0)
                self.tableView.insertRows(at: [IndexPath.init(row: 0, section: 0)], with: .automatic)
            }
        })
        
        // get conversation messages
        chat.fetchMessages(conversation: userCon.conversation, limit: 100, beforeTime: Date()) { (messages, error) in
            if let err = error {
                let alert = UIAlertController(title: "Unable to fetch conversations", message: err.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }
            
            if let msg = messages {
                chat.markDeliveredMessages(msg, completion: nil);
                chat.markReadMessages(msg, completion: nil);
                
                self.messages = msg
                self.tableView.reloadData()
            }
        }
    }
    
    // MARK: - Action
    
    @IBAction func showDetail(_ sender: AnyObject) {
        self.performSegue(withIdentifier: "conversation_detail", sender: userCon)
    }

    @IBAction func sendMessage(_ sender: AnyObject) {
        // convert metadata to dictionary
        var metadateDic:[String: Any]?
        if let metadata = messageMetadataTextField.text, !metadata.isEmpty {
            let jsonData = messageMetadataTextField.text!.data(using: String.Encoding.utf8)
            do {
                metadateDic = try JSONSerialization.jsonObject(with: jsonData!, options: []) as? [String: Any]
            } catch let error {
                print("json error: \(error)")
            }
        }
        
        guard let message = SKYMessage() else {
            print("cannot create message")
            return
        }
        message.body = messaegBodyTextField.text
        message.metadata = metadateDic
        message.attachment = chosenAsset
        SKYContainer.default().chatExtension().addMessage(message, to: userCon.conversation) { (message, error) in
                if let err = error {
                    let alert = UIAlertController(title: "Unable to send message", message: err.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    return
                }
                
                if message != nil {
                    print("send message successful")
                    self.messaegBodyTextField.text = ""
                    self.messageMetadataTextField.text = ""
                }
        }
    }
    
    @IBAction func chooseImageAsset(_ sender: AnyObject) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .savedPhotosAlbum
        imagePicker.delegate = self
        self.navigationController?.present(imagePicker, animated: true, completion: nil)
    }
    
    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let message = messages[indexPath.row]
        
        var lastRead = ""
        if lastReadMessage != nil && lastReadMessage?.recordID.recordName == message.recordID.recordName {
            lastRead = "  === last read message ==="
        }
        let messageBody = message.body != nil ? message.body! : "";
        cell.textLabel?.text = messageBody + lastRead
        cell.detailTextLabel?.text = message.recordID.canonicalString
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "message_detail", sender: messages[indexPath.row].dictionary)
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let unreadAction = UITableViewRowAction(style: UITableViewRowActionStyle.normal , title: "mark as unread") { (action, indexPath) in
            
            let message = self.messages[indexPath.row]
            SKYContainer.default().chatExtension().markLastReadMessage(message,
                                                            in: self.userCon) { (userCon, error) in
                    
                    if let err = error {
                        let alert = UIAlertController(title: "Unable to mark last read message", message: err.localizedDescription, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                        return
                    }
                    
                    self.refreshConversation()
            }
        }
        
        return [unreadAction]
    }
    
    // MARK: - Text field delegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "message_detail" {
            let controller = segue.destination as! DictionaryDetailViewController
            controller.dictionary = sender as! NSDictionary
        } else if segue.identifier == "conversation_detail" {
            let controller = segue.destination as! ConversationDetailViewController
            controller.userCon = sender as! SKYUserConversation
        }
    }
    
    func refreshConversation() {
        SKYContainer.default().chatExtension().fetchUserConversation(id: self.userCon.conversation.recordID.recordName) { (conversation, error) in
            if let conv = conversation {
                self.userCon = conv
                self.lastReadMessage = conv.lastReadMessage
                self.tableView.reloadData()
            }
        }
    }

    // MARK: - UIImagePickerControllerDelegate

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        self.navigationController?.dismiss(animated: true, completion: nil)
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            return
        }
        
        if let asset = SKYAsset(data: UIImagePNGRepresentation(image)) {
            asset.mimeType = "image/png"
            SKYContainer.default().uploadAsset(asset) { (asset, error) in
                if let err = error {
                    let alert = UIAlertController(title: "Unable to upload", message: err.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    return
                }

                if let ast = asset {
                    self.chosenAsset = ast
                    self.chosenAsseTexttLabel.text = ast.description
                }
            }
        }

    }
}
