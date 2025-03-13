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

    @IBOutlet weak var getFMButton: UIButton!
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
        
//        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Info", style: .plain, target: self, action: #selector(showBLEInfo))
        
        updateConnectionStatus()
//        NotificationCenter.default.addObserver(self, selector: #selector(handleDisconnection2(_:)), name: NSNotification.Name("DeviceDisconnected"), object: nil)
        NotificationCenter.default.addObserver(
              self,
              selector: #selector(handleDisconnection2(_:)),
              name: .deviceDisconnected,
              object: nil
          )
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
             title: "ChatGPT",
             style: .plain,
             target: self,
             action: #selector(askChatGPTForIdeas)
         )
    }
    
    @IBAction func askClicked(_ sender: UIButton) {
        askChatGPTForIdeas()
    }
    
    
    @objc private func askChatGPTForIdeas() {
        let responseText = responseTextView.text ?? ""

        guard !responseText.isEmpty else {
            showAlert(title: "Error", message: "No data in the response view to analyze.")
            return
        }

        let alert = UIAlertController(title: "Analyzing...", message: "Asking AI for ideas...", preferredStyle: .alert)
        present(alert, animated: true, completion: nil)

        askChatGPT(prompt: responseText) { [weak self] result in
            DispatchQueue.main.async {
                alert.dismiss(animated: true) {
                    switch result {
                    case .success(let response):
                        self?.showAIGuessVC(with: response)
                    case .failure(let error):
                        self?.showAlert(title: "Error", message: error.localizedDescription)
                    }
                }
            }
        }
    }
    
    private func showAIGuessVC(with aiResponse: String) {
        let aiVC = AIGuessVC(nibName: "AIGuessVC", bundle: nil)

        _ = aiVC.view
        let responseParts = aiResponse.components(separatedBy: "\n\n") // Split AI response into sections
        let probableDevice = responseParts.first ?? "Unknown Device"

        aiVC.deviceTitle.text = probableDevice
        aiVC.findingsLabel.text = aiResponse // Full AI response

        // ✅ Convert AI response into structured command data
        let parsedSignals = parseUARTCommands(from: aiResponse)

        DispatchQueue.main.async {
            aiVC.possibleSignals = parsedSignals
            aiVC.signalTable.reloadData()
        }

        aiVC.modalPresentationStyle = .overCurrentContext
        aiVC.modalTransitionStyle = .crossDissolve
        present(aiVC, animated: true, completion: nil)
    }


    
