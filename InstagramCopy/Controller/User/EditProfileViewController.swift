//
//  EditProfileViewController.swift
//  InstagramCopy
//
//  Created by jonghoKim on 2022/07/21.
//

import UIKit
import Firebase

class EditProfileViewController: UIViewController {
    
    var user: User?
    
    var imageChanged = false
    var usernameChaged = false
    var updateUsername: String?
    
    var userProfileController: UserProfileViewController?
    
    let profileImageView: CustomImageView = {
        let iv = CustomImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .lightGray
        return iv
    }()
    
    let changeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Change Profile Photo", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.addTarget(self, action: #selector(handleChageProfilePhoto), for: .touchUpInside)
        return button
    }()
    
    let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .lightGray
        return view
    }()
    
    let usernameTextField: UITextField = {
        let tf = UITextField()
        tf.textAlignment = .center
        tf.borderStyle = .none
        return tf
    }()
    
    let fullnameTextField: UITextField = {
        let tf = UITextField()
        tf.textAlignment = .center
        tf.borderStyle = .none
        tf.isUserInteractionEnabled = false
        return tf
    }()
    
    let fullnameLabel: UILabel = {
        let label = UILabel()
        label.text = "Full name"
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()
    
    let usernameLabel: UILabel = {
        let label = UILabel()
        label.text = "username"
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()
    
    let fullnameSeparatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .lightGray
        return view
    }()
    
    let usernameSeparatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .lightGray
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        configureNavigationBar()
        
        configureViewComponents()
        
        usernameTextField.delegate = self
        
        loadUserData()
    }
    
    // MARK: - Handlers
    
    func configureNavigationBar() {
        navigationItem.title = "Edit Profile"
        
        navigationController?.navigationBar.tintColor = .black
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style:.plain, target: self, action: #selector(handleCancel))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(handleDone))
    }
    
    func configureViewComponents() {
        let frame = CGRect(x: 0, y: 88, width: view.frame.width, height: 150)
        let containerView = UIView(frame: frame)
        containerView.backgroundColor = UIColor.systemGroupedBackground
        
        view.addSubview(containerView)
        
        containerView.addSubview(profileImageView)
        profileImageView.anchor(top: containerView.topAnchor, left: nil, bottom: nil, right: nil, paddingTop: 16, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, widht: 80, height: 80)
        profileImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
        profileImageView.layer.cornerRadius = 80 / 2
        
        containerView.addSubview(changeButton)
        changeButton.anchor(top: profileImageView.bottomAnchor, left: nil, bottom: nil, right: nil, paddingTop: 8, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, widht: 0, height: 0)
        changeButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
        
        containerView.addSubview(separatorView)
        separatorView.anchor(top: nil, left: containerView.leftAnchor, bottom: containerView.bottomAnchor, right: containerView.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, widht: 0, height: 0.5)
        
        view.addSubview(fullnameLabel)
        fullnameLabel.anchor(top: containerView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: nil, paddingTop: 20, paddingLeft: 12, paddingBottom: 0, paddingRight: 0, widht: 0, height: 0)
        
        view.addSubview(usernameLabel)
        usernameLabel.anchor(top: fullnameLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: nil, paddingTop: 20, paddingLeft: 12, paddingBottom: 0, paddingRight: 0, widht: 0, height: 0)
        
        view.addSubview(fullnameTextField)
        fullnameTextField.anchor(top: containerView.bottomAnchor, left: fullnameLabel.rightAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 16, paddingLeft: 12, paddingBottom: 0, paddingRight: 12, widht: (view.frame.width / 1.6), height: 0)
        
        view.addSubview(usernameTextField)
        usernameTextField.anchor(top: fullnameTextField.bottomAnchor, left: usernameLabel.rightAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 16, paddingLeft: 12, paddingBottom: 0, paddingRight: 12, widht: (view.frame.width / 1.6), height: 0)
        
        view.addSubview(fullnameSeparatorView)
        fullnameSeparatorView.anchor(top: nil, left: fullnameTextField.leftAnchor, bottom: fullnameTextField.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: -8, paddingRight: 12, widht: 0, height: 0.5)
        
        view.addSubview(usernameSeparatorView)
        usernameSeparatorView.anchor(top: nil, left: usernameTextField.leftAnchor, bottom: usernameTextField.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: -8, paddingRight: 12, widht: 0, height: 0.5)
    }
    
    @objc func handleChageProfilePhoto() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true
        present(imagePickerController, animated: true, completion: nil)
    }
    
    @objc func handleCancel() {
        self.dismiss(animated: true)
    }
    
    @objc func handleDone() {
        view.endEditing(true)
        
        if usernameChaged {
            updateUserName()
        }
        
        if imageChanged {
            updateProfileImage()
        }
    }
    
    func loadUserData() {
        guard let user = self.user else { return }
        
        profileImageView.loadImage(with: user.profileImageUrl)
        fullnameTextField.text = user.name
        usernameTextField.text = user.username
    }
    
    // MARK: - API
    
    func updateUserName() {
        guard let updateUsername = self.updateUsername else { return }
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        guard usernameChaged == true else { return }
        
        USER_REF.child(currentUid).child("username").setValue(updateUsername) { (error, ref) in
            guard let userProfileController = self.userProfileController else { return }
            userProfileController.fetchCurrentUserData()
            
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func updateProfileImage() {
        guard imageChanged == true else { return }
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        guard let user = self.user else { return }

        Storage.storage().reference(forURL: user.profileImageUrl).delete(completion: nil)

        let filename = NSUUID().uuidString
        
        guard let updateProfileImage = profileImageView.image else { return }
        guard let imageData = updateProfileImage.jpegData(compressionQuality: 0.3) else { return }
        
        STORAGE_PROFILE_IMAGES_REF.child(filename).putData(imageData) { (metadata, err) in
            if let err = err {
                print(err.localizedDescription)
            }
            
            STORAGE_PROFILE_IMAGES_REF.child(filename).downloadURL { (url, err) in
                USER_REF.child(currentUid).child("profileImageUrl").setValue(url?.absoluteString) { (err, ref) in
                    guard let userProfileController = self.userProfileController else { return }
                    userProfileController.fetchCurrentUserData()
                    
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }
    }
}


extension EditProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[.editedImage] as? UIImage {
            profileImageView.image = selectedImage
            self.imageChanged = true
        }
        dismiss(animated: true)
    }
}

extension EditProfileViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let user = self.user else { return }
        
        let trimmedString = usernameTextField.text?.replacingOccurrences(of: "\\s+$", with: "", options: .regularExpression)
        
        guard user.username != trimmedString else {
            print("not chagne")
            usernameChaged = false
            return
        }
        
        guard trimmedString != "" else {
            print("trim")
            usernameChaged = false
            return
        }
        
        updateUsername = trimmedString?.lowercased()
        usernameChaged = true
    }
}
