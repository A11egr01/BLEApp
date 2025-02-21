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
            let hexString = data.map { String(format: "%02X", $0) }.joined(separator: " ")

            // ✅ Try to decode the value to readable text
            let translatedValue = translateCharacteristicValue(data: data)

            print("📡 Read Value: \(translatedValue) (\(hexString))")

            DispatchQueue.main.async {
                self.valueLabel.text = "Value: \(translatedValue) (\(hexString))"
            }
        }
    }

}

/// ✅ Translates characteristic values to readable format
func translateCharacteristicValue(data: Data) -> String {
    // ✅ 1️⃣ Try to decode as UTF-8 text
    if let textValue = String(data: data, encoding: .utf8), textValue.count > 0 {
        return textValue.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // ✅ 2️⃣ Try to decode as an integer (UInt8, UInt16, UInt32)
    if data.count == 1 {
        return "\(data[0])"
    } else if data.count == 2 {
        let intValue = UInt16(data[0]) | (UInt16(data[1]) << 8)
        return "\(intValue)"
    } else if data.count == 4 {
        let intValue = UInt32(data[0]) | (UInt32(data[1]) << 8) | (UInt32(data[2]) << 16) | (UInt32(data[3]) << 24)
        return "\(intValue)"
    }

    // ✅ 3️⃣ Try to decode as a UUID
    if data.count == 16 {
        let uuid = UUID(uuid: (data[0], data[1], data[2], data[3], data[4], data[5], data[6], data[7], data[8], data[9], data[10], data[11], data[12], data[13], data[14], data[15]))
        return uuid.uuidString
    }

    // ✅ 4️⃣ Default: Show as raw hex
    return data.map { String(format: "%02X", $0) }.joined(separator: " ")
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

