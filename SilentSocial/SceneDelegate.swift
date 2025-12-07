//  Project: SilentSocial
//  Names: Phuc Dinh, Nicholas Ng, Preston Tu, Rui Xue
//  Course: CS329E
//  SceneDelegate.swift

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let _ = (scene as? UIWindowScene) else { return }
        applyThemeFromUserDefaults()
    }

    func sceneDidDisconnect(_ scene: UIScene) { }
    func sceneDidBecomeActive(_ scene: UIScene) { }
    func sceneWillResignActive(_ scene: UIScene) { }
    func sceneWillEnterForeground(_ scene: UIScene) { }
    func sceneDidEnterBackground(_ scene: UIScene) { }

    // MARK: - Theme Handling

    func applyThemeFromUserDefaults() {
        let index = UserDefaults.standard.object(forKey: "selectedThemeIndex") as? Int ?? 2

        let style: UIUserInterfaceStyle
        switch index {
        case 0:
            style = .light
        case 1:
            style = .dark
        default:
            style = .unspecified // follow system
        }

        window?.overrideUserInterfaceStyle = style
        if let s = window?.windowScene {
            s.windows.forEach { $0.overrideUserInterfaceStyle = style }
        } else {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .forEach { scene in
                    scene.windows.forEach { $0.overrideUserInterfaceStyle = style }
                }
        }
    }
}
