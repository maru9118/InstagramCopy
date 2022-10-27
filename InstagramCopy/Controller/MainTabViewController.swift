//
//  MainTabViewController.swift
//  InstagramCopy
//
//  Created by jonghoKim on 2022/06/28.
//

import UIKit
import Firebase

class MainTabViewController: UITabBarController, UITabBarControllerDelegate {
    
    let dot = UIView()
    var notificationIDs = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.delegate = self
        configureViewControllers()
        
        configureNotificationDot()
        
        observeNotifications()
        
        checkIfUsersIsLoggedIn()
    }
    
    func configureViewControllers() {
        guard
            let homeUnselected: UIImage = UIImage(named: "home_unselected.png"),
            let homeSeletedImage = UIImage(named: "home_selected.png"),
            
            let searchUnselected = UIImage(named: "search_unselected.png"),
            let searchSelected = UIImage(named: "search_selected.png"),
            
            let uploadUnselected = UIImage(named: "plus_unselected.png"),
            let uploadSelected = UIImage(named: "plus_unselected.png"),
            
            let notificationUnselected = UIImage(named: "like_unselected.png"),
            let notificationSelected = UIImage(named: "like_selected.png"),
            
            let profileUnselected = UIImage(named: "profile_unselected.png"),
            let profileSelected = UIImage(named: "profile_selected.png")
        else { return }
        
        let feedVC = constructNavControllers(unseletedImage: homeUnselected, seletedImage: homeSeletedImage, rootViewController: FeedViewController(collectionViewLayout: UICollectionViewFlowLayout()))

        let searchVC = constructNavControllers(unseletedImage: searchUnselected, seletedImage: searchSelected, rootViewController: SearchViewController())
        
        let selectImageVC = constructNavControllers(unseletedImage: uploadUnselected, seletedImage: uploadSelected)
        
        let notificationVC = constructNavControllers(unseletedImage: notificationUnselected, seletedImage: notificationSelected, rootViewController: NotificationViewController())
        
        let profileVC = constructNavControllers(unseletedImage: profileUnselected, seletedImage: profileSelected, rootViewController: UserProfileViewController(collectionViewLayout: UICollectionViewFlowLayout()))
        
        viewControllers = [feedVC, searchVC, selectImageVC, notificationVC, profileVC]
        tabBar.tintColor = .black
    }
    
    func constructNavControllers(unseletedImage: UIImage, seletedImage: UIImage, rootViewController: UIViewController = UIViewController()) -> UINavigationController {
        let navController = UINavigationController(rootViewController: rootViewController)
        navController.tabBarItem.image = unseletedImage
        navController.tabBarItem.selectedImage = seletedImage
        navController.navigationBar.tintColor = .black
        
        return navController
    }
    
    func configureNotificationDot() {
        let tabBarHeight = tabBar.frame.height
        
        if UIDevice().userInterfaceIdiom == .phone {
            if UIScreen.main.nativeBounds.height == 2436 {
                dot.frame = CGRect(x: view.frame.width / 5 * 3, y: view.frame.height - tabBarHeight, width: 6, height: 6)
            } else {
                dot.frame = CGRect(x: view.frame.width / 5 * 3, y: view.frame.height - 16, width: 6, height: 6)
            }
            
            dot.center.x = (view.frame.width / 5 * 3 + (view.frame.width / 5) / 2)
            dot.backgroundColor = UIColor(red: 233/255, green: 30/255, blue: 99/255, alpha: 1)
            dot.layer.cornerRadius = dot.frame.width / 2
            self.view.addSubview(dot)
            dot.isHidden = true
        }
    }
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        
        let index = viewControllers?.firstIndex(of: viewController)
        
        if index == 2 {
            let selectImageVC = SelectImageViewController(collectionViewLayout: UICollectionViewFlowLayout())
            let navController = UINavigationController(rootViewController: selectImageVC)
            navController.navigationBar.tintColor = .black
            
            present(navController, animated: true, completion: nil)
            
            return false
        } else if index == 3 {
            dot.isHidden = true
            return true
        }
        return true
    }
    
    func checkIfUsersIsLoggedIn() {
        if Auth.auth().currentUser == nil {
            let loginVC = LoginViewController()
            let navController = UINavigationController(rootViewController: loginVC)
            self.present(navController, animated: true, completion: nil)
        }
        return
    }
    
    func observeNotifications() {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        self.notificationIDs.removeAll()
        
        NOTIFICATION_REF.child(currentUid).observeSingleEvent(of: .value) { (snapshot) in
            guard let allObject = snapshot.children.allObjects as? [DataSnapshot] else { return }
            
            allObject.forEach { (snapshot) in
                let notificationId = snapshot.key
                
                NOTIFICATION_REF.child(currentUid).child(notificationId).child("checked").observeSingleEvent(of: .value) { (snapshot) in
                    guard let checked = snapshot.value as? Int else { return }
                    
                    if checked == 0 {
                        self.dot.isHidden = false
                    } else {
                        self.dot.isHidden = true
                    }
                }
            }
        }
    }
}
