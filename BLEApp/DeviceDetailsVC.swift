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
           
           if isAirPods(selectedDevice.peripheral) {
               navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Alert", style: .plain, target: self, action: #selector(sendAlertToAirPods))
           }
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

           selectedDevice.services.removeAll()
           selectedDevice.characteristics.removeAll()

           // ✅ Rediscover services & characteristics
           selectedDevice.peripheral.discoverServices(nil)
           
           // Stop refresh animation after 2 seconds (prevents UI hang)
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

            // ✅ If characteristic supports Notify, open NotifyDataVC using XIB
            if characteristic.properties.contains(.notify) {
                let notifyVC = NotifyDataVC(nibName: "NotifyDataVC", bundle: nil)
                notifyVC.selectedDevice = selectedDevice
                notifyVC.characteristic = characteristic
                navigationController?.pushViewController(notifyVC, animated: true)
            }
            
            if characteristic.properties.contains(.read) {
                  // ✅ Open `ReadDataVC` to show the read data
                  let readVC = ReadDataVC(nibName: "ReadDataVC", bundle: nil)
                  readVC.selectedDevice = selectedDevice
                  readVC.characteristic = characteristic
                  navigationController?.pushViewController(readVC, animated: true)
              }
        }
    }
    
    /// 🔍 Known BLE Services and Their Names
    let knownServices: [String: String] = [
        "180A": "📱 Device Information",
        "180F": "🔋 Battery Service",
        "180D": "❤️ Heart Rate Monitor",
        "1809": "🌡️ Temperature Sensor",
        "181A": "🌍 Environmental Sensor",
        "1814": "👟 Step Counter",
        "FEAA": "📍 iBeacon Service",
        "D0611E78-BBB4-4591-A5F8-487910AE4366": "🎧 AirPods Service"
    ]

    /// 🔍 Known BLE Characteristics and Their Names
    let knownCharacteristics: [String: String] = [
        "2A29": "🏭 Manufacturer Name",
        "2A24": "📦 Model Number",
        "2A25": "🔢 Serial Number",
        "2A26": "💽 Firmware Version",
        "2A27": "🛠 Hardware Version",
        "2A19": "🔋 Battery Level",
        "2A37": "❤️ Heart Rate Data",
        "2A1C": "🌡️ Body Temperature",
        "2A6E": "🌡️ Air Temperature",
        "2A67": "🏃 Speed Data",
        "2A6C": "🧭 Altitude Data",
        "2A53": "👟 Step Count",
        "2A68": "📏 Stride Length",
        "2A6B": "📍 GPS Coordinates",
        "2A07": "📡 TX Power",
        "2A00": "🎧 AirPods Name"
    ]

   }
