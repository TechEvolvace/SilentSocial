//  Project: SilentSocial
//  Names: Phuc Dinh, Nicholas Ng, Preston Tu, Rui Xue
//  Course: CS329E
//  ProfileSetupViewController.swift

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class ProfileSetupViewController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // Firebase properties
    let db = Firestore.firestore()
    let usersCollection = "users"
    let storage = Storage.storage() // Added storage reference
    
    // Define outlets
    @IBOutlet weak var usernameSetTextField: UITextField!
    @IBOutlet weak var displayNameSetTextField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var uploadImageButton: UIButton!
    
    // Variables
    var currentUser: User?
    var selectedProfileImage: UIImage?
    private var uiConfigured = false
    
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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !uiConfigured {
            configureUI()
            uiConfigured = true
        }
    }
    
    private func configureUI() {
        profileImageView.layer.cornerRadius = profileImageView.frame.width / 2
        profileImageView.clipsToBounds = true
    }
    
    @IBAction func uploadImageButtonPressed(_ sender: Any) {
        presentImagePicker()
    }
    
    @IBAction func continueButtonPressed(_ sender: Any) {
        // Extract text field values while stripping white space
        guard let username = usernameSetTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
              let displayName = displayNameSetTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            errorLabel.text = "Authentication error. Please restart application."
            return
        }
        
        if username.isEmpty || displayName.isEmpty {
            errorLabel.text = "Please enter both a username and a display name"
            return
        }

        handleContinueAction(username: username, displayName: displayName)
    }

    // MARK: - Orchestration and Firebase Storage
    
    func handleContinueAction(username: String, displayName: String) {
        self.errorLabel.text = ""
        
        if let image = self.selectedProfileImage {
            self.uploadImageAndContinue(image: image, username: username, displayName: displayName)
        } else {
            self.saveUserDataToFirestore(username: username, displayName: displayName, photoURL: nil)
        }
    }
    
    func uploadImageAndContinue(image: UIImage, username: String, displayName: String) {
        self.errorLabel.text = "Uploading profile picture..."

        uploadImageToFirebaseStorage(image: image) { [weak self] photoURLString in
            guard let self = self else { return }
            
            if let urlString = photoURLString,
               let user = self.currentUser,
               let photoURL = URL(string: urlString) {
                
                let changeRequest = user.createProfileChangeRequest()
                changeRequest.photoURL = photoURL
                changeRequest.commitChanges { error in
                    if let error = error {
                        print("Auth PhotoURL Update Error: \(error.localizedDescription)")
                    }
                    self.saveUserDataToFirestore(username: username, displayName: displayName, photoURL: urlString)
                }
            } else {
                self.errorLabel.text = "Error uploading image. Proceeding without picture."
                self.saveUserDataToFirestore(username: username, displayName: displayName, photoURL: nil)
            }
        }
    }
    
    func uploadImageToFirebaseStorage(image: UIImage, completion: @escaping (String?) -> Void) {
        guard let user = currentUser else {
            completion(nil)
            return
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(nil)
            return
        }
        
        let storageRef = storage.reference().child("users/\(user.uid)/profile_pic.jpg")
        
        storageRef.putData(imageData, metadata: nil) { metadata, error in
            guard metadata != nil else {
                print("Firebase Storage Upload Error: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }
            
            storageRef.downloadURL { url, error in
                guard let downloadURL = url else {
                    print("Firebase Storage URL Retrieval Error: \(error?.localizedDescription ?? "Unknown error")")
                    completion(nil)
                    return
                }
                completion(downloadURL.absoluteString)
            }
        }
    }
    
    func saveUserDataToFirestore(username: String, displayName: String, photoURL: String?) {
        guard let user = currentUser else {
            errorLabel.text = "Authentication error. Please restart application."
            return
        }
        
        // Check for duplicate usernames
        db.collection(usersCollection).whereField("username", isEqualTo: username).getDocuments { [weak self] (querySnapshot, error) in
            guard let self = self else { return }
            
            if let error = error {
                self.errorLabel.text = "Network error checking username. Please try again."
                return
            }
            
            let isAvailable = querySnapshot?.documents.isEmpty ?? true
            
            if isAvailable {
                let userRef = self.db.collection(self.usersCollection).document(user.uid)
                
                var userData: [String: Any] = [
                    "username": username,
                    "displayName": displayName,
                    "email": user.email ?? "",
                    "createdAt": FieldValue.serverTimestamp()
                ]
                
                // Include the photo URL if available
                if let url = photoURL {
                    userData["photoURL"] = url
                }
                
                userRef.setData(userData) { error in
                    if let error = error {
                        self.errorLabel.text = "Failed to create profile: \(error.localizedDescription)"
                    } else {
                        // Profile created and transition to the main app
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let sceneDelegate = windowScene.delegate as? SceneDelegate {
                            let storyboard = UIStoryboard(name: "Main", bundle: nil)
                            let mainAppVC = storyboard.instantiateViewController(withIdentifier: "DashboardViewController")
                            sceneDelegate.window?.rootViewController = mainAppVC
                            sceneDelegate.window?.makeKeyAndVisible()
                        }
                    }
                }
            } else {
                self.errorLabel.text = "The username you entered is already taken. Please choose another one."
            }
        }
    }

    // MARK: - Delegate Methods
    
    // Called when 'return' key pressed
    func textFieldShouldReturn(_ textField:UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // Called when the user clicks on the view outside of the UITextField
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }

    // MARK: - Image Picker Implementation
    
    @objc func presentImagePicker() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        
        let alert = UIAlertController(title: "Choose Profile Picture Source", message: nil, preferredStyle: .actionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction(title: "Camera", style: .default) { _ in
                picker.sourceType = .camera
                self.present(picker, animated: true)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Photo Library", style: .default) { _ in
            picker.sourceType = .photoLibrary
            self.present(picker, animated: true)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        self.present(alert, animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let editedImage = info[.editedImage] as? UIImage {
            self.selectedProfileImage = editedImage
        } else if let originalImage = info[.originalImage] as? UIImage {
            self.selectedProfileImage = originalImage
        }
        
        self.profileImageView.image = self.selectedProfileImage
        
        picker.dismiss(animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
