//
//  HashtagController.swift
//  InstagramCopy
//
//  Created by jonghoKim on 2022/07/18.
//

import UIKit
import Firebase

private let reuseIdeentifier = "HashtagCell"

class HashtagController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    var posts = [Post]()
    var hashtag: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureNavigationBar()
        
        collectionView.backgroundColor = .white
        collectionView.register(HashtagCell.self, forCellWithReuseIdentifier: reuseIdeentifier)
        
        fetchPost()
    }
    
    // MARK: - UICollectionViewFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (view.frame.width - 2) / 3
        return CGSize(width: width, height: width)
    }
    
    // MARK: - UIColleciontView DataSource
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdeentifier, for: indexPath) as! HashtagCell
        cell.post = posts[indexPath.item]
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let feedVC = FeedViewController(collectionViewLayout: UICollectionViewFlowLayout())
        feedVC.viewSinglePost = true
        feedVC.post = posts[indexPath.item]
        
        navigationController?.pushViewController(feedVC, animated: true)
    }
    
    // MARK: - Handlers
    
    func configureNavigationBar() {
        guard let hashtag = self.hashtag else { return }
        navigationItem.title = hashtag
    }
    
    // MARK: - API
    
    func fetchPost() {
        guard let hashtag = self.hashtag else { return }
        
        HASHTAG_POST_REF.child(hashtag).observe(.childAdded) { (snapshot) in
            
            let postId = snapshot.key
            
            Database.fetchPost(with: postId) { (post) in
                self.posts.append(post)
                self.collectionView?.reloadData()
            }
        }
    }
}
