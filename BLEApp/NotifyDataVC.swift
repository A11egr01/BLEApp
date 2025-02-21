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
        selectedDevice.peripheral.delegate = self

        // ✅ Subscribe to characteristic notifications
        selectedDevice.peripheral.setNotifyValue(true, for: characteristic)

        // ✅ Setup TextView properties
        textView.isEditable = false
        textView.text = "Waiting for data...\n"
    }

    // ✅ Read incoming BLE data
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("❌ Error reading data: \(error)")
            return
        }

        if let data = characteristic.value {
            let hexString = data.map { String(format: "%02X", $0) }.joined(separator: " ")
            print("📡 Received Data: \(hexString)")

            DispatchQueue.main.async {
                self.appendDataToTextView("📡 \(hexString)")
            }
        }
    }

    /// ✅ Append new data to the text view with automatic scrolling
    private func appendDataToTextView(_ newData: String) {
        receivedData.append("\(newData)\n")
        textView.text = receivedData

        // ✅ Auto-scroll to the latest data
        let range = NSMakeRange(textView.text.count - 1, 1)
        textView.scrollRangeToVisible(range)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // ✅ Unsubscribe from notifications when leaving
        selectedDevice.peripheral.setNotifyValue(false, for: characteristic)
    }
}
