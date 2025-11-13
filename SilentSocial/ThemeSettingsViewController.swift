//  Project: SilentSocial
//  Names: Phuc Dinh, Nicholas Ng, Preston Tu, Rui Xue
//  Course: CS329E
//  ThemeSettingsViewController.swift
import UIKit
extension UIColor {
    static var customBackground: UIColor {
        return UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                // Your custom dark gray here (this is iOS system dark gray)
                return UIColor(red: 28/255, green: 28/255, blue: 30/255, alpha: 1.0)
            } else {
                // Light mode color (use standard system background)
                return .systemBackground
            }
        }
    }
}
final class ThemeSettingsViewController: UIViewController {

    @IBOutlet weak var themeSegmentedControl: UISegmentedControl!

    private let defaults = UserDefaults.standard
    private let selectedThemeKey = "selectedThemeIndex"

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Theme"

        let savedIndex = defaults.object(forKey: selectedThemeKey) as? Int ?? 2
        themeSegmentedControl.selectedSegmentIndex = savedIndex
    }

    @IBAction func themeSegmentChanged(_ sender: UISegmentedControl) {
        let index = sender.selectedSegmentIndex
        defaults.set(index, forKey: selectedThemeKey)

        // Main path: current window
        if let scene = view.window?.windowScene,
           let sceneDelegate = scene.delegate as? SceneDelegate {
            sceneDelegate.applyThemeFromUserDefaults()
            return
        }

        // Fallback: first connected scene
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let sceneDelegate = scene.delegate as? SceneDelegate {
            sceneDelegate.applyThemeFromUserDefaults()
        }
    }
}
