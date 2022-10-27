//
//  NotificationViewController.swift
//  InstagramCopy
//
//  Created by jonghoKim on 2022/06/28.
//

import UIKit
import Firebase

private let notificationCell = "NotificationCell"

class NotificationViewController: UITableViewController, NotificationCellDelegate {
    
    var timer: Timer?
    
    var notifications = [Notification]()
    
    var currentKey: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.separatorColor = .clear
        
        navigationItem.title = "Notifications"
        
        tableView.register(NotificationCell.self, forCellReuseIdentifier: notificationCell)
        
        fetchNotification()
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notifications.count
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if notifications.count > 4 {
            if indexPath.row == notifications.count - 1 {
                fetchNotification()
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: notificationCell, for: indexPath) as! NotificationCell
        cell.notification = notifications[indexPath.row]
        cell.delegate = self
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let notification = notifications[indexPath.row]
        
        let userProfileVC = UserProfileViewController(collectionViewLayout: UICollectionViewFlowLayout())
        userProfileVC.user = notification.user
        navigationController?.pushViewController(userProfileVC, animated: true)
    }
    
    // MARK: - NotificationCellDelegate protocal
    
    func handleFollowTapped(for cell: NotificationCell) {
        guard let user = cell.notification?.user else { return }
        
        if user.isFollowed {
            user.unfollow()
            cell.followButton.configure(didFollow: false)
        } else {
            user.follow()
            cell.followButton.configure(didFollow: true)
        }
    }
    
    func handlePostTapped(for cell: NotificationCell) {
        guard let post = cell.notification?.post else { return }
        
        let feedVC = FeedViewController(collectionViewLayout: UICollectionViewFlowLayout())
        feedVC.viewSinglePost = true
        feedVC.post = post
        navigationController?.pushViewController(feedVC, animated: true)
    }
    
    // MARK: - Handler
    
    func handleReloadTable() {
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(handleSortNotification), userInfo: nil, repeats: false)
    }
    
    @objc func handleSortNotification() {
        self.notifications.sort { (notification1, notification2) in
            return notification1.creationDate > notification2.creationDate
        }
        self.tableView.reloadData()
    }
    
    // MARK: - API
    
    func fetchNotifications(withNotificationID notificationID: String, dataSnapshot snapshot: DataSnapshot) {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        guard let dictionary = snapshot.value as? Dictionary<String, AnyObject> else { return }
        guard let uid = dictionary["uid"] as? String else { return }
        
        Database.fetchUser(with: uid) { (user) in
            if let postId = dictionary["postId"] as? String {
                Database.fetchPost(with: postId) { (post) in
                    let notification = Notification(user: user, post: post, dictionary: dictionary)
                    self.notifications.append(notification)
                    self.handleReloadTable()
                }
            } else {
                let notification = Notification(user: user, dictionary: dictionary)
                self.notifications.append(notification)
                self.handleReloadTable()
            }
        }
        NOTIFICATION_REF.child(currentUid).child(notificationID).child("checked").setValue(1)
    }
    
    func fetchNotification() {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        if currentKey == nil {
            NOTIFICATION_REF.child(currentUid).queryLimited(toLast: 5).observeSingleEvent(of: .value) { (snapshot) in
                
                guard let first = snapshot.children.allObjects.first as? DataSnapshot else { return }
                guard let allObjects = snapshot.children.allObjects as? [DataSnapshot] else { return }
                
                allObjects.forEach { (snapshot) in
                    let notificationID = snapshot.key
                    self.fetchNotifications(withNotificationID: notificationID, dataSnapshot: snapshot)
                }
                self.currentKey = first.key
            }
        } else {
            NOTIFICATION_REF.child(currentUid).queryOrderedByKey().queryEnding(atValue: self.currentKey).queryLimited(toLast: 6).observeSingleEvent(of: .value) { (snapshot) in
                guard let first = snapshot.children.allObjects.first as? DataSnapshot else { return }
                guard let allObjects = snapshot.children.allObjects as? [DataSnapshot] else { return }
                
                allObjects.forEach { (snapshot) in
                    let notificationID = snapshot.key
                    
                    if notificationID != self.currentKey {
                        self.fetchNotifications(withNotificationID: notificationID, dataSnapshot: snapshot)
                    }
                    self.currentKey = first.key
                }
            }
        }
    }
}

