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
//    private var batteryLevel: Int?  // Store battery level

    var selectedDevice: BLEDevice!
       let refreshControl = UIRefreshControl()  // 🔄 Pull-to-Refresh

       override func viewDidLoad() {
           super.viewDidLoad()
           
           tableView.dataSource = self
           tableView.delegate = self
           title = selectedDevice.peripheral.name ?? "BLE Device"
           
           // ✅ Register the cell to prevent crashes
//           tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DetailCell")
           
           // ✅ Add Pull-to-Refresh
           refreshControl.addTarget(self, action: #selector(refreshBLEData), for: .valueChanged)
           tableView.refreshControl = refreshControl
           
           // ✅ Start discovering services when opening the view
           selectedDevice.peripheral.delegate = self
           selectedDevice.peripheral.discoverServices(nil)
           
               navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Try UART", style: .plain, target: self, action: #selector(tryUart))
       }
    
    /// 🏷️ Get characteristic properties as a readable string
    private func getCharacteristicProperties(_ characteristic: CBCharacteristic) -> String {
        var properties: [String] = []

        if characteristic.properties.contains(.read) {
            properties.append("📖 Read")
        }
        if characteristic.properties.contains(.write) {
            properties.append("✍️ Write")
        }
        if characteristic.properties.contains(.writeWithoutResponse) {
            properties.append("✍️ Write (No Response)")
        }
        if characteristic.properties.contains(.notify) {
            properties.append("🚀 Notify")
        }
        if characteristic.properties.contains(.indicate) {
            properties.append("🔔 Indicate")
        }
        if characteristic.properties.contains(.broadcast) {
            properties.append("📡 Broadcast")
        }
        if characteristic.properties.contains(.authenticatedSignedWrites) {
            properties.append("🔒 Auth Write")
        }
        if characteristic.properties.contains(.extendedProperties) {
            properties.append("🛠 Extended")
        }

        return properties.isEmpty ? "" : "[\(properties.joined(separator: ", "))]"
    }

    
    private func isAirPods(_ peripheral: CBPeripheral) -> Bool {
        guard let name = peripheral.name else { return false }
        return name.contains("Allegro") || name.contains("AirPods") || name.contains("AirPods Max")
    }
    
    @objc private func tryUart() {
        let vc = UARTDeviceVC()
        vc.selectedDevice = selectedDevice
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    /// 🔔 Send an alert signal to AirPods (Find My sound)
    @objc private func sendAlertToAirPods() {
        print("🔔 Sending alert signal to AirPods...")

        guard let airPodsService = selectedDevice.services.first(where: { $0.uuid.uuidString == "D0611E78-BBB4-4591-A5F8-487910AE4366" }) else {
            print("❌ AirPods service not found.")
            return
        }

        guard let alertCharacteristic = selectedDevice.characteristics[airPodsService]?.first(where: { $0.uuid.uuidString == "D0611E78-BBB4-4591-A5F8-487910AE4366" }) else {
            print("❌ AirPods alert characteristic not found.")
            return
        }

        let alertCommand: [UInt8] = [0x02] // Example: 0x02 might trigger the "Find My" sound
        let data = Data(alertCommand)
        
        if alertCharacteristic.properties.contains(.writeWithoutResponse) {
            selectedDevice.peripheral.writeValue(data, for: alertCharacteristic, type: .withoutResponse)
            print("✅ Alert command sent successfully.")
        } else {
            print("⚠️ Characteristic does not support writing.")
        }
    }


       /// 🔄 **Pull-to-Refresh: Request all BLE data again**
    @objc func refreshBLEData() {
        print("🔄 Refreshing BLE Device Data...")

        // ✅ Clear old data
        selectedDevice.services.removeAll()
        selectedDevice.characteristics.removeAll()

        // ✅ Reload table to avoid accessing empty arrays
        tableView.reloadData()

        // ✅ Rediscover services & characteristics
        selectedDevice.peripheral.discoverServices(nil)

        // ✅ Stop refresh animation after 2 seconds (prevents UI hang)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.refreshControl.endRefreshing()
        }
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
        // ✅ Ensure cell is initialized with .subtitle style
        let cell = tableView.dequeueReusableCell(withIdentifier: "DetailCell")
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: "DetailCell")
        
        cell.textLabel?.text = nil
        cell.detailTextLabel?.text = nil
        cell.detailTextLabel?.attributedText = nil
        cell.accessoryType = .none

        if indexPath.section == 0 {
            let keys = Array(selectedDevice.advertisementData.keys)
            guard indexPath.row < keys.count else { return cell }
            let key = keys[indexPath.row]
            let value = selectedDevice.advertisementData[key] ?? "N/A"
            cell.textLabel?.text = "\(key): \(value)"
        } else if indexPath.section == 1 {
            let service = selectedDevice.services[indexPath.row]
            cell.textLabel?.text = "Service: \(service.uuid.uuidString)"
            
            // ✅ Show extra service details in detailTextLabel
            if let serviceName = knownServices[service.uuid.uuidString] {
                cell.detailTextLabel?.text = "🛠 \(serviceName)"
            } else {
                cell.detailTextLabel?.text = ""
            }

            cell.accessoryType = .disclosureIndicator
        } else {
            let service = selectedDevice.services[indexPath.section - 2]
            guard let characteristics = selectedDevice.characteristics[service], indexPath.row < characteristics.count else { return cell }
            let characteristic = characteristics[indexPath.row]

            let propertiesText = getCharacteristicProperties(characteristic)
            cell.textLabel?.text = "Characteristic: \(characteristic.uuid.uuidString) \(propertiesText)"

            // ✅ Show extra characteristic details in detailTextLabel
            if let characteristicName = knownCharacteristics[characteristic.uuid.uuidString] {
                cell.detailTextLabel?.text = "🛠 \(characteristicName)"
            } else {
                cell.detailTextLabel?.text = ""
            }
            
            if characteristic.uuid.uuidString == "2A19" {  // Battery Level Characteristic
                let batteryText: String
                if let battery = selectedDevice.batteryLevel {
                    batteryText = "🔋 Battery Level: \(battery)%"
                } else {
                    batteryText = "🔋 Battery Level: Fetching..."
                }

                let attributedText = NSMutableAttributedString(string: batteryText)
                
                if let battery = selectedDevice.batteryLevel {
                    let range = (batteryText as NSString).range(of: "\(battery)%")
                    attributedText.addAttributes([.font: UIFont.boldSystemFont(ofSize: 16)], range: range)
                }
                
                cell.detailTextLabel?.attributedText = attributedText
            }

        }
        

        
        cell.textLabel?.numberOfLines = 0
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

       // ✅ Handle BLE Service & Characteristic Discovery
       func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
           if let error = error {
               print("❌ Error discovering services: \(error)")
               return
           }

           if let services = peripheral.services {
               selectedDevice.services = services
               print("🔍 Discovered Services: \(services.map { $0.uuid.uuidString })")

               for service in services {
                   peripheral.discoverCharacteristics(nil, for: service)
               }
           }

           DispatchQueue.main.async {
               self.tableView.reloadData()
           }
       }

       func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
           if let error = error {
               print("❌ Error discovering characteristics: \(error)")
               return
           }

           if let characteristics = service.characteristics {
               selectedDevice.characteristics[service] = characteristics
               print("🔍 Characteristics for \(service.uuid): \(characteristics.map { $0.uuid.uuidString })")
               
           }
           
           guard let characteristics = service.characteristics else { return }
           selectedDevice.characteristics[service] = characteristics
           
           for characteristic in characteristics {
                 print("🔍 Found Characteristic: \(characteristic.uuid.uuidString)")

                 // ✅ Automatically read battery level
                 if characteristic.uuid.uuidString == "2A19" {
                     print("🔋 Requesting battery level...")
                     peripheral.readValue(for: characteristic)
                 }
               
               if characteristic.properties.contains(.read) {
                   print("📖 Requesting read for characteristic \(characteristic.uuid.uuidString)...")
                   peripheral.readValue(for: characteristic)
               }
             }

           DispatchQueue.main.async {
               self.tableView.reloadData()
           }
       }

       // ✅ Expand characteristics when a service is tapped
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 1 {  // Services section
            let service = selectedDevice.services[indexPath.row]

            if service.uuid.uuidString == "180A" {  // ✅ Device Information Service
                let deviceInfoVC = DeviceInfoVC(nibName: "DeviceInfoVC", bundle: nil)
                deviceInfoVC.selectedDevice = selectedDevice
                navigationController?.pushViewController(deviceInfoVC, animated: true)
            }
        }
        
        if indexPath.section > 1 {  // Only for characteristics
            let service = selectedDevice.services[indexPath.section - 2]
            guard let characteristics = selectedDevice.characteristics[service], indexPath.row < characteristics.count else { return }
            
            let characteristic = characteristics[indexPath.row]

            let supportsRead = characteristic.properties.contains(.read)
            let supportsNotify = characteristic.properties.contains(.notify)

            if supportsRead && supportsNotify {
                // ✅ Show action sheet to choose Read or Notify
                presentCharacteristicActionSheet(characteristic)
            } else if supportsRead {
                // ✅ Directly open Read screen
                openReadVC(for: characteristic)
            } else if supportsNotify {
                // ✅ Directly open Notify screen
                openNotifyVC(for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("❌ Error reading characteristic value: \(error)")
            return
        }

        // ✅ Battery Level (Handled in DeviceDetailsVC)
        if characteristic.uuid.uuidString == "2A19", let value = characteristic.value {
            selectedDevice.batteryLevel = Int(value.first ?? 0)
            print("🔋 Battery Level Updated: \(selectedDevice.batteryLevel ?? 0)%")
            
            DispatchQueue.main.async {
                if let batteryIndexPath = self.indexPathForBatteryCharacteristic() {
                    self.tableView.reloadRows(at: [batteryIndexPath], with: .fade)
                }
            }
            return  // 🔄 Exit to avoid processing in other VCs
        }

        // ❌ Ignore updates for Notify, Read, or Device Info handled elsewhere
        if characteristic.properties.contains(.notify) ||
           characteristic.properties.contains(.read) ||
           characteristic.properties.contains(.indicate) {
            print("➡️ Ignoring update for characteristic \(characteristic.uuid.uuidString), handled in other VCs")
            return
        }
    }
    private func indexPathForBatteryCharacteristic() -> IndexPath? {
        for (serviceIndex, service) in selectedDevice.services.enumerated() {
            if let characteristics = selectedDevice.characteristics[service] {
                for (charIndex, characteristic) in characteristics.enumerated() {
                    if characteristic.uuid.uuidString == "2A19" {
                        return IndexPath(row: charIndex, section: serviceIndex + 2)
                    }
                }
            }
        }
        return nil
    }
    
    private func presentCharacteristicActionSheet(_ characteristic: CBCharacteristic) {
        let actionSheet = UIAlertController(title: "Select Action",
                                            message: "Would you like to read the characteristic value or receive live updates?",
                                            preferredStyle: .actionSheet)

        let readAction = UIAlertAction(title: "📖 Read Data", style: .default) { _ in
            self.openReadVC(for: characteristic)
        }

        let notifyAction = UIAlertAction(title: "🚀 Notify (Live Updates)", style: .default) { _ in
            self.openNotifyVC(for: characteristic)
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

        actionSheet.addAction(readAction)
        actionSheet.addAction(notifyAction)
        actionSheet.addAction(cancelAction)

        present(actionSheet, animated: true)
    }
    
    private func openReadVC(for characteristic: CBCharacteristic) {
        let readVC = ReadDataVC(nibName: "ReadDataVC", bundle: nil)
        readVC.selectedDevice = selectedDevice
        readVC.characteristic = characteristic
        navigationController?.pushViewController(readVC, animated: true)
    }

    private func openNotifyVC(for characteristic: CBCharacteristic) {
        let notifyVC = NotifyDataVC(nibName: "NotifyDataVC", bundle: nil)
        notifyVC.selectedDevice = selectedDevice
        notifyVC.characteristic = characteristic
        navigationController?.pushViewController(notifyVC, animated: true)
    }
    
   }
