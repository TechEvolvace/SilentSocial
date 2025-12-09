// Project: SilentSocial
// Names: Phuc Dinh, Nicholas Ng, Preston Tu, Rui Xue
// Course: CS329E
// ProfileViewController.swift

import UIKit
import FirebaseAuth
import FirebaseFirestore

final class ProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var displayNameField: UITextField!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var regionField: UITextField!
    @IBOutlet weak var emojiField: UITextField!

    private var profile: UserProfile?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Profile"
        configureUI()
        loadProfile()
    }

    private func configureUI() {
        avatarImageView.layer.cornerRadius = avatarImageView.frame.width / 2
        avatarImageView.clipsToBounds = true
        avatarImageView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(changePhotoTapped))
        avatarImageView.addGestureRecognizer(tap)

        
        emojiField.delegate = self
        let tapEmoji = UITapGestureRecognizer(target: self, action: #selector(openEmojiPicker))
        emojiField.addGestureRecognizer(tapEmoji)
        emojiField.isUserInteractionEnabled = true
    }

    private func loadProfile() {
        guard let uid = FirebaseService.shared.currentUID() else {
            presentAlert("Not logged in", "Please log in again.")
            return
        }
        FirebaseService.shared.userDocRef(uid: uid).getDocument { [weak self] snap, err in
            guard let self = self else { return }
            if let err = err {
                self.presentAlert("Error", "Failed to load profile: \(err.localizedDescription)")
                return
            }
            if let data = snap?.data() {
                self.profile = UserProfile(uid: uid,
                                             displayName: data["displayName"] as? String ?? "New User",
                                             username: data["username"] as? String ?? "newuser",
                                             region: data["region"] as? String ?? "US",
                                             currentEmoji: data["currentEmoji"] as? String ?? "🙂",
                                             photoURL: data["photoURL"] as? String)
            } else {
                let p = UserProfile.empty(uid: uid)
                self.profile = p
                self.saveProfileToFirestore(p, silent: true)
            }
            self.populateUI()
        }
    }

    private func populateUI() {
        guard let p = profile else { return }
        displayNameField.text = p.displayName
        usernameField.text = p.username
        regionField.text = p.region
        emojiField.text = p.currentEmoji
        

        // Use Base64 decoding instead of URLSession for fetching image
        if let photoURL = p.photoURL, let image = self.image(from: photoURL) {
            self.avatarImageView.image = image
        } else {
            avatarImageView.image = UIImage(systemName: "person.circle")
        }
    }

    @IBAction func saveButtonTapped(_ sender: UIButton) {
        guard var p = profile else { return }
        // Update local profile with text field data
        p.displayName = displayNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? p.displayName
        p.username = usernameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? p.username
        p.region = regionField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? p.region
        p.currentEmoji = emojiField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? p.currentEmoji
        
        // Before saving, ensure the username field is cleaned up and only contains lowercase letters
        // (Assuming you do username validation elsewhere, like on the sign-up screen)
        p.username = p.username.lowercased()
        
        // This p now contains both the updated text fields AND the new photoURL
        // if the user had selected a photo.
        saveProfileToFirestore(p, silent: false)
    }

    @objc private func openEmojiPicker() {
        let picker = EmojiPickerViewController()
        picker.modalPresentationStyle = .overFullScreen
        picker.modalTransitionStyle = .crossDissolve
        picker.onPick = { [weak self] e in
            self?.emojiField.text = e
        }
        present(picker, animated: true)
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField === emojiField { openEmojiPicker(); return false }
        return true
    }

    private func saveProfileToFirestore(_ p: UserProfile, silent: Bool) {
        let doc: [String: Any] = [
            "displayName": p.displayName,
            "username": p.username,
            "region": p.region,
            "currentEmoji": p.currentEmoji,
            "photoURL": p.photoURL as Any
        ]
        FirebaseService.shared.userDocRef(uid: p.uid).setData(doc, merge: true) { [weak self] err in
            guard let self = self else { return }
            if let err = err {
                if !silent { self.presentAlert("Error", "Failed to save: \(err.localizedDescription)") }
            } else {
                self.profile = p
                if !silent {
                    self.presentAlert("Saved", "Profile updated.")
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }

    @IBAction func changePhotoButtonTapped(_ sender: UIButton) { changePhotoTapped() }

    @objc private func changePhotoTapped() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        present(picker, animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController,
                              didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        defer { picker.dismiss(animated: true) }
        guard let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage else { return }
        avatarImageView.image = image
        // Only update the local profile object, do not save to Firestore yet.
        updateLocalAvatar(image: image)
    }
    
    // Replaced Firebase Storage upload with Base64 encoding and local profile update
    private func updateLocalAvatar(image: UIImage) {
        guard let uid = FirebaseService.shared.currentUID() else { return }
        
        var base64String: String? = nil
        // Resize and compress the image for smaller storage size in Firestore
        if let resizedImage = image.resizedToMaxSquare(500),
            let compressedData = resizedImage.jpegData(compressionQuality: 0.6) {
                
            // Encode the compressed data to a Base64 string and prepend the data URI scheme
            base64String = "data:image/jpeg;base64,\(compressedData.base64EncodedString())"
        }

        // Save the Base64 string to the profile object LOCALLY
        guard var p = self.profile else { return }
        p.photoURL = base64String
        self.profile = p 
        
    }

    private func presentAlert(_ title: String, _ message: String) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }

    // MARK: - Base64 Helper
    
    /// Decodes a Base64 string (potentially with a data URI prefix) into a UIImage.
    private func image(from base64String: String) -> UIImage? {
        // Check for and strip the optional 'data:image/jpeg;base64,' prefix
        let parts = base64String.components(separatedBy: ",")
        guard let base64 = parts.last else { return nil }

        // Decode the Base64 string back into Data
        guard let data = Data(base64Encoded: base64, options: .ignoreUnknownCharacters) else { return nil }
        
        // Create UIImage from Data
        return UIImage(data: data)
    }
}
