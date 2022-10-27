//
//  Constants.swift
//  InstagramCopy
//
//  Created by jonghoKim on 2022/06/29.
//

import Foundation
import Firebase

let DB_REF = Database.database(url: "https://instagramcopy-70004-default-rtdb.asia-southeast1.firebasedatabase.app").reference()
let STORAGE_REF = Storage.storage().reference()

let STORAGE_PROFILE_IMAGES_REF = STORAGE_REF.child("profile_image")

let USER_REF = DB_REF.child("users")

let USER_FOLLOWER_REF = DB_REF.child("user-followers")
let USER_FOLLOWING_REF = DB_REF.child("user-following")

let POSTS_REF = DB_REF.child("posts")
let USER_POSTS_REF = DB_REF.child("user-posts")

let USER_FEED_REF = DB_REF.child("user-feed")

let USER_LIKES_REF = DB_REF.child("user-like")
let POST_LIKES_REF = DB_REF.child("post-likes")

let COMMENT_REF = DB_REF.child("comments")

let NOTIFICATION_REF = DB_REF.child("notifications")

let MESSAGE_REF = DB_REF.child("messages")
let USER_MESSAGE_REF = DB_REF.child("user-messages")

let HASHTAG_POST_REF = DB_REF.child("hashtag-post")

let LIKE_INT_VALUE = 0
let COMMENT_INT_VALUE = 1
let FOLLOW_INT_VALUE = 2
let COMMENT_MENTION_INT_VALUE = 3
let POST_MENTION_INT_VALUE = 4
