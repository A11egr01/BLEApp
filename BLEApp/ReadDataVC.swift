//
//  ReadDataVC.swift
//  BLEApp
//
//  Created by Allegro on 2/21/25.
//

import UIKit
import CoreBluetooth

class ReadDataVC: UIViewController, CBPeripheralDelegate {
    
    @IBOutlet weak var uuidLabel: UILabel!
    @IBOutlet weak var propertiesLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    
    var selectedDevice: BLEDevice!
    var characteristic: CBCharacteristic!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Characteristic Details"
        selectedDevice.peripheral.delegate = self
        
        uuidLabel.text = "UUID: \(characteristic.uuid.uuidString)"
        propertiesLabel.text = "Properties: \(getCharacteristicProperties(characteristic))"
        valueLabel.text = "Reading value..."
        
        // ✅ Request the characteristic value again when the screen loads
        if characteristic.properties.contains(.read) {
            selectedDevice.peripheral.readValue(for: characteristic)
        }
    }
    
    // ✅ Get read values when they update
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("❌ Error reading value: \(error)")
            return
        }
        
        if let data = characteristic.value {
            let valueString = data.map { String(format: "%02X", $0) }.joined(separator: " ")
            print("📡 Read Value: \(valueString)")
            
            DispatchQueue.main.async {
                self.valueLabel.text = "Value: \(valueString)"
            }
        }
    }
}


func getCharacteristicProperties(_ characteristic: CBCharacteristic) -> String {
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

