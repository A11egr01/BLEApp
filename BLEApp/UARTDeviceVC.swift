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

    @IBOutlet weak var listenSwitch: UIButton!
    @IBOutlet weak var listeningLabel: UILabel!
    
    var selectedDevice: BLEDevice!
    let refreshControl = UIRefreshControl()
    
    var txCharacteristic: CBCharacteristic?
    var rxCharacteristic: CBCharacteristic? {
           didSet {
               updateListeningLabel()
           }
       }
    var writeCharacteristics: [CBCharacteristic] = [] // Store all writable characteristics

    override func viewDidLoad() {
        super.viewDidLoad()
//        title = "UART Terminal"
        self.title = (selectedDevice.peripheral.name ?? "") + " | UART"
        tableView.dataSource = self
        tableView.delegate = self
        responseTextView.isEditable = false
        sendButton.isEnabled = false

        refreshControl.addTarget(self, action: #selector(refreshBLEData), for: .valueChanged)
//        tableView.refreshControl = refreshControl
        
        selectedDevice.peripheral.delegate = self
        selectedDevice.peripheral.discoverServices(nil)
        sendTextField.delegate = self

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
           tapGesture.cancelsTouchesInView = false  // Allows tableView selection
           view.addGestureRecognizer(tapGesture)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Info", style: .plain, target: self, action: #selector(showBLEInfo))
        
        updateConnectionStatus()
//        NotificationCenter.default.addObserver(self, selector: #selector(handleDisconnection2(_:)), name: NSNotification.Name("DeviceDisconnected"), object: nil)
        NotificationCenter.default.addObserver(
              self,
              selector: #selector(handleDisconnection2(_:)),
              name: .deviceDisconnected,
              object: nil
          )
    }
    
    deinit {
          // Remove the observer when the view controller is deallocated
          NotificationCenter.default.removeObserver(self, name: .deviceDisconnected, object: nil)
      }
    
    private func updateConnectionStatus() {
        if selectedDevice.peripheral.state == .connected {
            statusLabel.text = "✅ Connected to \(selectedDevice.peripheral.name ?? "Device")"
            statusLabel.textColor = .systemGreen
        } else {
            statusLabel.text = "❌ Disconnected"
            statusLabel.textColor = .systemRed
            responseTextView.text = ""
//            handleDisconnection()
        }
    }
    
    private func updateListeningLabel() {
        if let rx = rxCharacteristic {
            let friendlyName = knownCharacteristics[rx.uuid.uuidString] ?? rx.uuid.uuidString
            DispatchQueue.main.async {
                self.listeningLabel.text = "🎧 Listening to: \(friendlyName)"
            }
        } else {
            listeningLabel.text = "❌ Not listening to any characteristic."
        }
    }
    
    @objc private func handleDisconnection(_ notification: Notification) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.navigationController?.popViewController(animated: true)
        }
        
        // ✅ Clear characteristic lists on disconnection
        writeCharacteristics.removeAll()
        rxCharacteristic = nil
        
        DispatchQueue.main.async {
            self.responseTextView.text = ""
        }

    }
    
    func handleDisconnection() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    @objc private func handleDisconnection2(_ notification: Notification) {
        // Extract the disconnected peripheral from the notification
        guard let userInfo = notification.userInfo,
              let disconnectedPeripheral = userInfo["peripheral"] as? CBPeripheral else {
            return
        }
        
        // Check if the disconnected peripheral matches selectedDevice
        if disconnectedPeripheral.identifier == selectedDevice.peripheral.identifier {
            DispatchQueue.main.async {
                self.updateConnectionStatus()
                
                // Optionally, navigate back to the previous screen after a delay
//                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
//                    self.navigationController?.popViewController(animated: true)
//                }
            }
        }
    }
    
    @objc func showBLEInfo() {
        let infoVC = BLEInfoVC()
        let navController = UINavigationController(rootViewController: infoVC)
        present(navController, animated: true)
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
        
        // ✅ Clear previous characteristic references
        writeCharacteristics.removeAll()
        rxCharacteristic = nil

        selectedDevice.peripheral.discoverServices(nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.refreshControl.endRefreshing()
        }
    }

    /// 🔍 **Discover Services & Characteristics**
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("🔸 [UARTDeviceVC] cices")

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

        // Prepare an array to gather eligible notification characteristics.
        var eligibleRxChars: [CBCharacteristic] = []

        for characteristic in characteristics {
            let foundMessage = "🔍 Found Characteristic: \(characteristic.uuid.uuidString)"
            print(foundMessage)
            DispatchQueue.main.async {
                self.statusLabel.text = foundMessage
            }

            // ✅ Prevent duplicates in writeCharacteristics
            if (characteristic.properties.contains(.writeWithoutResponse) || characteristic.properties.contains(.write)),
               !writeCharacteristics.contains(where: { $0.uuid == characteristic.uuid }) {
                writeCharacteristics.append(characteristic)
                let txMessage = "✅ Writable Characteristic: \(characteristic.uuid.uuidString)"
                print(txMessage)
                DispatchQueue.main.async {
                    self.statusLabel.text = txMessage
                    self.sendButton.isEnabled = true  // Enable send button
                }
            }

            // ✅ Prevent duplicates in eligibleRxChars
            if (characteristic.properties.contains(.notify) || characteristic.properties.contains(.indicate)),
               !eligibleRxChars.contains(where: { $0.uuid == characteristic.uuid }) {
                eligibleRxChars.append(characteristic)
            }

            // If the characteristic is readable, trigger a read.
            if characteristic.properties.contains(.read) {
                print("📖 Requesting read for characteristic \(characteristic.uuid.uuidString)...")
                peripheral.readValue(for: characteristic)
            }
        }

        // ✅ Ensure rxCharacteristic is only set if it hasn’t been set before.
        if rxCharacteristic == nil, let firstEligible = eligibleRxChars.first {
            rxCharacteristic = firstEligible
            peripheral.setNotifyValue(true, for: firstEligible)
            let rxMessage = "✅ RX Characteristic Enabled: \(firstEligible.uuid.uuidString)"
            print(rxMessage)
            DispatchQueue.main.async {
                self.statusLabel.text = rxMessage
            }
        }

        DispatchQueue.main.async {
            self.tableView.reloadData()
        }    }


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

        var translatedData = translateCharacteristicValue(data: data)
        
        if characteristic.uuid.uuidString.uppercased() == "2A19", data.count == 1 {
            translatedData = "\(data[0])%"
        } else {
            translatedData = translateCharacteristicValue(data: data)
        }
        
        let hexData = data.map { String(format: "%02X", $0) }.joined(separator: " ")

        // ✅ Extract last 4 characters of UUID
        let characteristicID = String(characteristic.uuid.uuidString.suffix(4))

        // ✅ Get associated emoji for the characteristic
        let characteristicInfo = getCharacteristicInfo(characteristicID)
        let readIndicator = characteristic.properties.contains(.read) ? "📖" : ""

        if translatedData == hexData {
            translatedData = "RAW: "
        }

        var receivedMessage = "📡 \(characteristicInfo.emoji) \(readIndicator) [\(characteristicID)] Received: \(translatedData) (\(hexData))"

        if characteristicInfo.emoji != "🔹" {
            receivedMessage = "📡 \(characteristicInfo.emoji) \(readIndicator) [\(characteristicID)] \(characteristicInfo.description): \(translatedData)"
        }
        
        print(receivedMessage)
        
        if characteristic.uuid.uuidString == "2A19", let value = characteristic.value {
            selectedDevice.batteryLevel = Int(value.first ?? 0)
        }

        DispatchQueue.main.async {
            self.statusLabel.text = receivedMessage
            self.appendToResponseView(receivedMessage)
//            self.responseTextView.scrollToBottom()
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

        // ✅ iPad Fix
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = self.view // Anchor to the main view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.maxY, width: 0, height: 0)
            popoverController.permittedArrowDirections = [] // Remove arrow
        }

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
        return selectedDevice.services.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let service = selectedDevice.services[section]

        let characteristicsCount = selectedDevice.characteristics[service]?.count ?? 0
        return 1 + characteristicsCount
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Dequeue or create the cell.
        let cell = tableView.dequeueReusableCell(withIdentifier: "DetailCell") ??
            UITableViewCell(style: .subtitle, reuseIdentifier: "DetailCell")
        cell.selectionStyle = .none
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.numberOfLines = 0
        cell.detailTextLabel?.attributedText = nil
        cell.accessoryType = .none
        cell.accessoryView = nil  // Clear any previous accessory

        let service = selectedDevice.services[indexPath.section]
        
        if indexPath.row == 0 {
            // Service Cell
            let serviceText = "Service: \(service.uuid.uuidString)"
            let attributedText = NSMutableAttributedString(string: serviceText,
                                                             attributes: [.font: UIFont.systemFont(ofSize: 17, weight: .regular)])
            if let range = serviceText.range(of: "Service:") {
                let nsRange = NSRange(range, in: serviceText)
                attributedText.addAttribute(.font, value: UIFont.systemFont(ofSize: 17, weight: .semibold), range: nsRange)
            }
            cell.textLabel?.attributedText = attributedText

            if let serviceName = knownServices[service.uuid.uuidString] {
                cell.detailTextLabel?.text = "🛠 \(serviceName)"
            } else {
                cell.detailTextLabel?.text = ""
            }
            
            cell.backgroundColor = UIColor(white: 0.95, alpha: 1.0)  // Light gray background
        } else {
            // Characteristic Cell
            let characteristics = selectedDevice.characteristics[service] ?? []
            let characteristic = characteristics[indexPath.row - 1] // row 0 is service cell
            
            let propertiesText = getCharacteristicProperties(characteristic)
            let serviceSuffix = String(service.uuid.uuidString.suffix(4))
            cell.textLabel?.text = "Characteristic: \(characteristic.uuid.uuidString) \(propertiesText) (\(serviceSuffix))"
            
            if let characteristicName = knownCharacteristics[characteristic.uuid.uuidString] {
                cell.detailTextLabel?.text = "🛠 \(characteristicName)"
            } else {
                cell.detailTextLabel?.text = ""
            }
            
            // Set a slightly smaller font for characteristics.
            cell.textLabel?.font = UIFont.systemFont(ofSize: 14)
            
            // Mark TX characteristics with a light green background.
            if writeCharacteristics.contains(where: { $0 === characteristic }) {
                cell.backgroundColor = UIColor(red: 0.9, green: 1.0, blue: 0.9, alpha: 1.0)
            } else {
                cell.backgroundColor = .white
            }
            
            // If this characteristic is the one we're listening to, add a headphones emoji on the right.
            if let rx = rxCharacteristic, rx === characteristic {
                let emojiLabel = UILabel()
                emojiLabel.text = "🎧"
                emojiLabel.font = UIFont.systemFont(ofSize: 18)
                emojiLabel.sizeToFit()
                cell.accessoryView = emojiLabel
            } else {
                cell.accessoryView = nil
            }
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
    
    /// Updates the listeningLabel with the currently selected rxCharacteristic.
//        private func updateListeningLabel() {
//            if let rx = rxCharacteristic {
//                // Optionally, use a friendly name lookup if available (e.g., knownCharacteristics)
//                let friendlyName = rx.uuid.uuidString  // Replace with lookup if available
//                DispatchQueue.main.async {
//                    self.listeningLabel.text = "Listening to: \(friendlyName)"
//                }
//
//            } else {
//                listeningLabel.text = "Not listening to any characteristic."
//            }
//        }

        /// Called when the listenSwitch button is tapped.
        @IBAction func listenSwitchTapped(_ sender: UIButton) {
            // Gather all eligible characteristics for notifications from all services.
            var eligibleRxChars: [CBCharacteristic] = []
            for service in selectedDevice.services {
                if let chars = selectedDevice.characteristics[service] {
                    for char in chars {
                        if char.properties.contains(.notify) || char.properties.contains(.indicate) {
                            eligibleRxChars.append(char)
                        }
                    }
                }
            }
            
            // Create an action sheet to allow the user to choose.
            let alert = UIAlertController(title: "Select Listening Characteristic", message: "Choose a characteristic for UART responses", preferredStyle: .actionSheet)
            for characteristic in eligibleRxChars {
                // Optionally, use a friendly name here as well.
                let title = characteristic.uuid.uuidString
                alert.addAction(UIAlertAction(title: title, style: .default, handler: { _ in
                    // If a different characteristic is chosen, disable notifications on the current one.
                    if let currentRx = self.rxCharacteristic, currentRx != characteristic {
                        self.selectedDevice.peripheral.setNotifyValue(false, for: currentRx)
                    }
                    self.rxCharacteristic = characteristic
                    // Enable notifications on the newly selected characteristic.
                    self.selectedDevice.peripheral.setNotifyValue(true, for: characteristic)
                    self.tableView.reloadData()
                }))
            }
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            // For iPad support, specify the source view.
            alert.popoverPresentationController?.sourceView = sender
            alert.popoverPresentationController?.sourceRect = sender.bounds
            
            // ✅ iPad Fix
            if let popoverController = alert.popoverPresentationController {
                popoverController.sourceView = sender
                popoverController.sourceRect = sender.bounds
                popoverController.permittedArrowDirections = .up
            }
            
            present(alert, animated: true, completion: nil)
        }
}

extension UITextView {
    func scrollToBottom() {
        let range = NSMakeRange(self.text.count - 1, 1)
        self.scrollRangeToVisible(range)
    }
}
