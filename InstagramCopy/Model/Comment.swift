//
//  Comment.swift
//  InstagramCopy
//
//  Created by jonghoKim on 2022/07/11.
//

import Foundation
import Firebase

class Comment {
    
    var uid: String!
    var commentText: String!
    var creationDate: Date!
    var user: User?
    
    init(user: User, dicitonary: Dictionary<String, AnyObject>) {
        
        self.user = user
        
        if let uid = dicitonary["uid"] as? String {
            self.uid = uid
        }
        
        if let commentText = dicitonary["commentText"] as? String {
            self.commentText = commentText
        }
        
        if let creationDate = dicitonary["creationDate"] as? Double {
            self.creationDate = Date(timeIntervalSince1970: creationDate)
        }
    }
}
