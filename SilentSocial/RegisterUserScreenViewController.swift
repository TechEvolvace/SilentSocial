//  Project: SilentSocial
//  Names: Phuc Dinh, Nicholas Ng, Preston Tu, Rui Xue
//  Course: CS329E
//  RegisterUserScreenViewController.swift
//  SilentSocial
//
//  Created by Nicholas Gia-Bao Ng on 10/14/25.
//

import UIKit
import FirebaseAuth

class RegisterUserScreenViewController: UIViewController, UITextFieldDelegate {

    // Define various outlets
    @IBOutlet weak var registerLogoImage: UIImageView!
    @IBOutlet weak var userRegisterField: UITextField!
    @IBOutlet weak var passwordRegisterField: UITextField!
    @IBOutlet weak var passwordConfirmField: UITextField!
    @IBOutlet weak var registerErrorLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set Various Label text to nothing
        userRegisterField.text = ""
        passwordRegisterField.text = ""
        passwordConfirmField.text = ""
        registerErrorLabel.text = ""
        
        // Make sure password and confirmation textfield is secure
        passwordRegisterField.isSecureTextEntry = true
        passwordConfirmField.isSecureTextEntry = true

        
        // Load logo from asets library
        if let logoImage = UIImage(named: "SilentSocialLogo") {
            registerLogoImage.image = logoImage
        }
        
        // Set up to let keyboard dismiss work
        userRegisterField.delegate = self
        passwordRegisterField.delegate = self
        passwordConfirmField.delegate = self
        
        Auth.auth().addStateDidChangeListener() { (auth, user) in
            // Remove registration fields upon registration
            if user != nil {
                // Segue to dashboard page if login is successful
                self.performSegue(withIdentifier: "registerSegue", sender: nil)
                self.userRegisterField.text = nil
                self.passwordRegisterField.text = nil
                self.passwordConfirmField.text = nil
            }
        }
    }
    
    @IBAction func createAccountPressed(_ sender: Any) {
        // Try to make account when create account button is pressed
        if passwordRegisterField.text == passwordConfirmField.text {
            // Make sure that the password and confirmation are the same
            // create a new user here
            Auth.auth().createUser(withEmail: userRegisterField.text!, password: passwordRegisterField.text!) { (result, error) in
                if let error = error as NSError? {
                    self.registerErrorLabel.text = "Error \(error.localizedDescription)"
                } else {
                    self.registerErrorLabel.text = ""
                }
                if error == nil {
                    // Sign user in right away if there is a valid registration
                    Auth.auth().signIn(withEmail: self.userRegisterField.text!,password: self.passwordRegisterField.text!)
                }
            }
        } else {
            // Set an error message and return
            registerErrorLabel.text = "Password confirmation and password does not match."
        }
    }
    
    @IBAction func returnLoginPress(_ sender: Any) {
        // Return to login screen without another popup
        self.dismiss(animated: true)
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
