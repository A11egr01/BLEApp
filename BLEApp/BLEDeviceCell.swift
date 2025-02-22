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
            manufacturerLabel.text = "\(device.manufacturer)"
        }
        
        // ✅ Append battery level if available
        if let battery = device.batteryLevel {
            manufacturerLabel.text! += " 🔋 Battery: \(battery)%"
        }

        // ✅ Append Last Seen timestamp if available
        if let timestamp = device.lastSeenTimestamp {
            let formattedTime = formatTimestamp(timestamp)
            manufacturerLabel.text! += " ⏳ Last Seen: \(formattedTime)"
        }

        uuidLabel.text = "UUID: \(device.peripheral.identifier.uuidString)"
        rssiLabel.textColor = getColorForRSSI(device.rssi.intValue)
    }

    
//    private func getColorForRSSI(_ rssi: Int) -> UIColor {
//        switch rssi {
//        case (-100)...(-86): return UIColor.brown   // 🟤 Very Weak
//        case (-85)...(-76): return UIColor.red     // 🔴 Weak
//        case (-75)...(-66): return UIColor.orange  // 🟠 Far
//        case (-65)...(-56): return UIColor.yellow  // 🟡 Medium Distance
//        case (-55)...(-46): return UIColor.systemGreen // 🟢 Close
//        case (-45)...(-30): return UIColor.green   // 🔥 Very Close
//        default: return UIColor.gray               // ⚫ Unknown / Out of Range
//        }
//    }
    
    private func getColorForRSSI(_ rssi: Int) -> UIColor {
        var distanceText = ""

        switch rssi {
        case (-100)...(-86):
            distanceText = "📡 Very Weak\n (~15+ meters)"
            rssiLabel.textColor = UIColor.brown  // 🟤 Very Weak
        case (-85)...(-76):
            distanceText = "📶 Weak\n (~10-15 meters)"
            rssiLabel.textColor = UIColor.red  // 🔴 Weak
        case (-75)...(-66):
            distanceText = "📡 Far\n (~5-10 meters)"
            rssiLabel.textColor = UIColor.orange  // 🟠 Far
        case (-65)...(-56):
            distanceText = "📡 Getting Closer\n (~2-5 meters)"
            rssiLabel.textColor = UIColor.systemBlue  // 🔵 Medium Distance
        case (-55)...(-46):
            distanceText = "📡 Close\n (~1-2 meters)"
            rssiLabel.textColor = UIColor.systemGreen  // 🟢 Close
        case (-45)...(-30):
            distanceText = "🎯 Very Close\n (~<1 meter)"
            rssiLabel.textColor = UIColor.green  // 💚 Extremely Close
        default:
            distanceText = "❓\n Unknown Distance"
            rssiLabel.textColor = UIColor.gray  // ⚫ Unknown / Out of Range
        }

        // ✅ Set the RSSI label with both value & distance
        rssiLabel.text = "RSSI: \(rssi) dBm\n\(distanceText)"

        // ✅ Return only the color (fixes logic issue)
        return rssiLabel.textColor
    }
    
    private func formatTimestamp(_ timestamp: TimeInterval) -> String {
        let elapsedTime = Date().timeIntervalSinceReferenceDate - timestamp

        if elapsedTime < 60 {
            return "\(Int(elapsedTime)) sec ago"
        } else if elapsedTime < 3600 {
            return "\(Int(elapsedTime / 60)) min ago"
        } else {
            return "\(Int(elapsedTime / 3600)) hr ago"
        }
    }

}
