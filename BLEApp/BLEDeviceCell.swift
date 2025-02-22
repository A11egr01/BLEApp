//
//  BLEDeviceCell.swift
//  BLEApp
//
//  Created by Allegro on 2/21/25.
//

import UIKit
import CoreBluetooth

class BLEDeviceCell: UITableViewCell {
    
    @IBOutlet weak var deviceNameLabel: UILabel!
    @IBOutlet weak var uuidLabel: UILabel!
    @IBOutlet weak var rssiLabel: UILabel!
    @IBOutlet weak var manufacturerLabel: UILabel!
    
    
    func configure(with device: BLEDevice) {
        deviceNameLabel.text = device.peripheral.name ?? "Unknown Device"
        
        if device.manufacturer == "Unknown Manufacturer" {
            manufacturerLabel.text = ""
        } else {
            manufacturerLabel.text = "Manufacturer: \(device.manufacturer)"
        }
        
        // ✅ Append battery level if available
        if let battery = device.batteryLevel {
            manufacturerLabel.text! += " 🔋 Battery: \(battery)%"
        }
        
        uuidLabel.text = "UUID: \(device.peripheral.identifier.uuidString)"
        rssiLabel.text = "RSSI: \(device.rssi) dBm"
        rssiLabel.textColor = getColorForRSSI(device.rssi.intValue)
    }
    
    private func getColorForRSSI(_ rssi: Int) -> UIColor {
        switch rssi {
        case (-100)...(-86): return UIColor.brown   // 🟤 Very Weak
        case (-85)...(-76): return UIColor.red     // 🔴 Weak
        case (-75)...(-66): return UIColor.orange  // 🟠 Far
        case (-65)...(-56): return UIColor.yellow  // 🟡 Medium Distance
        case (-55)...(-46): return UIColor.systemGreen // 🟢 Close
        case (-45)...(-30): return UIColor.green   // 🔥 Very Close
        default: return UIColor.gray               // ⚫ Unknown / Out of Range
        }
    }
}
