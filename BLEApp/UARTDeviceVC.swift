//
//  UARTDeviceVC.swift
//  BLEApp
//
//  Created by Allegro on 2/23/25.
//

import UIKit
import CoreBluetooth

class UARTDeviceVC: UIViewController, UITableViewDataSource, UITableViewDelegate, CBPeripheralDelegate, UITextFieldDelegate {

    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var sendTextField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var responseTextView: UITextView!

    var selectedDevice: BLEDevice!
    let refreshControl = UIRefreshControl()
    
    var txCharacteristic: CBCharacteristic?
    var rxCharacteristic: CBCharacteristic?
    
    var writeCharacteristics: [CBCharacteristic] = [] // Store all writable characteristics

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "UART Terminal"
        
        tableView.dataSource = self
        tableView.delegate = self
        responseTextView.isEditable = false
        sendButton.isEnabled = false

        refreshControl.addTarget(self, action: #selector(refreshBLEData), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        selectedDevice.peripheral.delegate = self
        selectedDevice.peripheral.discoverServices(nil)
        sendTextField.delegate = self

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
           tapGesture.cancelsTouchesInView = false  // Allows tableView selection
           view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()  // Hide keyboard
        return true
    }

    /// 🔄 **Pull-to-Refresh: Rediscover Services**
    @objc func refreshBLEData() {
        print("🔄 Refreshing UART Services...")
        statusLabel.text = "🔄 Refreshing UART Services..."
        selectedDevice.services.removeAll()
        selectedDevice.characteristics.removeAll()
        responseTextView.text = ""
        txCharacteristic = nil
        rxCharacteristic = nil

        selectedDevice.peripheral.discoverServices(nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.refreshControl.endRefreshing()
        }
    }

    /// 🔍 **Discover Services & Characteristics**
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("❌ Service Discovery Error: \(error)")
            DispatchQueue.main.async {
                self.statusLabel.text = "❌ Service Discovery Error: \(error)"
            }

            return
        }
        guard let services = peripheral.services else { return }

        selectedDevice.services = services
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }

        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            let errorMessage = "❌ Characteristic Discovery Error: \(error.localizedDescription)"
            print(errorMessage)
            DispatchQueue.main.async {
                self.statusLabel.text = errorMessage
            }
            return
        }
        
        guard let characteristics = service.characteristics else { return }
        
        selectedDevice.characteristics[service] = characteristics

        for characteristic in characteristics {
            let foundMessage = "🔍 Found Characteristic: \(characteristic.uuid.uuidString)"
            print(foundMessage)
            DispatchQueue.main.async {
                self.statusLabel.text = foundMessage
            }

            // ✅ Handle writable characteristics
            if characteristic.properties.contains(.writeWithoutResponse) || characteristic.properties.contains(.write) {
                writeCharacteristics.append(characteristic)
                let txMessage = "✅ Writable Characteristic: \(characteristic.uuid.uuidString)"
                print(txMessage)
                DispatchQueue.main.async {
                    self.statusLabel.text = txMessage
                    self.sendButton.isEnabled = true  // ✅ Enable send button
                }
            }

            // ✅ Enable notifications for incoming data
            if characteristic.properties.contains(.notify) || characteristic.properties.contains(.indicate) {
                rxCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
                let rxMessage = "✅ RX Characteristic Enabled: \(characteristic.uuid.uuidString)"
                print(rxMessage)
                DispatchQueue.main.async {
                    self.statusLabel.text = rxMessage
                }
            }
        }

        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    /// 📡 **Receive UART Data**
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            let errorMessage = "❌ Data Error: \(error.localizedDescription)"
            print(errorMessage)
            DispatchQueue.main.async {
                self.statusLabel.text = errorMessage
            }
            return
        }

        guard let data = characteristic.value else { return }

        let translatedData = translateCharacteristicValue(data: data)
        let hexData = data.map { String(format: "%02X", $0) }.joined(separator: " ")
        
        let receivedMessage = "📡 Received: \(translatedData) (\(hexData))"
        print(receivedMessage)

        DispatchQueue.main.async {
            self.statusLabel.text = receivedMessage
            self.appendToResponseView(receivedMessage)
        }
    }

    /// ✍️ **Send Data to UART Device**
    @IBAction func sendCommand() {
        guard !writeCharacteristics.isEmpty else {
            let warningMessage = "⚠️ No writable characteristics found!"
            print(warningMessage)
            DispatchQueue.main.async {
                self.statusLabel.text = warningMessage
            }
            return
        }
        
        if writeCharacteristics.count == 1 {
            sendData(to: writeCharacteristics.first!)
        } else {
            showCharacteristicSelection()
        }
    }

    private func sendData(to characteristic: CBCharacteristic) {
        guard let text = sendTextField.text, !text.isEmpty else { return }

        let commandData = (text + "\n").data(using: .utf8)!
        selectedDevice.peripheral.writeValue(commandData, for: characteristic, type: .withoutResponse)

        let sentMessage = "🚀 Sent Command: \(text) to \(characteristic.uuid.uuidString)"
        print(sentMessage)
        DispatchQueue.main.async {
            self.statusLabel.text = sentMessage
        }

        sendTextField.text = ""
    }
    
    private func showCharacteristicSelection() {
        let alert = UIAlertController(title: "Select TX Characteristic", message: "Multiple writable characteristics found.", preferredStyle: .actionSheet)

        for characteristic in writeCharacteristics {
            alert.addAction(UIAlertAction(title: characteristic.uuid.uuidString, style: .default, handler: { _ in
                self.sendData(to: characteristic)
            }))
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true)
    }

    /// 📝 **Append Response to View**
    private func appendToResponseView(_ message: String) {
        responseTextView.text.append("\n\(message)")
        let range = NSMakeRange(responseTextView.text.count - 1, 1)
        responseTextView.scrollRangeToVisible(range)
    }

    /// 🔍 **Parse UART Data**
    private func translateCharacteristicValue(data: Data) -> String {
        if let textValue = String(data: data, encoding: .utf8), !textValue.isEmpty {
            return textValue.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if data.count == 1 { return "\(data[0])" }
        if data.count == 2 {
            let intValue = UInt16(data[0]) | (UInt16(data[1]) << 8)
            return "\(intValue)"
        }
        return data.map { String(format: "%02X", $0) }.joined(separator: " ")
    }

    /// 📜 **UITableView Data Source**
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? selectedDevice.services.count : selectedDevice.characteristics.values.flatMap({ $0 }).count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DetailCell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "DetailCell")

        if indexPath.section == 0 {
            let service = selectedDevice.services[indexPath.row]
            cell.textLabel?.text = "Service: \(service.uuid.uuidString)"
        } else {
            let characteristic = selectedDevice.characteristics.values.flatMap({ $0 })[indexPath.row]
            let propertiesText = getCharacteristicProperties(characteristic)
            cell.textLabel?.text = "Characteristic: \(characteristic.uuid.uuidString) \(propertiesText)"
        }

        return cell
    }

    /// 📖 **Format Properties**
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

        return properties.isEmpty ? "" : "[\(properties.joined(separator: ", "))]"
    }
}
