//
//  BL_VC.swift
//  BLEApp
//
//  Created by Allegro on 2/21/25.
//

import UIKit
import CoreBluetooth

class BL_VC: UIViewController, UITableViewDataSource, UITableViewDelegate, BLEManagerDelegate {
    
    @IBOutlet weak var radarView: UIView!
    @IBOutlet weak var toggle: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    
    var bleManager = BLEManager()
    var devices: [BLEDevice] = []

    var filteredDevices: [BLEDevice] = []
    let refreshControl = UIRefreshControl()
    var bluetoothIconView: UIImageView!  // ✅ Bluetooth icon
    var isScanning = false  // ✅ Track scanning state
    var autoConnectBarButton = UIBarButtonItem()
    
    var autoConnectButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Auto-Connect", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14) // ✅ Set smaller font size
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "BLE devices"

        self.navigationItem.hidesBackButton = true
        
        toggle.insertSegment(withTitle: "iPhones", at: 2, animated: false)

        
        toggle.addTarget(self, action: #selector(segmentedControlChanged), for: .valueChanged)
        
        // ✅ Initialize & Start Bluetooth Animation
        setupBluetoothIcon()
        startBluetoothAnimation()
        setUpDevicesTableView()


        setAutoVCButton()
        updateAutoConnectButtonState()
        educationalLabel()
    }
    
    func educationalLabel() {
        let firstLaunchKey = "didShowLongPressHint"
        if !UserDefaults.standard.bool(forKey: firstLaunchKey) {
            UserDefaults.standard.set(true, forKey: firstLaunchKey)

            let hintLabel = UILabel()
            hintLabel.text = "👆 Long press a device for more actions!"
            hintLabel.textAlignment = .center
            hintLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
            hintLabel.textColor = .white
            hintLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            hintLabel.layer.cornerRadius = 10
            hintLabel.clipsToBounds = true
            hintLabel.numberOfLines = 0
            hintLabel.alpha = 0 // Start hidden for fade-in effect
            hintLabel.translatesAutoresizingMaskIntoConstraints = false

            view.addSubview(hintLabel)

            // ✅ Auto Layout constraints for centering
            NSLayoutConstraint.activate([
                hintLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                hintLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                hintLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
                hintLabel.heightAnchor.constraint(equalToConstant: 50)
            ])

            // ✅ Fade-in animation, then fade-out
            UIView.animate(withDuration: 1, animations: {
                hintLabel.alpha = 1
            }) { _ in
                UIView.animate(withDuration: 3, delay: 2, options: .curveEaseOut, animations: {
                    hintLabel.alpha = 0
                }) { _ in
                    hintLabel.removeFromSuperview()
                }
            }
        }
    }
    
    func setUpDevicesTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        bleManager.delegate = self

