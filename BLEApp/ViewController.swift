//
//  ViewController.swift
//  BLEApp
//
//  Created by Allegro on 2/21/25.
//

import UIKit

class ViewController: UIViewController {

    private let breathingBubble: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.blue
        view.layer.cornerRadius = 50 // Initial size, will animate
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let breathLabel: UILabel = {
        let label = UILabel()
        label.text = "...Breathe..."
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBreathingBubble()
        startBreathingAnimation()
        view.backgroundColor = .white

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { // Change time if needed
            self.pushBL_VC()
        }
    }

    private func setupBreathingBubble() {
        view.addSubview(breathingBubble)
        breathingBubble.addSubview(breathLabel)

        NSLayoutConstraint.activate([
            breathingBubble.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            breathingBubble.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            breathingBubble.widthAnchor.constraint(equalToConstant: 100),
            breathingBubble.heightAnchor.constraint(equalToConstant: 100),
            
            breathLabel.centerXAnchor.constraint(equalTo: breathingBubble.centerXAnchor),
            breathLabel.centerYAnchor.constraint(equalTo: breathingBubble.centerYAnchor)
        ])
    }

    private func startBreathingAnimation() {
        UIView.animate(withDuration: 1.5,
                       delay: 0,
                       options: [.repeat, .autoreverse, .allowUserInteraction],
                       animations: {
            self.breathingBubble.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        })
    }

    private func pushBL_VC() {
        UIView.animate(withDuration: 0.5, animations: {
            self.breathingBubble.alpha = 0
        }) { _ in
            let blVC = BL_VC()
            self.navigationController?.pushViewController(blVC, animated: true)
        }
    }
}

