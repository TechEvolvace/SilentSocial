//  Project: SilentSocial
//  Names: Phuc Dinh, Nicholas Ng, Preston Tu, Rui Xue
//  Course: CS329E
//  LoginScreenViewController.swift

import UIKit
// Import for login functionalities
import FirebaseAuth
import FirebaseFirestore

class LoginScreenViewController: UIViewController, UITextFieldDelegate {
    // Initial Screen that pops up for login
    
    // Firestore setup
    let db = Firestore.firestore()
    let usersCollection = "users"
    
    // Define outlets
    @IBOutlet weak var userLoginTextField: UITextField!
    @IBOutlet weak var passwordLoginTextField: UITextField!
    @IBOutlet weak var loginLogo: UIImageView!
    @IBOutlet weak var errorLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Check if a user is already authenticated and immediately switch to the main app
        if Auth.auth().currentUser != nil {
            setRootToMainTabs()
        }
        
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
    }
    
    @IBAction func loginButtonPressed(_ sender: Any) {
        
        if let loginInput = userLoginTextField.text, let password = passwordLoginTextField.text {
            
            if loginInput.isEmpty || password.isEmpty {
                self.errorLabel.text = "Please enter both login and password."
                return
            }
            
            // Function to handle the final Firebase Sign-In result
            let handleSignInResult: (AuthDataResult?, Error?) -> Void = { [weak self] (result, error) in
                if let self = self {
                    if let error = error as NSError? {
                        // FAILURE: Show error
                        self.errorLabel.text = "Login Error: \(error.localizedDescription)"
                    } else {
                        // SUCCESS!
                        self.errorLabel.text = ""
                        
                        self.setRootToMainTabs()
                        
                        // Clear the fields after a successful login
                        self.userLoginTextField.text = nil
                        self.passwordLoginTextField.text = nil
                    }
                }
            }
            
            // Check if input is email or username
            if loginInput.contains("@") {
                // Input is email, sign-in with normal auth function
                Auth.auth().signIn(withEmail: loginInput, password: password, completion: handleSignInResult)
                
            } else {
                // Looking up email in firestore based on username
                self.db.collection(self.usersCollection)
                    .whereField("username", isEqualTo: loginInput.lowercased())
                    .limit(to: 1)
                    .getDocuments { [weak self] (querySnapshot, error) in
                        
                        if let self = self {
                            
                            if let error = error {
                                self.errorLabel.text = "Network Error: Could not verify username."
                                print("Error checking username: \(error.localizedDescription)")
                                return
                            }
                            
                            if let document = querySnapshot?.documents.first {
                                let data = document.data()
                                if let email = data["email"] as? String {
                                    // Attempt the final sign-in with the retrieved email
                                    Auth.auth().signIn(withEmail: email, password: password, completion: handleSignInResult)
                                } else {
                                    self.errorLabel.text = "Account data missing email field."
                                }
                            } else {
                                self.errorLabel.text = "User not found. Check username or email."
                                return
                            }
                        }
                    }
            }
            
        } else {
            self.errorLabel.text = "Please enter both login and password."
            return
        }
    }
    
    // MARK: - Keyboard Delegate
    
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
    private func setRootToMainTabs() {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        guard let home = sb.instantiateViewController(withIdentifier: "DashboardViewController") as? DashboardViewController
        else { return }
        let profile = PostsProfileViewController()
        home.title = "Home"
        profile.title = "Profile"
        let homeNav = UINavigationController(rootViewController: home)
        let profileNav = UINavigationController(rootViewController: profile)
        homeNav.tabBarItem = UITabBarItem(title: "Home", image: UIImage(systemName: "house"), selectedImage: UIImage(systemName: "house.fill"))
        profileNav.tabBarItem = UITabBarItem(title: "Profile", image: UIImage(systemName: "person"), selectedImage: UIImage(systemName: "person.fill"))
        let tabs = UITabBarController()
        tabs.viewControllers = [homeNav, profileNav]
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let sceneDelegate = windowScene.delegate as? SceneDelegate {
            sceneDelegate.window?.rootViewController = tabs
            sceneDelegate.window?.makeKeyAndVisible()
        }
    }
}
