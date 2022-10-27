//
//  Post.swift
//  InstagramCopy
//
//  Created by jonghoKim on 2022/07/08.
//

import Foundation
import Firebase

class Post {
    
    var caption: String!
    var likes: Int!
    var imageUrl: String!
    var ownerUid: String!
    var creationDate: Date!
    var postId: String!
    var user: User?
    var didLike = false
    
    init(postId: String!, user: User, dictionary: Dictionary<String, AnyObject>) {
        self.postId = postId
        
        self.user = user
        
        if let caption = dictionary["caption"] as? String {
            self.caption = caption
        }
        
        if let likes = dictionary["likes"] as? Int {
            self.likes = likes
        }
        
        if let imageUrl = dictionary["imageUrl"] as? String {
            self.imageUrl = imageUrl
        }
        
        if let ownerUid = dictionary["ownerUid"] as? String {
            self.ownerUid = ownerUid
        }
        
        if let creationDate = dictionary["creationDate"] as? Double {
            self.creationDate = Date(timeIntervalSince1970: creationDate)
        }
    }
    
    func deletePost() {
        print(#function)
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        Storage.storage().reference(forURL: self.imageUrl).delete(completion: nil)

        USER_FOLLOWER_REF.child(currentUid).observe(.childAdded) { (snapshot) in
            let followUid = snapshot.key
            USER_FEED_REF.child(followUid).child(self.postId).removeValue()
        }

        USER_FEED_REF.child(currentUid).child(postId).removeValue()
        USER_POSTS_REF.child(currentUid).child(postId).removeValue()
        POST_LIKES_REF.child(postId).observe(.childAdded) { (snapshot) in
            let uid = snapshot.key
            
            USER_LIKES_REF.child(uid).child(self.postId).observeSingleEvent(of: .value) { (snapshot) in
                guard let notificationID = snapshot.value as? Int else { return }
                
                NOTIFICATION_REF.child(self.postId).child(String(notificationID)).removeValue { (err, ref) in
                    POST_LIKES_REF.child(self.postId).removeValue()
                    USER_LIKES_REF.child(uid).child(self.postId).removeValue()
                }
            }
        }
        
        let words = caption.components(separatedBy: .whitespacesAndNewlines)
        for var word in words {
            if word.hasPrefix("#") {
                word = word.trimmingCharacters(in: .punctuationCharacters)
                word = word.trimmingCharacters(in: .symbols)
                
                HASHTAG_POST_REF.child(word).child(postId).removeValue()
            }
        }
        
        COMMENT_REF.child(postId).removeValue()
        POSTS_REF.child(postId).removeValue()
    }
    
    func adjustLike(addLike: Bool, completion: @escaping(Int) -> ()) {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        guard let postId = self.postId else { return }
        
        if addLike {
            print("addLike")
            
            self.sendLikeNotificationToServer()
            
            USER_LIKES_REF.child(currentUid).updateChildValues([postId: 1]) { (error, ref) in
                POST_LIKES_REF.child(postId).updateChildValues([currentUid: 1]) { (error, ref) in
                    self.likes = self.likes + 1
                    self.didLike = true
                    completion(self.likes)
                    POSTS_REF.child(self.postId).child("likes").setValue(self.likes)
                }
            }
        } else {
            
            USER_LIKES_REF.child(currentUid).child(postId).observeSingleEvent(of: .value) { (snapshot) in
                guard let notificationID = snapshot.value as? String else { return }
                
                NOTIFICATION_REF.child(self.ownerUid).child(notificationID).removeValue { (error, ref) in
                    USER_LIKES_REF.child(currentUid).child(postId).removeValue { (error, ref) in
                        POST_LIKES_REF.child(postId).child(currentUid).removeValue { (error, ref) in
                            guard self.likes > 0 else { return }
                            self.likes = self.likes - 1
                            self.didLike = false
                            completion(self.likes)
                            POSTS_REF.child(postId).child("likes").setValue(self.likes)
                        }
                    }
                }
            }
        }
    }
    
    func sendLikeNotificationToServer() {
        
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        let creationDate = Int(NSDate().timeIntervalSince1970)
        
        if currentUid != self.ownerUid {
            let values = ["checked": 0,
                          "creationDate": creationDate,
                          "uid": currentUid,
                          "type": 0,
                          "postId": postId] as [String : Any]

            let notificationRef = NOTIFICATION_REF.child(self.ownerUid).childByAutoId()
            notificationRef.updateChildValues(values) { (error, ref) in
                USER_LIKES_REF.child(currentUid).child(self.postId).setValue(notificationRef.key)
            }
        }
    }
}
