//
//  User.swift
//  InstagramCopy
//
//  Created by jonghoKim on 2022/06/29.
//

import Foundation
import Firebase

class User {
    var username: String!
    var name: String!
    var profileImageUrl: String!
    var uid: String!
    var isFollowed = false
    
    init(uid: String, dictionary: Dictionary<String, AnyObject>) {
        
        self.uid = uid
        
        if let username = dictionary["username"] as? String {
            self.username = username
        }
        
        if let name = dictionary["name"] as? String {
            self.name = name
        }
        
        if let profileImageUrl = dictionary["profileImageUrl"] as? String {
            self.profileImageUrl = profileImageUrl
        }
    }
    
    func follow() {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        guard let uid = uid else { return }
        
        self.isFollowed = true
        
        USER_FOLLOWING_REF.child(currentUid).updateChildValues([uid: 1])
        USER_FOLLOWER_REF.child(uid).updateChildValues([currentUid: 1])
        
        uploadFollowNotificationToServer()
        
        USER_POSTS_REF.child(uid).observe(.childAdded) { (snapshot) in
            let postId = snapshot.key
            print("follow uid: \(uid)")
            print("follow postId: \(postId)")
            print("follow currentId: \(currentUid)")
            
            USER_FEED_REF.child(currentUid).updateChildValues([postId: 1])
        }
    }
    
    func unfollow() {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        guard let uid = uid else { return }
        
        self.isFollowed = false
        
        USER_FOLLOWING_REF.child(currentUid).removeValue()
        USER_FOLLOWER_REF.child(uid).child(currentUid).removeValue()

        USER_POSTS_REF.child(uid).observe(.childAdded) { (snapshot) in
            let postId = snapshot.key
//            print("unfollow postId: \(postId)")
//            print("unfollow currentId: \(currentUid)")
            USER_FEED_REF.child(currentUid).child(postId).removeValue()
        }
    }
    
    func checkIfUserIsFollowed(completion: @escaping (Bool) -> ()) {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        USER_FOLLOWING_REF.child(currentUid).observeSingleEvent(of: .value) { (snapshot) in
            
            if snapshot.hasChild(self.uid) {
                self.isFollowed = true
                completion(true)
            } else {
                self.isFollowed = false
                completion(false)
            }
        }
    }
    
    func uploadFollowNotificationToServer() {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        let creationDate = Int(NSDate().timeIntervalSince1970)
        
        let values = ["checked": 0,
                      "creationDate": creationDate,
                      "uid": currentUid,
                      "type": FOLLOW_INT_VALUE] as [String : Any]
        
        NOTIFICATION_REF.child(self.uid).childByAutoId().updateChildValues(values)
        
    }
}
