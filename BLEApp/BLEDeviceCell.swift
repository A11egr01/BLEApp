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

    
    func configure(with peripheral: CBPeripheral, manufacturer: String, manufacturerCode: String, rssi: NSNumber) {
            deviceNameLabel.text = peripheral.name ?? "Unknown Device"

            if manufacturer == "Unknown Manufacturer" {
                manufacturerLabel.text = "Manufacturer: \(manufacturer) (\(manufacturerCode))"
            } else {
                manufacturerLabel.text = "Manufacturer: \(manufacturer)"
            }

            uuidLabel.text = "UUID: \(peripheral.identifier.uuidString)"
            rssiLabel.text = "RSSI: \(rssi) dBm"
        }
}
