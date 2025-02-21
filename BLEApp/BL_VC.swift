//
//  BL_VC.swift
//  BLEApp
//
//  Created by Allegro on 2/21/25.
//

import UIKit
import CoreBluetooth

class BL_VC: UIViewController, UITableViewDataSource, UITableViewDelegate, BLEManagerDelegate {

    @IBOutlet weak var toggle: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    
    var bleManager = BLEManager()
        var devices: [BLEDevice] = []
        var filteredDevices: [BLEDevice] = []  // ✅ Filtered list
        let refreshControl = UIRefreshControl()  // 🔹 Add refresh control

        override func viewDidLoad() {
            super.viewDidLoad()
            
            tableView.dataSource = self
            tableView.delegate = self
            
            bleManager.delegate = self
            
            let nib = UINib(nibName: "BLEDeviceCell", bundle: nil)
            tableView.register(nib, forCellReuseIdentifier: "BLEDeviceCell")
            
            // 🔹 Setup Pull-to-Refresh
            refreshControl.addTarget(self, action: #selector(refreshBLEDevices), for: .valueChanged)
            tableView.refreshControl = refreshControl
            
            self.navigationItem.hidesBackButton = true

            // ✅ Set up segmented control action
            toggle.addTarget(self, action: #selector(segmentedControlChanged), for: .valueChanged)
        }
        
        /// ✅ Called when BLE devices update
        func didUpdateDevices(devices: [BLEDevice]) {
            self.devices = devices
            applyFilter()  // ✅ Apply filter before reloading data
        }
        
        /// ✅ Filters devices based on selected segment
        @objc func segmentedControlChanged() {
            applyFilter()
        }
        
        private func applyFilter() {
            if toggle.selectedSegmentIndex == 0 {
                // ✅ Show only named devices
                filteredDevices = devices.filter { $0.peripheral.name != nil }
            } else {
                // ✅ Show only unknown devices
                filteredDevices = devices.filter { $0.peripheral.name == nil }
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
        }

        // MARK: - UITableViewDataSource Methods
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return filteredDevices.count  // ✅ Use filtered devices
        }

        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "BLEDeviceCell", for: indexPath) as! BLEDeviceCell

            let device = filteredDevices[indexPath.row]
            if !device.services.isEmpty {
                cell.backgroundColor = UIColor(white: 0.96, alpha: 1.0)
            } else {
                cell.backgroundColor = .white
            }
            cell.configure(with: device.peripheral, manufacturer: device.manufacturer, manufacturerCode: device.manufacturerCode, rssi: device.rssi)

            return cell
        }
    }
