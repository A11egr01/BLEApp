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
    
    var selectedDevice: BLEDevice!
       var characteristic: CBCharacteristic!
       var receivedData: String = ""

       override func viewDidLoad() {
           super.viewDidLoad()
           
           title = "Live Data"
           textView.isEditable = false
           textView.text = "Waiting for data...\n"

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
               let translatedValue = translateCharacteristicValue(data: data)

               print("📡 Received Data: \(translatedValue) (\(hexString))")

               DispatchQueue.main.async {
                   self.appendDataToTextView("📡 \(translatedValue) (\(hexString))")
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

       /// ✅ Convert BLE data to a human-readable format
       private func translateCharacteristicValue(data: Data) -> String {
           if let textValue = String(data: data, encoding: .utf8), !textValue.isEmpty {
               return textValue.trimmingCharacters(in: .whitespacesAndNewlines)
           }
           if data.count == 1 { return "\(data[0])" }
           if data.count == 2 {
               let intValue = UInt16(data[0]) | (UInt16(data[1]) << 8)
               return "\(intValue)"
           }
           if data.count == 4 {
               let intValue = UInt32(data[0]) | (UInt32(data[1]) << 8) | (UInt32(data[2]) << 16) | (UInt32(data[3]) << 24)
               return "\(intValue)"
           }
           if data.count == 16 {
               let uuid = UUID(uuid: (data[0], data[1], data[2], data[3], data[4], data[5], data[6], data[7], data[8], data[9], data[10], data[11], data[12], data[13], data[14], data[15]))
               return uuid.uuidString
           }
           return data.map { String(format: "%02X", $0) }.joined(separator: " ")
       }

       override func viewWillDisappear(_ animated: Bool) {
           super.viewWillDisappear(animated)

           if characteristic.properties.contains(.notify) {
               print("🔌 Unsubscribing from notifications for \(characteristic.uuid.uuidString)")
               selectedDevice.peripheral.setNotifyValue(false, for: characteristic)
           }
       }
   }
