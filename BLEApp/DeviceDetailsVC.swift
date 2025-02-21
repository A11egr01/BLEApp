//
//  DeviceDetailsVC.swift
//  BLEApp
//
//  Created by Allegro on 2/21/25.
//

import UIKit
import CoreBluetooth

class DeviceDetailsVC: UIViewController, UITableViewDataSource, UITableViewDelegate, CBPeripheralDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    var selectedDevice: BLEDevice!

    override func viewDidLoad() {
           super.viewDidLoad()
           
           tableView.dataSource = self
           tableView.delegate = self
           title = selectedDevice.peripheral.name ?? "BLE Device"
           
           // ✅ Register the cell to prevent crashes
           tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DetailCell")
       }
       
       func numberOfSections(in tableView: UITableView) -> Int {
           return 2 + selectedDevice.services.count  // 1. Advertisement Data, 2. Services, 3+. Characteristics per service
       }
       
       func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
           if section == 0 {
               return selectedDevice.advertisementData.count
           } else if section == 1 {
               return selectedDevice.services.count
           } else {
               let service = selectedDevice.services[section - 2]
               return selectedDevice.characteristics[service]?.count ?? 0
           }
       }
       
       func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
           let cell = tableView.dequeueReusableCell(withIdentifier: "DetailCell", for: indexPath)
           
           if indexPath.section == 0 {
               let keys = Array(selectedDevice.advertisementData.keys)
               guard indexPath.row < keys.count else { return cell }
               let key = keys[indexPath.row]
               let value = selectedDevice.advertisementData[key] ?? "N/A"
               cell.textLabel?.text = "\(key): \(value)"
           } else if indexPath.section == 1 {
               let service = selectedDevice.services[indexPath.row]
               cell.textLabel?.text = "Service: \(service.uuid.uuidString)"
               cell.accessoryType = .disclosureIndicator  // ✅ Indicates it can be expanded
           } else {
               let service = selectedDevice.services[indexPath.section - 2]
               guard let characteristics = selectedDevice.characteristics[service], indexPath.row < characteristics.count else { return cell }
               let characteristic = characteristics[indexPath.row]
               cell.textLabel?.text = "Characteristic: \(characteristic.uuid.uuidString)"
           }
           
           return cell
       }
       
       func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
           if section == 0 { return "Advertisement Data" }
           else if section == 1 { return "Services" }
           else {
               let service = selectedDevice.services[section - 2]
               return "Characteristics for \(service.uuid.uuidString)"
           }
       }
       
       // ✅ Expand characteristics when a service is tapped
       func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
           if indexPath.section == 1 {  // Service section
               let service = selectedDevice.services[indexPath.row]
               if let characteristics = selectedDevice.characteristics[service], !characteristics.isEmpty {
                   let indexSet = IndexSet(integer: indexPath.row + 2)  // The corresponding characteristics section
                   tableView.reloadSections(indexSet, with: .automatic)
               }
           }
       }
   }
