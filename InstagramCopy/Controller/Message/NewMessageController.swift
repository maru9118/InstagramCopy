//
//  NewMessageController.swift
//  InstagramCopy
//
//  Created by jonghoKim on 2022/07/17.
//

import UIKit
import Firebase

private let reuseIdentifier = "NewMessageCell"

class NewMessageController: UITableViewController {
    
    var users = [User]()
    var messageController: MessageController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(NewMessageCell.self, forCellReuseIdentifier: reuseIdentifier)
         
        configureNavigationBar()
        
        fetchUsers()
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! NewMessageCell
        cell.user = users[indexPath.row]
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.dismiss(animated: true) {
            let user = self.users[indexPath.row]
            self.messageController?.showChatController(forUser: user)
        }
    }
    
    // MARK: - Handler
    
    func configureNavigationBar() {
        navigationItem.title = "Message"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(handleCancel))
        navigationItem.leftBarButtonItem?.tintColor = .black
    }
    
    @objc func handleCancel() {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - API
    
    func fetchUsers() {
        USER_REF.observe(.childAdded) { (snapshot) in
            let uid = snapshot.key
            
            if uid != Auth.auth().currentUser?.uid {
                Database.fetchUser(with: uid) { (user) in
                    self.users.append(user)
                    self.tableView.reloadData()
                }
            }
        }
    }
}
