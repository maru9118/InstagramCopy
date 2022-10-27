//
//  Feed ViewController.swift
//  InstagramCopy
//
//  Created by jonghoKim on 2022/06/28.
//

import UIKit
import Firebase
import ActiveLabel
import FirebaseMessaging

private let reuseIdentifier = "Cell"

class FeedViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, FeedCellDelegate {
    
    var posts = [Post]()
    var viewSinglePost = false
    var post: Post?
    
    var currentKey: String?
    
    var userProfileController: UserProfileViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.backgroundColor = .white
        self.collectionView!.register(FeedCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView.refreshControl = refreshControl
        
        configureNavigationBar()
        
        setUserFCMToken()
        
        if !viewSinglePost {
            fetchPosts()
        }
    }
    
    // MARK: - UICollectionViewFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = view.frame.width
        var height = width + 8 + 40 + 8
        height += 50
        height += 60
        
        return CGSize(width: width, height: height)
    }
    
    // MARK: UICollectionViewDataSource
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if posts.count > 4 {
            if indexPath.item == posts.count - 1 {
                fetchPosts()
            }
        }
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if viewSinglePost {
            return 1
        } else {
            return posts.count
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! FeedCell
        
        cell.delegate = self
        
        if viewSinglePost {
            if let post = self.post {
                cell.post = post
            }
        } else {
            cell.post = posts[indexPath.item]
        }
        
        handleHashtagTapped(forCell: cell)
        handleUsernameTapped(forCell: cell)
        handleMentionTapped(forCell: cell)
        
        return cell
    }
    
    // MARK: - FeedCellDelegate Protocal
    
    func handleUsernameTapped(for cell: FeedCell) {
        guard let post = cell.post else { return }
        let userProfileVC = UserProfileViewController(collectionViewLayout: UICollectionViewFlowLayout())
        
        userProfileVC.user = post.user
        
        navigationController?.pushViewController(userProfileVC, animated: true)
    }
    
    func handleOptionsTapped(for cell: FeedCell) {
        guard let post = cell.post else { return }
        
        if post.ownerUid == Auth.auth().currentUser?.uid {
            let alertController = UIAlertController(title: "Options", message: nil, preferredStyle: .actionSheet)
            
            alertController.addAction(UIAlertAction(title: "Delete post", style: .destructive, handler: { (_) in
                post.deletePost()
                
                if !self.viewSinglePost {
                    self.handleRefresh()
                } else {
                    if let userProfileController = self.userProfileController {
                        _ = self.navigationController?.popViewController(animated: true)
                        userProfileController.handleRefresh()
                    }
                }
            }))
            
            alertController.addAction(UIAlertAction(title: "Edit post", style: .default, handler: { (_) in
                let uploadVC = UploadPostViewController()
                let navigationController = UINavigationController(rootViewController: uploadVC)
                uploadVC.postToEdit = post
                uploadVC.uploadAction = UploadPostViewController.UploadAction(index: 1)
                
                self.present(navigationController, animated: true, completion: nil)
            }))
            
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            present(alertController, animated: true, completion: nil)
        }
    }
    
    func handleLikeTapped(for cell: FeedCell, isDoubleTap: Bool) {
        guard let post = cell.post else { return }
        
        if post.didLike {
            if !isDoubleTap {
                post.adjustLike(addLike: false) { (like) in
                    cell.likeLabel.text = "\(like) likes"
                    cell.likeButton.setImage(UIImage(named: "like_unselected.png"), for: .normal)
                    post.didLike = false
                }
            }
        } else {
            post.adjustLike(addLike: true) { (like) in
                cell.likeLabel.text = "\(like) likes"
                cell.likeButton.setImage(UIImage(named: "like_selected.png"), for: .normal)
            }
        }
        
//        guard let likes = post.likes else { return }
//        cell.likeLabel.text = "\(likes) likes"
    }
    
    func handleShowLike(for cell: FeedCell) {
        guard let post = cell.post else { return }
        guard let postId = post.postId else { return }
        
        let followLikeVC = FollowLikeViewController()
        followLikeVC.viewingMode = FollowLikeViewController.ViewingMode(index: 2)
        followLikeVC.postId = postId
        navigationController?.pushViewController(followLikeVC, animated: true)
    }
    
    func handleConfigureLikeButton(for cell: FeedCell) {
        guard let post = cell.post else { return }
        guard let postId = post.postId else { return }
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        USER_LIKES_REF.child(currentUid).observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.hasChild(postId) {
                post.didLike = true
                cell.likeButton.setImage(UIImage(named: "like_selected.png"), for: .normal)
            } else {
                post.didLike = false
                cell.likeButton.setImage(UIImage(named: "like_unselected.png"), for: .normal)
            }
        }
    }
    
    func handleCommentTapped(for cell: FeedCell) {
        guard let post = cell.post else { return }
        let commentVC = CommentCollectionViewController(collectionViewLayout: UICollectionViewFlowLayout())
        commentVC.post = post
        navigationController?.pushViewController(commentVC, animated: true)
    }
    
    // MARK: - Handlers
    
    @objc func handleRefresh() {
        posts.removeAll(keepingCapacity: false)
        self.currentKey = nil
        fetchPosts()
        collectionView.reloadData()
    }
    
    @objc func handleShowMessage() {
        let messageController = MessageController()
        navigationController?.pushViewController(messageController, animated: true)
    }
    
    func handleHashtagTapped(forCell cell: FeedCell) {
        cell.captionLabel.handleHashtagTap { (hashtag) in
            let hashtagController = HashtagController(collectionViewLayout: UICollectionViewFlowLayout())
            hashtagController.hashtag = hashtag
            self.navigationController?.pushViewController(hashtagController, animated: true)
        }
    }
    
    func handleMentionTapped(forCell cell: FeedCell) {
        cell.captionLabel.handleMentionTap { (username) in
            self.getMentionedUser(withUsername: username)
        }
    }
    
    func handleUsernameTapped(forCell cell: FeedCell) {
        guard let user = cell.post?.user else { return }
        guard let username = user.username else { return }
        let customType = ActiveType.custom(pattern: "^\(username)\\b")
        
        cell.captionLabel.handleCustomTap(for: customType) { (_) in
            let userProfileController = UserProfileViewController(collectionViewLayout: UICollectionViewFlowLayout())
            self.navigationController?.pushViewController(userProfileController, animated: true)
        }
    }
    
    func configureNavigationBar() {
        if !viewSinglePost {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(handlerLogout))
        }
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "send2.png"), style: .plain, target: self, action: #selector(handleShowMessage))
        
        self.navigationItem.title = "Feed"
    }
    
    @objc func handlerLogout() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alertController.addAction(UIAlertAction(title: "Log out", style: .destructive, handler: { (_) in
            
            do {
                try Auth.auth().signOut()
                
                let loginVC = LoginViewController()
                let navController = UINavigationController(rootViewController: loginVC)
                self.present(navController, animated: true, completion: nil)
                
                print("logout")
            } catch {
                
            }
        }))
        
        alertController.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - API
    
    func setUserFCMToken() {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        guard let fcmToken = Messaging.messaging().fcmToken else { return }
        
        let values = ["fcmToken": fcmToken]
        
        USER_REF.child(currentUid).updateChildValues(values)
    }
    
    func updateUserFeeds() {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        USER_FOLLOWING_REF.child(currentUid).observe(.childAdded) { (snapshot) in
            let followingUserId = snapshot.key
            
            USER_FOLLOWER_REF.child(followingUserId).observe(.childAdded) { (snapshot) in
                let postId = snapshot.key
                print("feedVC: 1")
                USER_FEED_REF.child(currentUid).updateChildValues([postId: 1])
            }
        }
        
        USER_POSTS_REF.child(currentUid).observe(.childAdded) { (snapshot) in
            let postId = snapshot.key
            print("feedVC: 2")
            USER_FEED_REF.child(currentUid).updateChildValues([postId: 1])
        }
    }
    
    func fetchPosts() {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        if currentKey == nil {
            USER_FEED_REF.child(currentUid).queryLimited(toLast: 5).observeSingleEvent(of: .value) { (snapshot) in
                
                self.collectionView.refreshControl?.endRefreshing()
                
                guard let first = snapshot.children.allObjects.first as? DataSnapshot else { return }
                guard let allObjects = snapshot.children.allObjects as? [DataSnapshot] else { return }
                
                allObjects.forEach { (snapshot) in
                    let postId = snapshot.key
                    self.fetchPost(withPostId: postId)
                }
                self.currentKey = first.key
            }
        } else {
            USER_FEED_REF.child(currentUid).queryOrderedByKey().queryEnding(atValue: self.currentKey).queryLimited(toLast: 6).observeSingleEvent(of: .value) { (snapshot) in
                guard let first = snapshot.children.allObjects.first as? DataSnapshot else { return }
                guard let allObjects = snapshot.children.allObjects as? [DataSnapshot] else { return }
                
                allObjects.forEach { (snapshot) in
                    let postId = snapshot.key
                    if postId != self.currentKey {
                        self.fetchPost(withPostId: postId)
                    }
                }
                self.currentKey = first.key
            }
        }
    }
    
    func fetchPost(withPostId postId: String) {
        Database.fetchPost(with: postId) { (post) in
            self.posts.append(post)
            
            self.posts.sort(by: { (post1, post2) -> Bool in
                return post1.creationDate > post2.creationDate
            })
            self.collectionView?.reloadData()
        }
    }
}
