//  Project: SilentSocial
//  Names: Phuc Dinh, Nicholas Ng, Preston Tu, Rui Xue
//  Course: CS329E
//  ProfileSetupViewController.swift

import UIKit
import FirebaseAuth
import FirebaseFirestore

class ProfileSetupViewController: UIViewController, UITextFieldDelegate {

    // Firebase properties
    let db = Firestore.firestore()
    let usersCollection = "users"
    
    // Define outlets
    @IBOutlet weak var usernameSetTextField: UITextField!
    @IBOutlet weak var displayNameSetTextField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    
    // Variables
    var currentUser: User?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set placeholders for textfields
        usernameSetTextField.placeholder = "Unique Username (e.g., JohnD_444)"
        displayNameSetTextField.placeholder = "Display name (e.g., John Doe)"

        // Set up to let keyboard dismiss work
        usernameSetTextField.delegate = self
        displayNameSetTextField.delegate = self
        
        // Set error label to nothing
        errorLabel.text = ""
        
        // Save the current user as a variable
        currentUser = Auth.auth().currentUser
    }
    
    @IBAction func continueButtonPressed(_ sender: Any) {
        // Upon continue button being pressed
        // Extract text field values while stripping white space
        if let user = currentUser,
           let username = usernameSetTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), let displayName = displayNameSetTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) {
            
            if username.isEmpty || displayName.isEmpty {
                // Check to make sure both fields are filled
                errorLabel.text = "Please enter both a username and a display name"
                // End function
                return
            }
            
            // Check for duplicate usernames
            db.collection(usersCollection).whereField("username", isEqualTo: username).getDocuments { [weak self] (querySnapshot, error) in
                if let self = self {
                    if error != nil {
                        errorLabel.text = "Network error checking username. Please try again."
                        return
                    }
                    // Check if username is available - ?? true defaults to expression to true if result is null
                    let isAvailable = querySnapshot?.documents.isEmpty ?? true
                    
                    if isAvailable {
                        // Reference for specific
                        let userRef = self.db.collection(self.usersCollection).document(user.uid)
                        
                        // Make a new document with the fields
                        let userData: [String: Any] = [
                            "username": username,
                            "displayName": displayName,
                            "email": user.email ?? "",
                            "createdAt": FieldValue.serverTimestamp() // Timestamp
                            // Add profile picture field later when existing
                        ]
                        
                        // Set the data
                        userRef.setData(userData) { [weak self] error in
                            if let self = self {
                                if let error = error {
                                    errorLabel.text = "Failed to create profile: \(error.localizedDescription)"
                                } else {
                                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                       let sceneDelegate = windowScene.delegate as? SceneDelegate {
                                        let sb = UIStoryboard(name: "Main", bundle: nil)
                                        if let home = sb.instantiateViewController(withIdentifier: "DashboardViewController") as? DashboardViewController {
                                            let profile = PostsProfileViewController()
                                            home.title = "Home"
                                            profile.title = "Profile"
                                            let homeNav = UINavigationController(rootViewController: home)
                                            let profileNav = UINavigationController(rootViewController: profile)
                                            homeNav.tabBarItem = UITabBarItem(title: "Home", image: UIImage(systemName: "house"), selectedImage: UIImage(systemName: "house.fill"))
                                            profileNav.tabBarItem = UITabBarItem(title: "Profile", image: UIImage(systemName: "person"), selectedImage: UIImage(systemName: "person.fill"))
                                            let tabs = UITabBarController()
                                            tabs.viewControllers = [homeNav, profileNav]
                                            sceneDelegate.window?.rootViewController = tabs
                                            sceneDelegate.window?.makeKeyAndVisible()
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                } else {
                    // Reaching here means the username is taken
                    self?.errorLabel.text = "The username you entered is already taken. Please choose another one."
                    return
                }
            }
        } else {
            // If above statement fails probably weird things happened with authentication
            errorLabel.text = "Authentication error. Please restart application."
            return
        }
    }
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
