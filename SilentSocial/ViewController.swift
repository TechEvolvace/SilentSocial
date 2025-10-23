//  Project: SilentSocial
//  Names: Phuc Dinh, Nicholas Ng, Preston Tu, Rui Xue
//  Course: CS329E
//  ViewController.swift
//  SilentSocial
//
//  Created by Nicholas Gia-Bao Ng on 10/14/25.
//

import UIKit

class ViewController: UIViewController {
    // THIS IS THE MAIN VIEW CONTROLLER AFTER LOGGING IN/REGISTERING
    
    @IBOutlet weak var goToDashboardButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func goToDashboardTapped(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let dashboardVC = storyboard.instantiateViewController(withIdentifier: "DashboardViewController") as? DashboardViewController {
                dashboardVC.modalPresentationStyle = .fullScreen
                present(dashboardVC, animated: true, completion: nil)
            }
    }
}

