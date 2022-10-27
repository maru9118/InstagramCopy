//
//  MessageController.swift
//  InstagramCopy
//
//  Created by jonghoKim on 2022/07/17.
//

import UIKit
import Firebase

private let reuseIdentifier = "MessageCell"

class MessageController: UITableViewController {
    
    var message = [Message]()
    var messageDictionary = [String: Message]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(MessageCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView.separatorStyle = .none
        configureNavigationBar()
        
        fetchMessages()
        
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return message.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! MessageCell
        cell.message = message[indexPath.row]
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let message = message[indexPath.row]
        let chatPartnerId = message.getChatPartnerId()
        Database.fetchUser(with: chatPartnerId) { (user) in
            self.showChatController(forUser: user)
        }
    }
    
    // MARK: - Handler
    
    func configureNavigationBar() {
        navigationItem.title = "Message"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(handleNewMessage))
    }
    
    func showChatController(forUser user: User) {
        let chatController = ChatController(collectionViewLayout: UICollectionViewFlowLayout())
        chatController.user = user
        navigationController?.pushViewController(chatController, animated: true)
    }
    
    @objc func handleNewMessage() {
        let newMessageController = NewMessageController()
        newMessageController.messageController = self
        let navigationController = UINavigationController(rootViewController: newMessageController)
        self.present(navigationController, animated: true, completion: nil)
    }
    
    // MARK: - API
    
    func fetchMessages() {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        self.message.removeAll()
        self.messageDictionary.removeAll()
        self.tableView.reloadData()
        
        USER_MESSAGE_REF.child(currentUid).observe(.childAdded) { (snapshot) in
            let uid = snapshot.key
            
            USER_MESSAGE_REF.child(currentUid).child(uid).observe(.childAdded) { (snapshot) in
                let messageId = snapshot.key
                
                self.fetchMessage(withMessageId: messageId)
            }
        }
    }
    
    func fetchMessage(withMessageId messageId: String) {
        MESSAGE_REF.child(messageId).observeSingleEvent(of: .value) { (snapshot) in
            guard let dictionary = snapshot.value as? Dictionary<String, AnyObject> else { return }
            
            let message = Message(dictionary: dictionary)
            let chatPartnerId = message.getChatPartnerId()
            self.messageDictionary[chatPartnerId] = message
            self.message = Array(self.messageDictionary.values)
            
            self.tableView?.reloadData()
        }
    }
}
