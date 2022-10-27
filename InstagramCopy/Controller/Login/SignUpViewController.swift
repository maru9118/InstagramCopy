//
//  SignUpViewController.swift
//  InstagramCopy
//
//  Created by jonghoKim on 2022/06/25.
//

import UIKit
import Firebase
import FirebaseMessaging

class SignUpViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var imageSelected = false

    let plusButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "plus_photo.png")?.withRenderingMode(.alwaysOriginal ), for: .normal)
        button.addTarget(self, action: #selector(handleSelectProfilePhoto), for: .touchUpInside)
        return button
    }()
    
    let emailTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Email"
        tf.backgroundColor = UIColor(white: 0, alpha: 0.03)
        tf.borderStyle = .roundedRect
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.addTarget(self, action: #selector(fromValidation), for: .editingChanged)
        return tf
    }()
    
    let passwordTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Password"
        tf.backgroundColor = UIColor(white: 0, alpha: 0.03)
        tf.borderStyle = .roundedRect
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.isSecureTextEntry = true
        tf.addTarget(self, action: #selector(fromValidation), for: .editingChanged)
        return tf
    }()
    
    let fullNameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Full Name"
        tf.backgroundColor = UIColor(white: 0, alpha: 0.03)
        tf.borderStyle = .roundedRect
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.addTarget(self, action: #selector(fromValidation), for: .editingChanged)
        return tf
    }()
    
    let userNameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "User Name"
        tf.backgroundColor = UIColor(white: 0, alpha: 0.03)
        tf.borderStyle = .roundedRect
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.addTarget(self, action: #selector(fromValidation), for: .editingChanged)
        return tf
    }()
    
    let signUpButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign Up", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(red: 149/255, green: 204/255, blue: 244/255, alpha: 1)
        button.layer.cornerRadius = 5
        button.isEnabled = false
        button.addTarget(self, action: #selector(handleSignUp), for: .touchUpInside)
        return button
    }()
    
    let alreadyHaveAccoutButton: UIButton = {
        let button = UIButton(type: .system)
        
        let attributedTitle = NSMutableAttributedString(string: "Already have an account?  ", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        attributedTitle.append(NSAttributedString(string: "Sign Up", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14), NSAttributedString.Key.foregroundColor: UIColor(red: 17/255, green: 154/255, blue: 237/255, alpha: 1)]))

        button.addTarget(self, action: #selector(handleShowLogin), for: .touchUpInside)
        button.setAttributedTitle(attributedTitle, for: .normal)
        
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        view.addSubview(plusButton)
        plusButton.anchor(top: nil, left: nil, bottom: nil, right: nil, paddingTop: 40, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, widht: 140, height: 140)
        plusButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        configureUI()
        
        view.addSubview(alreadyHaveAccoutButton)
        alreadyHaveAccoutButton.anchor(top: nil, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, widht: 0, height: 50)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let profileImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else {
            imageSelected = false
            return
        }
        
        imageSelected = true
        
        plusButton.layer.cornerRadius = plusButton.frame.width / 2
        plusButton.layer.masksToBounds = true
        plusButton.layer.borderColor = UIColor.black.cgColor
        plusButton.layer.borderWidth = 2
        plusButton.setImage(profileImage.withRenderingMode(.alwaysOriginal), for: .normal)
        
        print(imageSelected)
        
        self.dismiss(animated: true, completion: nil)
    }
    
    func configureUI() {
        let stackView = UIStackView(arrangedSubviews: [emailTextField, fullNameTextField, userNameTextField, passwordTextField, signUpButton])
        
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.distribution = .fillEqually
        
        view.addSubview(stackView)
        stackView.anchor(top: plusButton.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 24, paddingLeft: 40, paddingBottom: 0, paddingRight: 40, widht: 0, height: 240)
    }
    
    @objc func handleSelectProfilePhoto() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    @objc func fromValidation() {
        guard emailTextField.hasText,
        passwordTextField.hasText,
        fullNameTextField.hasText,
        userNameTextField.hasText,
        imageSelected == true
        else {
            signUpButton.isEnabled = false
            signUpButton.backgroundColor = UIColor(red: 149/255, green: 204/255, blue: 244/255, alpha: 1)
            return
        }
        
        signUpButton.isEnabled = true
        signUpButton.backgroundColor = UIColor(red: 17/255, green: 154/255, blue: 237/255, alpha: 1)
    }
    
    @objc func handleShowLogin() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc func handleSignUp() {
        guard let email = emailTextField.text else { return }
        guard let password = passwordTextField.text else { return }
        guard let fullName = fullNameTextField.text else { return }
        guard let userName = userNameTextField.text?.lowercased() else { return }
        
        Auth.auth().createUser(withEmail: email, password: password) { (user, error) in
            if let error = error {
                print("아이디 생성이 실패", error.localizedDescription)
                return
            }
            
            guard let profileImage = self.plusButton.imageView?.image else { return }
            guard let uploadData = profileImage.jpegData(compressionQuality: 0.3) else { return }
            
            let fileName = NSUUID().uuidString
            
            let storageRef = Storage.storage().reference().child("profile_image").child(fileName)
            
            storageRef.putData(uploadData, metadata: nil) { (metadata, error) in
                if let error = error {
                    print("failed upload image", error.localizedDescription)
                    return
                }
                
                storageRef.downloadURL { (downloadUrl, error) in
                    guard let profileImageUrl = downloadUrl?.absoluteString else {
                        print("profile image url nil")
                        return
                    }
                    
                    guard let uid = user?.user.uid else { return }
                    guard let fcmToken = Messaging.messaging().fcmToken else { return }
                    
                    let dictionaryValueds = ["name": fullName,
                                             "fcmToken": fcmToken,
                                             "username": userName,
                                             "profileImageUrl":profileImageUrl]
                    
                    let values = [uid: dictionaryValueds]
                    
                    Database.database(url: "https://instagramcopy-70004-default-rtdb.asia-southeast1.firebasedatabase.app").reference().child("users").updateChildValues(values) { (error, ref) in
                        
                        guard let mainTabVC = UIApplication.shared.keyWindow?.rootViewController as? MainTabViewController else { return }
                        
                        mainTabVC.configureViewControllers()
                        self.dismiss(animated: true, completion: nil)
                    }
                }
            }
            print("아이디 생성")
        }
    }
}
