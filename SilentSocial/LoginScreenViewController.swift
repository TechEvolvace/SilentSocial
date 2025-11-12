//  Project: SilentSocial
//  Names: Phuc Dinh, Nicholas Ng, Preston Tu, Rui Xue
//  Course: CS329E
//  LoginScreenViewController.swift
//  SilentSocial
//
//  Created by Nicholas Gia-Bao Ng on 10/14/25.
//

import UIKit
// Import for login functionalities
import FirebaseAuth

class LoginScreenViewController: UIViewController, UITextFieldDelegate {
    // Initial Screen that pops up for login
    
    // Define outlets
    @IBOutlet weak var userLoginTextField: UITextField!
    @IBOutlet weak var passwordLoginTextField: UITextField!
    @IBOutlet weak var loginLogo: UIImageView!
    @IBOutlet weak var errorLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set Various Label text to nothing
        userLoginTextField.text = ""
        passwordLoginTextField.text = ""
        errorLabel.text = ""
        // Make sure password textfield is secure
        passwordLoginTextField.isSecureTextEntry = true
        
        // Load logo from asets library
        if let logoImage = UIImage(named: "SilentSocialLogo") {
            loginLogo.image = logoImage
        }
        
        // Set up to let keyboard dismiss work
        userLoginTextField.delegate = self
        passwordLoginTextField.delegate = self
        
        Auth.auth().addStateDidChangeListener() { (auth, user) in
            // Remove login fields upon login
            if user != nil {
                self.presentMainTabs()
                self.userLoginTextField.text = nil
                self.passwordLoginTextField.text = nil
            }
        }
        
    }
    
    @IBAction func loginButtonPressed(_ sender: Any) {
        // When pressing the login button - tries to login user
        Auth.auth().signIn(withEmail: userLoginTextField.text!, password: passwordLoginTextField.text!) { (result, error) in
            if let error = error as NSError? {
                self.errorLabel.text = "Error:  \(error.localizedDescription)"
            } else {
                self.errorLabel.text = ""
            }
        }
    }

    // The following functions are to dismss the keyboard
    // Called when 'return' key pressed
    func textFieldShouldReturn(_ textField:UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    // Called when the user clicks on the view outside of the UITextField
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    

}

extension LoginScreenViewController {
    private func presentMainTabs() {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        guard let home = sb.instantiateViewController(withIdentifier: "DashboardViewController") as? DashboardViewController,
              let profile = sb.instantiateViewController(withIdentifier: "ProfileViewController") as? ProfileViewController,
              let settings = sb.instantiateViewController(withIdentifier: "SettingsTableViewController") as? SettingsTableViewController
        else {
            return
        }

        home.title = "Home"
        profile.title = "Profile"
        settings.title = "Setting"

        let homeNav = UINavigationController(rootViewController: home)
        let profileNav = UINavigationController(rootViewController: profile)
        let settingsNav = UINavigationController(rootViewController: settings)

        homeNav.tabBarItem = UITabBarItem(title: "Home", image: UIImage(systemName: "house"), selectedImage: UIImage(systemName: "house.fill"))
        profileNav.tabBarItem = UITabBarItem(title: "Profile", image: UIImage(systemName: "person"), selectedImage: UIImage(systemName: "person.fill"))
        settingsNav.tabBarItem = UITabBarItem(title: "Setting", image: UIImage(systemName: "gearshape"), selectedImage: UIImage(systemName: "gearshape.fill"))

        let tabs = UITabBarController()
        tabs.viewControllers = [homeNav, profileNav, settingsNav]
        tabs.modalPresentationStyle = .fullScreen
        present(tabs, animated: true)
    }
}
