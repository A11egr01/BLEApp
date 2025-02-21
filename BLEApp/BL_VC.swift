//
//  BL_VC.swift
//  BLEApp
//
//  Created by Allegro on 2/21/25.
//

import UIKit
import CoreBluetooth

class BL_VC: UIViewController, UITableViewDataSource, UITableViewDelegate, BLEManagerDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    var bleManager = BLEManager()
    var devices: [BLEDevice] = []
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

      }
    
    func didUpdateDevices(devices: [BLEDevice]) {
          self.devices = devices
          tableView.reloadData()
      }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedDevice = devices[indexPath.row]
        
        let detailsVC = DeviceDetailsVC()
            detailsVC.selectedDevice = selectedDevice
            navigationController?.pushViewController(detailsVC, animated: true)
        
        
//        let detailsVC = TestVC()
////            detailsVC.selectedDevice = selectedDevice
//            navigationController?.pushViewController(detailsVC, animated: true)
            
    }
    
    // 🔹 Called when user pulls down to refresh
    @objc func refreshBLEDevices() {
        print("🔄 Refreshing BLE Scan...")

        devices.removeAll()
        tableView.reloadData()
        bleManager.stopScanning()  // ✅ Now this function exists!
        bleManager = BLEManager()
        bleManager.delegate = self
        bleManager.centralManagerDidUpdateState(bleManager.centralManager)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.refreshControl.endRefreshing()
        }
    }

      // MARK: - UITableViewDataSource Methods
      func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
          return devices.count
      }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BLEDeviceCell", for: indexPath) as! BLEDeviceCell

        let device = devices[indexPath.row]
        cell.configure(with: device.peripheral, manufacturer: device.manufacturer, manufacturerCode: device.manufacturerCode, rssi: device.rssi)

        return cell
    }

  }
