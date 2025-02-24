//
//  MethodSwitcherVC.swift
//  BLEApp
//
//  Created by Allegro on 2/24/25.
//

import UIKit

class MethodSwitcherVC: UIViewController {
    
    let segmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["UART", "GATT"])
        control.selectedSegmentIndex = 0
        return control
    }()
    
    let containerView = UIView()
    var selectedDevice: BLEDevice!

    var uartVC: UARTDeviceVC?
    var detailsVC: DeviceDetailsVC?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        setupUI()
        
        // ✅ Initialize both view controllers
        uartVC = UARTDeviceVC()
        uartVC?.selectedDevice = selectedDevice
        detailsVC = DeviceDetailsVC()
        detailsVC?.selectedDevice = selectedDevice

        // ✅ Add target action correctly
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)

        // ✅ Add UART as the initial view (safely unwrap)
        if let uartVC = uartVC {
            switchToViewController(uartVC)
        }
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Info", style: .plain, target: self, action: #selector(showBLEInfo))
    }
    
    @objc func showBLEInfo() {
        let infoVC = BLEInfoVC()
        let navController = UINavigationController(rootViewController: infoVC)
        present(navController, animated: true)
    }
    
    func setupUI() {
        view.addSubview(segmentedControl)
        view.addSubview(containerView)
        
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            segmentedControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            segmentedControl.widthAnchor.constraint(equalToConstant: 250),
            
            containerView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 10),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc func segmentChanged() {
        // Remove the current child view controller
        removeChildViewControllers()
        
        // ✅ Safely unwrap the new view controller
        if let newVC = (segmentedControl.selectedSegmentIndex == 0) ? uartVC : detailsVC {
            switchToViewController(newVC)
        }
    }
    
    /// ✅ Corrected method name to avoid name conflict
    func switchToViewController(_ childVC: UIViewController) {
        addChild(childVC)
        childVC.view.frame = containerView.bounds
        containerView.addSubview(childVC.view)
        childVC.didMove(toParent: self)
    }
    
    func removeChildViewControllers() {
        for child in children {
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }
    }
}

