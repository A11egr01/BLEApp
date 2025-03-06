//
//  NotifyDataVC.swift
//  BLEApp
//
//  Created by Allegro on 2/21/25.
//

import UIKit
import CoreBluetooth

class NotifyDataVC: UIViewController, CBPeripheralDelegate {

    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var decodedData: UITextView!
    
    var selectedDevice: BLEDevice!
        var characteristic: CBCharacteristic!
        var receivedData: String = ""
        var receivedDecodedData: String = ""

        override func viewDidLoad() {
            super.viewDidLoad()
            
            title = "Live Data"
            textView.isEditable = false
            textView.text = "Waiting for data...\n"
            decodedData.isEditable = false
            decodedData.text = "Waiting for translation...\n"

            selectedDevice.peripheral.delegate = self

            // ✅ Ensure characteristic supports notifications
            if characteristic.properties.contains(.notify) || characteristic.properties.contains(.indicate) {
                selectedDevice.peripheral.setNotifyValue(true, for: characteristic)
                print("✅ Subscribed to notifications for \(characteristic.uuid.uuidString)")
            } else {
                print("⚠️ This characteristic does NOT support notifications.")
                textView.text = "⚠️ Notifications not supported for this characteristic."
            }
        }

        // ✅ Receive & Translate Incoming Data
        func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
            if let error = error {
                print("❌ Error reading data: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.appendDataToTextView("❌ Error receiving data: \(error.localizedDescription)")
                }
                return
            }

            if let data = characteristic.value {
                let hexString = data.map { String(format: "%02X", $0) }.joined(separator: " ")
                let translatedValue = translateCharacteristicValue(data: data, characteristic: characteristic)

                print("📡 Received Data: \(translatedValue) (\(hexString))")

                DispatchQueue.main.async {
                    self.appendDataToTextView("📡 \(hexString)")
                    self.appendDecodedData("🔍 \(translatedValue)")
                }
            }
        }

        /// ✅ Append new data to the text view with auto-scrolling
        private func appendDataToTextView(_ newData: String) {
            receivedData.append("\(newData)\n")
            textView.text = receivedData

            let range = NSMakeRange(textView.text.count - 1, 1)
            textView.scrollRangeToVisible(range)
        }
        
        /// ✅ Append decoded data to the translation text view
        private func appendDecodedData(_ newData: String) {
            receivedDecodedData.append("\(newData)\n")
            decodedData.text = receivedDecodedData

            let range = NSMakeRange(decodedData.text.count - 1, 1)
            decodedData.scrollRangeToVisible(range)
        }

        /// ✅ Convert BLE data to a human-readable format
        private func translateCharacteristicValue(data: Data, characteristic: CBCharacteristic) -> String {
            // ✅ Try to decode UTF-8 string
            if let textValue = String(data: data, encoding: .utf8), !textValue.isEmpty {
                return "📜 UTF-8 Text: \(textValue.trimmingCharacters(in: .whitespacesAndNewlines))"
            }

            // ✅ Common BLE Characteristics
            switch characteristic.uuid.uuidString {
                case "2A19":  // 🔋 Battery Level
                    return data.count == 1 ? "🔋 Battery: \(data[0])%" : "🔋 Battery: Unknown"

                case "2A6E", "2A6F":  // 🌡️ Temperature (Celsius or Fahrenheit)
                    if data.count == 2 {
                        let temp = Int16(data[0]) | (Int16(data[1]) << 8)
                        return "🌡️ Temperature: \(Float(temp) / 100)°C"
                    }

                case "2A37":  // ❤️ Heart Rate (BPM)
                    if data.count >= 2 {
                        let bpm = Int(data[1])
                        return "❤️ Heart Rate: \(bpm) BPM"
                    }

                case "2A58":  // ⚡ Power Measurement (Watt)
                    if data.count == 4 {
                        let power = UInt32(data[0]) | (UInt32(data[1]) << 8) | (UInt32(data[2]) << 16) | (UInt32(data[3]) << 24)
                        return "⚡ Power Output: \(power) W"
                    }

                case "2A08":  // ⏳ Date Time (Timestamp)
                    if data.count >= 7 {
                        let year = UInt16(data[0]) | (UInt16(data[1]) << 8)
                        let month = data[2]
                        let day = data[3]
                        let hour = data[4]
                        let minute = data[5]
                        let second = data[6]
                        return "📅 Date: \(year)-\(month)-\(day) ⏰ Time: \(hour):\(minute):\(second)"
                    }

                case "2A00":  // 📛 Device Name
                    return "📛 Device Name: \(String(decoding: data, as: UTF8.self))"

                case "2A01":  // 📏 Appearance
                    if data.count == 2 {
                        let appearance = UInt16(data[0]) | (UInt16(data[1]) << 8)
                        return "📏 Appearance Code: \(appearance)"
                    }

                case "2A07":  // 📡 TX Power Level (dBm)
                    if data.count == 1 {
                        return "📡 TX Power: \(Int8(bitPattern: data[0])) dBm"
                    }

                default:
                    break
            }

            // ✅ Handle Numeric Values
            if data.count == 1 {
                return "🔢 Single Byte: \(data[0])"
            }
            if data.count == 2 {
                let intValue = UInt16(data[0]) | (UInt16(data[1]) << 8)
                return "🔢 16-bit Integer: \(intValue)"
            }
            if data.count == 4 {
                let intValue = UInt32(data[0]) | (UInt32(data[1]) << 8) | (UInt32(data[2]) << 16) | (UInt32(data[3]) << 24)
                return "🔢 32-bit Integer: \(intValue)"
            }
            if data.count == 16 {
                let uuid = UUID(uuid: (data[0], data[1], data[2], data[3], data[4], data[5], data[6], data[7], data[8], data[9], data[10], data[11], data[12], data[13], data[14], data[15]))
                return "🔗 UUID: \(uuid.uuidString)"
            }

            return "📡 Raw Data: " + data.map { String(format: "%02X", $0) }.joined(separator: " ")
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)

            if characteristic.properties.contains(.notify) {
                print("🔌 Unsubscribing from notifications for \(characteristic.uuid.uuidString)")
                selectedDevice.peripheral.setNotifyValue(false, for: characteristic)
            }
        }
    }