        let nib = UINib(nibName: "BLEDeviceCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "BLEDeviceCell")
        
        refreshControl.addTarget(self, action: #selector(refreshBLEDevices), for: .valueChanged)
        tableView.refreshControl = refreshControl
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        tableView.addGestureRecognizer(longPressGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateAutoConnectButtonState()
    }
    
    func setAutoVCButton() {
        // ✅ Set up Auto-Connect Button in Nav Bar
            let autoConnectBarButton = UIBarButtonItem(customView: autoConnectButton)
            navigationItem.leftBarButtonItem = autoConnectBarButton

            // ✅ Set action inside viewDidLoad
            autoConnectButton.addTarget(self, action: #selector(showAutoConnectList), for: .touchUpInside)
            
            updateAutoConnectButtonState() // ✅ Update button appearance
    }
    
    func updateAutoConnectButtonState() {
        let hasAutoConnectDevices = !bleManager.autoConnectDevices.isEmpty

        autoConnectButton.isEnabled = hasAutoConnectDevices
        autoConnectButton.setTitleColor(hasAutoConnectDevices ? .systemBlue : .gray, for: .normal) // ✅ Grey out if empty
    }
    
    @objc func showAutoConnectList() {
        let autoConnectVC = AutoConnectVC()
        autoConnectVC.bleManager = self.bleManager
        navigationController?.pushViewController(autoConnectVC, animated: true)
    }
    
    /// ✅ Called when BLE devices update
    func didUpdateDevices(devices: [BLEDevice]) {
        self.devices = devices
        applyFilter()
    }
    
    /// ✅ Filters devices based on selected segment
    @objc func segmentedControlChanged() {
        applyFilter()
    }
    
    private func applyFilter() {
        switch toggle.selectedSegmentIndex {
        case 0:
            filteredDevices = devices.filter {
                guard let name = $0.peripheral.name else { return false }
                return !(name.contains("iPhone") || name.contains("iPad") || name.contains("iMac") || name.contains("Mac"))
            }                    case 1:
            filteredDevices = devices.filter { $0.peripheral.name == nil }
        case 2:  // iPhones Filter
            filteredDevices = devices.filter {
                guard let name = $0.peripheral.name else { return false }
                return name.contains("iPhone") || name.contains("iPad") || name.contains("iMac") || name.contains("Mac")
            }
        default:
            break
        }
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedDevice = filteredDevices[indexPath.row]

        if selectedDevice.peripheral.name == "FM12" {
            print("📡 FM12 detected! Using FM12Device class.")

            // ✅ Get the corresponding EAAccessory from BLEManager
            if let fm12Accessory = bleManager.getClassicDevice(named: "FM12") {
                
                // ✅ Create an FM12-specific device object
                let fm12Device = FM12Device(accessory: fm12Accessory)

                // ✅ Open TransparentVC with FM12Device
                let transparentVC = TransparentVC()
                transparentVC.selectedDevice = fm12Device
                navigationController?.pushViewController(transparentVC, animated: true)

            } else {
                print("❌ FM12 accessory not found!")
            }

        } else {
            print("🛠 Normal BLE device detected! Opening MethodSwitcherVC...")
            
            // ✅ Open the standard BLE device screen
            let detailsVC = MethodSwitcherVC()
            detailsVC.title = selectedDevice.peripheral.name ?? "No name"
            detailsVC.selectedDevice = selectedDevice
            navigationController?.pushViewController(detailsVC, animated: true)
        }
    }
    
    // 🔹 Called when user pulls down to refresh
    @objc func refreshBLEDevices() {
        print("🔄 Refreshing BLE Scan...")
        
        devices.removeAll()
        filteredDevices.removeAll()
        tableView.reloadData()
        bleManager.stopScanning()
        bleManager = BLEManager()
        bleManager.delegate = self
        bleManager.centralManagerDidUpdateState(bleManager.centralManager)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.refreshControl.endRefreshing()
        }
        
        // ✅ Restart Bluetooth animation
        startBluetoothAnimation()
    }
    
    // MARK: - UITableViewDataSource Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredDevices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BLEDeviceCell", for: indexPath) as! BLEDeviceCell
        
        let device = filteredDevices[indexPath.row]
        cell.backgroundColor = device.services.isEmpty ? .white : UIColor(white: 0.96, alpha: 1.0)
        
        // ✅ Check if the device has a UART service
        if device.services.contains(where: { isUARTService($0.uuid) }) {
            cell.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)  // Light blue for UART devices
            device.uart = true
        } else {
            cell.backgroundColor = device.services.isEmpty ? .white : UIColor(white: 0.96, alpha: 1.0)
            device.uart = false
        }
        
        if isUARTDevice(device.peripheral) {
            cell.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)
            device.uart = true
        } else {
            cell.backgroundColor = device.services.isEmpty ? .white : UIColor(white: 0.96, alpha: 1.0)
            device.uart = true
            
        }
        let isConnected = bleManager.connectedDevices.contains { $0.peripheral.identifier == device.peripheral.identifier }
        let isAutoConnected = bleManager.autoConnectDevices.contains(device.peripheral.identifier)

        // ✅ Configure cell with connection and auto-connect status
        cell.configure(with: device, connected: isConnected, autoConnected: isAutoConnected)

        // ✅ Reset background only when disconnected
        cell.backgroundColor = isConnected ? cell.backgroundColor : .white
        

