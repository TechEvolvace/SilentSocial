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
// Import for access to usernames
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
                // Segue to dashboard page if login is successful
                self.performSegue(withIdentifier: "loginSegue", sender: nil)
                self.userLoginTextField.text = nil
                self.passwordLoginTextField.text = nil
            }
        }
        
    }
    
    @IBAction func loginButtonPressed(_ sender: Any) {
            // When pressing the login button - tries to login user
            
            if let loginInput = userLoginTextField.text, let password = passwordLoginTextField.text {
                // If fields are empty return an error label message
                if loginInput.isEmpty || password.isEmpty {
                    self.errorLabel.text = "Please enter both login and password."
                    return
                }
                // Function to handle the final Firebase Sign-In result
                let handleSignInResult: (AuthDataResult?, Error?) -> Void = { [weak self] (result, error) in
                    if let self = self {
                        if let error = error as NSError? {
                            self.errorLabel.text = "Login Error: \(error.localizedDescription)"
                        } else {
                            self.errorLabel.text = ""
                            // Success handled in the view load with the listener I think
                        }
                    }
                }
                
                // Check if username or email with checking the @
                if loginInput.contains("@") {
                    // Input is email, sign-in with normal auth function
                    Auth.auth().signIn(withEmail: loginInput, password: password, completion: handleSignInResult)
                    
                } else {
                    // Looking up email in firestore based on username
                    self.db.collection(self.usersCollection)
                      .whereField("username", isEqualTo: loginInput)
                      .limit(to: 1) // Only need one result
                      .getDocuments { [weak self] (querySnapshot, error) in
                        
                        if let self = self {
                            if let error = error {
                                // Check failed due to network probably
                                self.errorLabel.text = "Network Error: Could not verify username."
                                print("Error checking username: \(error.localizedDescription)")
                                return
                            }
                            
                            // Check for document and username
                            if let document = querySnapshot?.documents.first {
                                //  Extract email
                                let data = document.data()
                                if let email = data["email"] as? String {
                                    // Attempt the final sign-in with the retrieved email
                                    Auth.auth().signIn(withEmail: email, password: password, completion: handleSignInResult)
                                } else {
                                    // If failed here then somehow missing email field - not sure how this would happen
                                    self.errorLabel.text = "Account data missing email field."
                                }
                            } else {
                                // No document found with that username
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
