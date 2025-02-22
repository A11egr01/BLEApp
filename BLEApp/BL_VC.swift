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

        override func viewDidLoad() {
            super.viewDidLoad()
            self.title = "BLE devices"
            tableView.dataSource = self
            tableView.delegate = self
            bleManager.delegate = self
            
            let nib = UINib(nibName: "BLEDeviceCell", bundle: nil)
            tableView.register(nib, forCellReuseIdentifier: "BLEDeviceCell")
            
            // 🔹 Setup Pull-to-Refresh
            refreshControl.addTarget(self, action: #selector(refreshBLEDevices), for: .valueChanged)
            tableView.refreshControl = refreshControl
            
            self.navigationItem.hidesBackButton = true
            toggle.insertSegment(withTitle: "iPhones", at: 2, animated: false)

            // ✅ Set up segmented control action
            toggle.addTarget(self, action: #selector(segmentedControlChanged), for: .valueChanged)
            
            // ✅ Initialize & Start Bluetooth Animation
            setupBluetoothIcon()
            startBluetoothAnimation()
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
            let detailsVC = DeviceDetailsVC()
            detailsVC.selectedDevice = selectedDevice
            navigationController?.pushViewController(detailsVC, animated: true)
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
        
        // ✅ Now, we just pass the BLEDevice object
        cell.configure(with: device)

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
    }
