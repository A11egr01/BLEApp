//
//  ViewController.swift
//  BLEApp
//
//  Created by Allegro on 2/21/25.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.pushBL_VC()
                }
    }
    
    private func pushBL_VC() {
         let blVC = BL_VC()
            self.navigationController?.pushViewController(blVC, animated: true)
        
    }


}

