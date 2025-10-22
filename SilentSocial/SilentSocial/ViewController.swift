//  Project: SilentSocial
//  Names: Phuc Dinh, Nicholas Ng, Preston Tu, Rui Xue
//  Course: CS329E
//  ViewController.swift
//  SilentSocial
//
//  Created by Nicholas Gia-Bao Ng on 10/14/25.
//

import UIKit
import FirebaseAuth

class ViewController: UIViewController {
    // THIS IS THE MAIN VIEW CONTROLLER AFTER LOGGING IN/REGISTERING
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func logOutButton(_ sender: UIButton) {
        // for testing DELETE LATER
        do { // this is just generated stuff it gAVe me a heAdache and i needed a test
                try Auth.auth().signOut()
                print("User successfully signed out.")
                
                // 2. Safely get a reference to the main window
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let sceneDelegate = windowScene.delegate as? SceneDelegate else {
                    print("Error: Could not access SceneDelegate.")
                    return
                }
                
                // 3. Instantiate the initial Authentication View Controller
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                
                // **IMPORTANT:** Replace "LoginNavController" with the actual Storyboard ID
                // of your initial Login/Registration view controller (or its Navigation Controller).
                guard let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginNavController") as? UIViewController else {
                    print("Error: Could not instantiate Login View Controller from Storyboard.")
                    return
                }

                // 4. Set the new view controller as the root view controller
                // This is the key step that dismisses the entire main app UI.
                sceneDelegate.window?.rootViewController = loginVC
                
                // Use a transition animation for a smoother user experience
                UIView.transition(with: sceneDelegate.window!, duration: 0.3, options: .transitionCrossDissolve, animations: nil, completion: nil)
                
                sceneDelegate.window?.makeKeyAndVisible()
                
            } catch let signOutError as NSError {
                print("Error signing out: \(signOutError.localizedDescription)")
            }
    }
    
}

