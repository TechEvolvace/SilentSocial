//  Project: SilentSocial
//  Names: Phuc Dinh, Nicholas Ng, Preston Tu, Rui Xue
//  Course: CS329E
//  SettingsTableViewController.swift

import UIKit
import FirebaseAuth
import FirebaseFirestore

final class SettingsTableViewController: UITableViewController {

    private enum Row: Int {
        case profile = 0
        case notifications = 1
        case theme = 2
        case changePassword = 3
        case logout = 4
        case deleteAccount = 5
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
    }

    override func numberOfSections(in tableView: UITableView) -> Int { 1 }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let row = Row(rawValue: indexPath.row) else { return }

        switch row {
        case .profile:
            performSegue(withIdentifier: "showProfileFromSettings", sender: nil)

        case .notifications:
            // Push the Notifications settings screen
            performSegue(withIdentifier: "showNotificationsSettings", sender: nil)

        case .theme:
            // Push the Theme settings screen
            performSegue(withIdentifier: "showThemeSettings", sender: nil)

        case .changePassword:
            sendPasswordReset()

        case .logout:
            logOut()

        case .deleteAccount:
            confirmDeleteAccount()
        }
    }

    // Actions
    private func sendPasswordReset() {
        guard let email = Auth.auth().currentUser?.email else {
            showInfo("Error", "No email on file for this account.")
            return
        }
        Auth.auth().sendPasswordReset(withEmail: email) { [weak self] err in
            if let err = err {
                self?.showInfo("Error", err.localizedDescription)
            } else {
                self?.showInfo("Email Sent", "Check \(email) to reset your password.")
            }
        }
    }

    private func logOut() {
        do {
            try Auth.auth().signOut()
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = scene.windows.first {
                let sb = UIStoryboard(name: "Main", bundle: nil)
                let loginVC = sb.instantiateViewController(withIdentifier: "LoginScreenViewController")
                window.rootViewController = loginVC
                window.makeKeyAndVisible()
            }
        } catch {
            showInfo("Error", error.localizedDescription)
        }
    }

    private func confirmDeleteAccount() {
        let a = UIAlertController(title: "Delete Account",
                                  message: "This cannot be undone.",
                                  preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        a.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
            self.deleteAccount()
        }))
        present(a, animated: true)
    }

    private func deleteAccount() {
        guard let user = Auth.auth().currentUser else { return }
        let uid = user.uid

        Firestore.firestore().collection("users").document(uid).delete { _ in }

        user.delete { [weak self] err in
            if let err = err {
                self?.showInfo("Error", "Re-auth required: \(err.localizedDescription)")
            } else {
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = scene.windows.first {
                    let sb = UIStoryboard(name: "Main", bundle: nil)
                    let loginVC = sb.instantiateViewController(withIdentifier: "LoginScreenViewController")
                    window.rootViewController = loginVC
                    window.makeKeyAndVisible()
                }
            }
        }
    }

    // Helper
    private func showInfo(_ title: String, _ message: String) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }
}