//    func requestAIUARTSignals(for device: String, completion: @escaping ([[String: String]]) -> Void) {
//        // Simulated AI-generated response
//        let generatedSignals = [
//            ["Command ID": "0x01", "Function": "Request Device Status", "Description": "Requests the current status of the device, including battery level."],
//            ["Command ID": "0x10", "Function": "Unlock Device", "Description": "Sends an unlock request to the device."]
//        ]
//
//        completion(generatedSignals) // Now returns the correct format
//    }
    
    func parseUARTCommands(from response: String) -> [[String: String]] {
        var parsedCommands: [[String: String]] = []
        
        // Find the "Possible UART Commands Table" section
        guard let tableStartRange = response.range(of: "**Possible UART Commands Table:**") else {
            print("⚠️ No command table found in response")
            return []
        }
        
        let tableContent = response[tableStartRange.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Extract rows
        let tableLines = tableContent.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        // Start processing table only when headers are found
        var processingTable = false
        
        for row in tableLines {
            let cleanRow = row.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip header row dynamically
            if cleanRow.contains("| Command ID | Function") {
                processingTable = true
                continue
            }

            if processingTable {
                // Split by '|' and remove empty elements
                let columns = cleanRow.components(separatedBy: "|")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
                
                // Ensure we get 4 columns (Command ID, Function, Description, HEX Data)
                if columns.count == 4 {
                    let commandDict: [String: String] = [
                        "Command ID": columns[0],
                        "Function": columns[1],
                        "Description": columns[2],
                        "HEX Data": columns[3] // New column added
                    ]
                    parsedCommands.append(commandDict)
                }
            }
        }
        
        if parsedCommands.isEmpty {
            print("⚠️ No commands were extracted from the table. Check AI response formatting.")
        } else {
            print("✅ Extracted \(parsedCommands.count) commands.")
        }
        
        return parsedCommands
    }



    
//    private func requestAIUARTSignals(for deviceName: String, completion: @escaping ([String]) -> Void) {
//        let prompt = """
//        Given that this is a \(deviceName), what common UART commands or AT commands can be sent to it?
//        List them as bullet points with short descriptions.
//        """
//
//        askChatGPT(prompt: prompt) { result in
//            switch result {
//            case .success(let response):
//                let signals = response.components(separatedBy: "\n").filter { !$0.isEmpty }
//                completion(signals)
//            case .failure:
//                completion(["No AI-generated signals found."])
//            }
//        }
//    }
    
    func appendToResponseViewFM(_ message: String) {
        DispatchQueue.main.async {
            self.responseTextView.text.append("\n\(message)")
            let range = NSMakeRange(self.responseTextView.text.count - 1, 1)
            self.responseTextView.scrollRangeToVisible(range)
        }
    }
 

    private func askChatGPT(prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        
        let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""

        let url = URL(string: "https://api.openai.com/v1/chat/completions")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let fullPrompt = """
        You are a highly knowledgeable assistant specializing in analyzing BLE (Bluetooth Low Energy) UART communication logs.

        Your task is to:
        1. **Identify the type of device** based purely on the provided UART log.
        2. **Extract relevant characteristics and values** based on known BLE GATT characteristics (e.g., battery level, firmware, manufacturer, serial number).
        3. **Suggest only commands that match the detected device type** (e.g., audio controls for headphones, unlock commands for smart locks).
        4. **Return a structured table listing all possible commands**, including:
           - **Command ID** (e.g., `0x10`)
           - **Function** (e.g., `Unlock Device`)
           - **Description** (e.g., `Sends an unlock request to the device`)
           - **HEX Data (if applicable)**

        Provide UART commands only if they are clearly related to the identified device. Avoid making assumptions beyond the data provided.

        Here is the UART communication log to analyze:
        
        ```
        \(prompt)
        ```

        Return the response in the following format:
        - **Device Type:** (Detected device type)
        - **Extracted Characteristics:**
          - [Characteristic Name]: [Value]
          - [Characteristic Name]: [Value]
        - **Possible UART Commands Table:**

        | Command ID | Function | Description | HEX Data |
        |------------|----------|-------------|----------|
        | 0x01       | Request Device Status | Requests device health and battery | 64 |
        | 0x02       | Request Serial Number | Retrieves the device serial number | 53 4E ... |
        | 0x03       | Request Manufacturer | Retrieves manufacturer info | 53 63 69 ... |
        | 0x10       | Unlock Device | Sends an unlock request to the device | 00 00 00 |
        | 0x11       | Lock Device | Sends a lock request | 00 00 00 |
        | 0x12       | Get Last Unlock Record | Retrieves last unlock attempt | --- |
        | 0x20       | Register RFID Card | Registers a new RFID card | 53 4E ... |
        | 0x21       | Delete RFID Card | Removes an RFID card from memory | --- |
        | 0x22       | List Registered RFID Cards | Retrieves stored RFID cards | --- |
        | 0x30       | Request Remote Unlock Code | Generates a one-time unlock code | --- |
        | 0x31       | Validate Unlock Request | Verifies an unlock attempt | --- |
        | 0x32       | Sync Time with Device | Synchronizes lock time with phone | --- |
        | 0x40       | Retrieve Unlock History | Gets unlock history logs | --- |
        | 0x41       | Clear Unlock Logs | Erases all unlock logs | --- |

        Please provide all **possible UART commands**, even if they are inferred based on known BLE device communication patterns.
        
        If the device type is unclear, state:
        "Unknown BLE device. Based on the available data, I cannot determine the exact type. Please provide additional details or check manufacturer documentation."
        """

        let requestBody: [String: Any] = [
            "model": "gpt-4-turbo",  // Use GPT-4 turbo for best results
            "messages": [
                ["role": "system", "content": "You are a helpful assistant that identifies BLE devices based on their UART communication logs."],
                ["role": "user", "content": fullPrompt]
            ],
            "max_tokens": 250, // Increase response size
            "temperature": 0.2 // Make responses more consistent
        ]

        guard let httpBody = try? JSONSerialization.data(withJSONObject: requestBody, options: []) else {
            completion(.failure(NSError(domain: "Invalid request body", code: -1, userInfo: nil)))
            return
        }
        request.httpBody = httpBody

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data received", code: -1, userInfo: nil)))
                return
            }
            
            // Debug: Print the raw response
            if let rawResponse = String(data: data, encoding: .utf8) {
                print("Raw API Response sap13: \(rawResponse)")
            }
            
            // Parse the response
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let choices = json["choices"] as? [[String: Any]],
                       let firstChoice = choices.first,
                       let message = firstChoice["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        completion(.success(content))
                    } else {
                        completion(.failure(NSError(domain: "Invalid response format", code: -1, userInfo: nil)))
                    }
                } else {
                    completion(.failure(NSError(domain: "Invalid JSON format", code: -1, userInfo: nil)))
                }
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }

        private func showAlert(title: String, message: String) {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
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
            handleDisconnection()
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
    
    @IBAction func getFMButtonTapped(_ sender: UIButton) {
        guard !writeCharacteristics.isEmpty else {
            showAlert(title: "Error", message: "No writable characteristics found!")
            return
        }
        
        if writeCharacteristics.count == 1 {
            openFMGetViewController(with: writeCharacteristics.first!)
        } else {
            let alert = UIAlertController(title: "Select TX Characteristic", message: "Multiple writable characteristics found.", preferredStyle: .actionSheet)

            for characteristic in writeCharacteristics {
                alert.addAction(UIAlertAction(title: characteristic.uuid.uuidString, style: .default, handler: { _ in
                    self.openFMGetViewController(with: characteristic)
                }))
            }

            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(alert, animated: true)
        }
    }

    private func openFMGetViewController(with characteristic: CBCharacteristic) {
        let fmVC = FMGetViewController()
        fmVC.selectedCharacteristic = characteristic
        fmVC.parentVC = self
        fmVC.peripheral = selectedDevice.peripheral
        fmVC.modalPresentationStyle = .formSheet
        present(fmVC, animated: true)
    }

}

extension UITextView {
    func scrollToBottom() {
        let range = NSMakeRange(self.text.count - 1, 1)
        self.scrollRangeToVisible(range)
    }
}
