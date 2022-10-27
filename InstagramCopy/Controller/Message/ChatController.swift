//
//  ChatController.swift
//  InstagramCopy
//
//  Created by jonghoKim on 2022/07/17.
//

import UIKit
import Firebase

private let reuseIdentifier = "ChatCell"

class ChatController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    var user: User?
    var messages = [Message]()
    
    lazy var containerView: UIView = {
        let containerView = UIView()
        containerView.frame = CGRect(x: 0, y: 0, width: 100, height: 55)
        
        containerView.addSubview(sendButton)
        sendButton.anchor(top: nil, left: nil, bottom: nil, right: containerView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 8, widht: 50, height: 0)
        sendButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        
        containerView.addSubview(messageTextField)
        messageTextField.anchor(top: containerView.topAnchor, left: containerView.leftAnchor, bottom: containerView.bottomAnchor, right: sendButton.leftAnchor, paddingTop: 0, paddingLeft: 12, paddingBottom: 0, paddingRight: 8, widht: 0, height: 0)
        
        let separatorView = UIView()
        separatorView.backgroundColor = .lightGray
        
        containerView.addSubview(separatorView)
        separatorView.anchor(top: containerView.topAnchor, left: containerView.leftAnchor, bottom: nil, right: containerView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, widht: 0, height: 0.5)
        
        return containerView
    }()
    
    let messageTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Enter Message..."
        return tf
    }()
    
    let sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Send", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        button.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.backgroundColor = .white
        
        collectionView.register(ChatCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        configureNavigationBar()
        
         observeMessage()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
    }
    
    override var inputAccessoryView: UIView? {
        get {
            return containerView
        }
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    // MARK: - CollectionView
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 80
        let message = messages[indexPath.item]
        
        height = estimateFrameForText(message.messageText).height + 20
        
        return CGSize(width: view.frame.width, height: height)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ChatCell
        cell.message = messages[indexPath.item]
        
        configureMessage(cell: cell, message: messages[indexPath.item])
        
        return cell
    }
    
    // MARK: - Handlers
    
    func configureNavigationBar() {
        guard let user = self.user else { return }
        
        navigationItem.title = user.username
        
        let infoButton = UIButton(type: .infoLight)
        infoButton.tintColor = .black
        infoButton.addTarget(self, action: #selector(handleInfoTapped), for: .touchUpInside)
        let infoBarButtonItem = UIBarButtonItem(customView: infoButton)
        
        navigationItem.rightBarButtonItem = infoBarButtonItem
    }
    
    @objc func handleSend() {
        uploadMessageToServer()
        
        messageTextField.text = nil
    }
    
    @objc func handleInfoTapped() {
        let userProfileController = UserProfileViewController(collectionViewLayout: UICollectionViewFlowLayout())
        userProfileController.user = user
        navigationController?.pushViewController(userProfileController, animated: true)
    }
    
    func estimateFrameForText(_ text: String) -> CGRect {
        let size = CGSize(width: 200, height: 100)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], context: nil)
    }
    
    func configureMessage(cell: ChatCell, message: Message) {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        cell.bubbleWidthAnchor?.constant = estimateFrameForText(message.messageText).width + 32
        cell.frame.size.height = estimateFrameForText(message.messageText).height + 20
        
        if message.fromId == currentUid {
            cell.bubbleViewRightAnchor?.isActive = true
            cell.bubbleViewLeftAnchor?.isActive = false
            cell.bubbleView.backgroundColor = UIColor.rgb(red: 0, green: 137, blue: 249)
            cell.textView.textColor = .white
            cell.profileImageView.isHidden = true
        } else {
            cell.bubbleViewRightAnchor?.isActive = false
            cell.bubbleViewLeftAnchor?.isActive = true
            cell.bubbleView.backgroundColor = UIColor.rgb(red: 240, green: 240, blue: 240)
            cell.textView.textColor = .black
            cell.profileImageView.isHidden = false
        }
    }
    
    // MARK: - API
    
    func uploadMessageToServer() {
        guard let messageText = messageTextField.text else { return }
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        guard let user = self.user else { return }
        guard let uid = user.uid else { return }
        let creationDate = Int(NSDate().timeIntervalSince1970)
        
        let messageValues = ["creationDate": creationDate,
                             "fromId": currentUid,
                             "toId": uid,
                             "messageText": messageText] as [String : Any]
        
        let messageRef = MESSAGE_REF.childByAutoId()
        guard let messageKey = messageRef.key else { return }
        
        messageRef.updateChildValues(messageValues)
        
        USER_MESSAGE_REF.child(currentUid).child(uid).updateChildValues([messageKey: 1])
        USER_MESSAGE_REF.child(uid).child(currentUid).updateChildValues([messageKey: 1])
    }
    
    func observeMessage() {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        guard let user = self.user else { return }
        guard let chatPartnerId = user.uid else { return }
        
        USER_MESSAGE_REF.child(currentUid).child(chatPartnerId).observe(.childAdded) { (snapshot) in
            let messageId = snapshot.key
            
            self.fetchMessage(withMessageId: messageId)
        }
    }
    
    func fetchMessage(withMessageId messageId: String) {
        MESSAGE_REF.child(messageId).observeSingleEvent(of: .value) { (snapshot) in
            guard let dictionary = snapshot.value as? Dictionary<String, AnyObject> else { return }
            let message = Message(dictionary: dictionary)
            self.messages.append(message)
            self.collectionView.reloadData()
        }
    }
}
