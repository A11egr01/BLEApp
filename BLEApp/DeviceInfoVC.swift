//
//  DeviceInfoVC.swift
//  BLEApp
//
//  Created by Allegro on 2/21/25.
//

import UIKit
import CoreBluetooth

class DeviceInfoVC: UIViewController, CBPeripheralDelegate {
    
    @IBOutlet weak var manufacturerLabel: UILabel!
    @IBOutlet weak var modelLabel: UILabel!
    @IBOutlet weak var serialLabel: UILabel!
    @IBOutlet weak var firmwareLabel: UILabel!
    @IBOutlet weak var hardwareLabel: UILabel!

    var selectedDevice: BLEDevice!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Device Info"
        selectedDevice.peripheral.delegate = self

        manufacturerLabel.text = "Manufacturer: Reading..."
        modelLabel.text = "Model: Reading..."
        serialLabel.text = "Serial: Reading..."
        firmwareLabel.text = "Firmware: Reading..."
        hardwareLabel.text = "Hardware: Reading..."

        // ✅ Discover Device Information characteristics
        if let service = selectedDevice.services.first(where: { $0.uuid.uuidString == "180A" }) {
            for characteristic in selectedDevice.characteristics[service] ?? [] {
                selectedDevice.peripheral.readValue(for: characteristic)
            }
        }
    }
    
    // ✅ Update values when received
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("❌ Error reading device info: \(error)")
            return
        }

        if let data = characteristic.value, let value = String(data: data, encoding: .utf8) {
            print("📡 Read Value for \(characteristic.uuid.uuidString): \(value)")

            DispatchQueue.main.async {
                switch characteristic.uuid.uuidString {
                    case "2A29": self.manufacturerLabel.text = "Manufacturer: \(value)"
                    case "2A24": self.modelLabel.text = "Model: \(value)"
                    case "2A25": self.serialLabel.text = "Serial: \(value)"
                    case "2A26": self.firmwareLabel.text = "Firmware: \(value)"
                    case "2A27": self.hardwareLabel.text = "Hardware: \(value)"
                    default: break
                }
            }
        }
    }
}