        return cell
    }
    
    private func isUARTService(_ uuid: CBUUID) -> Bool {
        let uartServices: [CBUUID] = [
            CBUUID(string: "0001"), // Some modules use this
            CBUUID(string: "FFE0"), // TI CC254x
            CBUUID(string: "49535343-FE7D-4AE5-8FA9-9FAFD205E455"), // HM-10
            CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E") // Nordic UART Service (NUS)
        ]
        return uartServices.contains(uuid)
    }
    
    // ✅ Setup Bluetooth Icon Inside `radarView`
    func setupBluetoothIcon() {
        let iconSize: CGFloat = 50
        bluetoothIconView = UIImageView(image: UIImage(systemName: "dot.radiowaves.left.and.right"))  // ✅ Use SF Symbol
        bluetoothIconView.tintColor = .blue
        bluetoothIconView.contentMode = .scaleAspectFit
        bluetoothIconView.frame = CGRect(x: (radarView.bounds.width - iconSize) / 2,
                                         y: (radarView.bounds.height - iconSize) / 2,
                                         width: iconSize, height: iconSize)
        radarView.addSubview(bluetoothIconView)
    }
    
    // ✅ Start Pulsing Animation
    func startBluetoothAnimation() {
        isScanning = true
        
        let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
        pulseAnimation.duration = 1.0
        pulseAnimation.fromValue = 1.0
        pulseAnimation.toValue = 1.3
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .infinity
        bluetoothIconView.layer.add(pulseAnimation, forKey: "pulse")
        
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.duration = 1.0
        opacityAnimation.fromValue = 1.0
        opacityAnimation.toValue = 0.5
        opacityAnimation.autoreverses = true
        opacityAnimation.repeatCount = .infinity
        bluetoothIconView.layer.add(opacityAnimation, forKey: "fade")
    }
    
    // ✅ Stop Pulsing Animation
    func stopBluetoothAnimation() {
        isScanning = false
        bluetoothIconView.layer.removeAllAnimations()
    }
    
    /// ✅ Handle Long Press Gesture
    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        guard gestureRecognizer.state == .began else { return }
        
        //        let touchPoint = gestureRecognizer.location(in: tableView)
        //        if let indexPath = tableView.indexPathForRow(at: touchPoint) {
        //            let device = filteredDevices[indexPath.row]
        //            showConnectionActionSheet(for: device)
        //        }
        let touchPoint = gestureRecognizer.location(in: tableView)
        
        if let indexPath = tableView.indexPathForRow(at: touchPoint) {
            let device = filteredDevices[indexPath.row]
            
            let actionSheet = UIAlertController(title: device.peripheral.name ?? "Unknown Device", message: nil, preferredStyle: .actionSheet)
            
            // ✅ Connect or Disconnect Option
            if bleManager.connectedDevices.contains(where: { $0.peripheral.identifier == device.peripheral.identifier }) {
                actionSheet.addAction(UIAlertAction(title: "Disconnect", style: .destructive, handler: { _ in
                    self.bleManager.centralManager.cancelPeripheralConnection(device.peripheral)
                }))
            } else {
                actionSheet.addAction(UIAlertAction(title: "Connect", style: .default, handler: { _ in
                    self.bleManager.centralManager.connect(device.peripheral, options: nil)
                }))
            }
            
            // ✅ Auto-Connect Toggle
            if bleManager.autoConnectDevices.contains(device.peripheral.identifier) {
                actionSheet.addAction(UIAlertAction(title: "Remove from Auto-Connect", style: .default, handler: { _ in
                    self.bleManager.removeFromAutoConnect(device)
                    self.updateAutoConnectButtonState() // ✅ Update button state after removing
                }))
            } else {
                actionSheet.addAction(UIAlertAction(title: "Save to Auto-Connect", style: .default, handler: { _ in
                    self.bleManager.addToAutoConnect(device)
                    self.updateAutoConnectButtonState() // ✅ Update button state after adding
                }))
            }
            
            actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(actionSheet, animated: true)
        }
        
        /// ✅ Show Bottom Sheet (UIAlertController) with Connect/Disconnect options
        func showConnectionActionSheet(for device: BLEDevice) {
            let isConnected = bleManager.connectedDevices.contains { $0.peripheral.identifier == device.peripheral.identifier }
            
            let alert = UIAlertController(title: device.peripheral.name ?? "Unknown Device", message: "Choose an action", preferredStyle: .actionSheet)
            
            if isConnected {
                let disconnectAction = UIAlertAction(title: "Disconnect", style: .destructive) { _ in
                    print("🔴 Disconnecting from \(device.peripheral.name ?? "Unknown Device")")
                    self.bleManager.disconnectDevice(peripheral: device.peripheral)
                }
                alert.addAction(disconnectAction)
            } else {
                let connectAction = UIAlertAction(title: "Connect", style: .default) { _ in
                    print("🔵 Connecting to \(device.peripheral.name ?? "Unknown Device")")
                    self.bleManager.connectDevice(peripheral: device.peripheral)
                }
                alert.addAction(connectAction)
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alert.addAction(cancelAction)
            
            present(alert, animated: true, completion: nil)
        }
        
    }
}
