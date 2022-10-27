//
//  UploadPostViewController.swift
//  InstagramCopy
//
//  Created by jonghoKim on 2022/06/28.
//

import UIKit
import Firebase

class UploadPostViewController: UIViewController, UITextViewDelegate {
    
    enum UploadAction: Int {
        case UploadPost
        case SaveChages
        
        init(index: Int) {
            switch index {
            case 0: self = .UploadPost
            case 1: self = .SaveChages
            default: self = .UploadPost
            }
        }
    }
    
    var uploadAction: UploadAction!
    
    var selectedImage: UIImage?
    
    var postToEdit: Post?
    
    let photoImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .lightGray
        return iv
    }()
    
    let captionTextView: UITextView = {
        let tv = UITextView()
        tv.backgroundColor = UIColor.systemGroupedBackground
        tv.font = UIFont.systemFont(ofSize: 12)
        return tv
    }()
    
    let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor(red: 149/255, green: 204/255, blue: 244/255, alpha: 1)
        button.setTitle("Share", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 5
        button.isEnabled = false
        button.addTarget(self, action: #selector(handleUploadAction), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureViewComponents()
        
        loadImage()
        
        captionTextView.delegate = self
        
        view.backgroundColor = .white
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if uploadAction == .SaveChages {
            guard let post = self.postToEdit else { return }
            actionButton.setTitle("Save Changes", for: .normal)
            self.navigationItem.title = "Edit Post"
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(handleCancel))
            navigationController?.navigationBar.tintColor = .black
            photoImageView.loadImage(with: post.imageUrl)
            captionTextView.text = post.caption
        } else {
            actionButton.setTitle("Share", for: .normal)
            self.navigationItem.title = "Upload Post"
        }
    }
    
    func configureViewComponents() {
        view.addSubview(photoImageView)
        photoImageView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: nil, right: nil, paddingTop: 92, paddingLeft: 12, paddingBottom: 0, paddingRight: 0, widht: 100, height: 100)
        
        view.addSubview(captionTextView)
        captionTextView.anchor(top: view.topAnchor, left: photoImageView.rightAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 92, paddingLeft: 12, paddingBottom: 0, paddingRight: 12, widht: 0, height: 100)
        
        view.addSubview(actionButton)
        actionButton.anchor(top: photoImageView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 12, paddingLeft: 24, paddingBottom: 0, paddingRight: 24, widht: 0, height: 40)
    }
    
    func loadImage() {
        guard let selectedImage = self.selectedImage else { return }
        
        photoImageView.image = selectedImage
    }
    
    func textViewDidChange(_ textView: UITextView) {
        guard !textView.text.isEmpty else {
            actionButton.isEnabled = false
            actionButton.backgroundColor = UIColor(red: 149/255, green: 204/255, blue: 244/255, alpha: 1)
            return
        }
        
        actionButton.isEnabled = true
        actionButton.backgroundColor = UIColor(red: 17/255, green: 154/255, blue: 237/255, alpha: 1)
    }
    
    // MARK: - Handler
    
    func updateUserFeeds(with postId: String) {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        let values = [postId: 1]
        
        USER_FOLLOWER_REF.child(currentUid).observe(.childAdded) { (snapshot) in
            let follwerUid = snapshot.key
            USER_FEED_REF.child(follwerUid).updateChildValues(values)
        }
        USER_FEED_REF.child(currentUid).updateChildValues(values)
    }
    
    @objc func handleUploadAction() {
        buttonSeletor(uploadAction: uploadAction)
    }
    
    @objc func handleCancel() {
        self.dismiss(animated: true)
    }
    
    func buttonSeletor(uploadAction: UploadAction) {
        switch uploadAction {
        case .UploadPost:
            handleUploadPost()
        case .SaveChages:
            handleSavePostChages()
        }
    }
    
    func handleSavePostChages() {
        guard let post = self.postToEdit else { return }
        let updatedCaption = captionTextView.text
        
        uploadHastagToServer(withPostId: post.postId)
        
        POSTS_REF.child(post.postId).child("caption").setValue(updatedCaption) { (err, ref) in
            self.dismiss(animated: true)
        }
    }
    
    func handleUploadPost() {
        guard
            let caption = captionTextView.text,
            let postImg = photoImageView.image,
            let currentUid = Auth.auth().currentUser?.uid else { return }
        
        guard let uploadData = postImg.jpegData(compressionQuality: 0.5) else { return }
        
        let creationDate = Int(NSDate().timeIntervalSince1970)
        
        let fileName = NSUUID().uuidString
        let storageRef =  Storage.storage().reference().child("post_image").child(fileName)
        
        storageRef.putData(uploadData, metadata: nil) { (metaData, error) in
            if let error = error {
                print("post upload error", error.localizedDescription)
                return
            }
            
            storageRef.downloadURL { (downloadUrl, error) in
                guard let postImageUrl = downloadUrl?.absoluteString else { return }
                
                let values = ["caption": caption,
                              "creationDate": creationDate,
                              "likes": 0,
                              "imageUrl": postImageUrl,
                              "ownerUid": currentUid] as [String: Any]
                
                let postId = POSTS_REF.childByAutoId()
                guard let postKey = postId.key else { return }
                
                postId.updateChildValues(values) { (error, reference) in
                    USER_POSTS_REF.child(currentUid).updateChildValues([postKey: 1])
                    
                    self.updateUserFeeds(with: postKey)
                    
                    self.uploadHastagToServer(withPostId: postKey)
                    
                    if caption.contains("@") {
                        self.uploadMentionNotification(forPostId: postKey, withText: caption, isForComment: false)
                    }
                    
                    self.dismiss(animated: true) {
                        self.tabBarController?.selectedIndex = 0
                    }
                }
            }
        }
    }
    
    // MARK: - API
    
    func uploadHastagToServer(withPostId postId: String) {
        guard let caption = captionTextView.text else { return }
        
        let words: [String] = caption.components(separatedBy: .whitespacesAndNewlines)
        for var word in words {
            if word.hasPrefix("#") {
                word = word.trimmingCharacters(in: .punctuationCharacters)
                word = word.trimmingCharacters(in: .symbols)
                
                let hashtagValues = [postId: 1]
                
                HASHTAG_POST_REF.child(word.lowercased()).updateChildValues(hashtagValues)
            }
        }
    }
}
