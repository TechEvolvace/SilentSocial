// Project: SilentSocial
// Names: Phuc Dinh, Nicholas Ng, Preston Tu, Rui Xue
// Course: CS329E
// ProfileSetupViewController.swift

import UIKit
import FirebaseAuth
import FirebaseFirestore
import CoreLocation

class ProfileSetupViewController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CLLocationManagerDelegate {
    
    // Firebase properties
    let db = Firestore.firestore()
    let usersCollection = "users"
    
    // Location properties
    private let locationManager = CLLocationManager()
    private var geocoder = CLGeocoder()
    private var regionCode: String = "US" // Default to US if location fails
    
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
        
        // Location Setup
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization() // Request permission
        
        // Start attempting to find location once permissions are granted
        if locationManager.authorizationStatus == .authorizedWhenInUse {
            locationManager.requestLocation()
        }
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
        
        self.saveProfileData(username: username, displayName: displayName, image: selectedProfileImage)
    }
    
    // MARK: - Orchestration and Base64 Encoding
    // Handle Base64 encoding and Firestore save
    func saveProfileData(username: String, displayName: String, image: UIImage?) {
        guard let user = currentUser else {
            errorLabel.text = "Authentication error. Please restart application."
            return
        }
        
        // Base64 ENCODING LOGIC
        var base64String: String? = nil
        if let selectedImage = image {
            // Resize the image to a max of 500x500 pixels for small storage size
            if let resizedImage = selectedImage.resizedToMaxSquare(500) {
                // Compress the image to JPEG with moderate quality (0.6)
                if let compressedData = resizedImage.jpegData(compressionQuality: 0.6) {
                    // Encode the compressed data to a Base64 string
                    base64String = compressedData.base64EncodedString()
                    self.errorLabel.text = "Profile picture encoded..."
                }
            }
        }
        
        // Check for duplicate usernames and save data
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
                    "createdAt": FieldValue.serverTimestamp(),
                    "region": self.regionCode, // Uses the region determined by Core Location
                    "currentEmoji": "🙂"
                ]
                
                // Include the Base64 string in the photoURL field
                if let base64 = base64String {
                    userData["photoURL"] = "data:image/jpeg;base64,\(base64)" // It's good practice to prepend the data URI scheme
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
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // If permissions change to authorized, start the location request
        if manager.authorizationStatus == .authorizedWhenInUse {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        
        // Stop updates once a location is found
        manager.stopUpdatingLocation()
        
        // Reverse geocode to get the region code
        geocoder.reverseGeocodeLocation(location) { [weak self] (placemarks, error) in
            guard let self = self else { return }
            
            // Get the two-letter ISO country code (e.g., "US")
            if let countryCode = placemarks?.first?.isoCountryCode {
                self.regionCode = countryCode.uppercased()
                print("Detected Region Code: \(self.regionCode)")
            } else {
                print("Could not determine country code from location.")
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription). Defaulting to US.")
        // regionCode remains the default "US"
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
