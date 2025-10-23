//
//  ProfileViewController.swift
//  SilentSocial
//
//  Created by Preston Tu on 10/20/25.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

final class ProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

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

        if let urlStr = p.photoURL, let url = URL(string: urlStr) {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                guard let data = data, let img = UIImage(data: data) else { return }
                DispatchQueue.main.async { self.avatarImageView.image = img }
            }.resume()
        } else {
            avatarImageView.image = UIImage(systemName: "person.circle")
        }
    }

    @IBAction func saveButtonTapped(_ sender: UIButton) {
        guard var p = profile else { return }
        p.displayName = displayNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? p.displayName
        p.username = usernameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? p.username
        p.region = regionField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? p.region
        p.currentEmoji = emojiField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? p.currentEmoji
        saveProfileToFirestore(p, silent: false)
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
        uploadAvatar(image: image)
    }

    private func uploadAvatar(image: UIImage) {
        guard let uid = FirebaseService.shared.currentUID() else { return }
        guard let data = image.jpegData(compressionQuality: 0.85) else { return }
        let ref = FirebaseService.shared.storageProfileImageRef(uid: uid)
        let metadata = StorageMetadata(); metadata.contentType = "image/jpeg"

        ref.putData(data, metadata: metadata) { [weak self] _, err in
            guard let self = self else { return }
            if let err = err { self.presentAlert("Upload Error", err.localizedDescription); return }
            ref.downloadURL { url, err in
                if let err = err { self.presentAlert("URL Error", err.localizedDescription); return }
                guard let url = url, var p = self.profile else { return }
                p.photoURL = url.absoluteString
                self.saveProfileToFirestore(p, silent: true)
            }
        }
    }

    private func presentAlert(_ title: String, _ message: String) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }
}
