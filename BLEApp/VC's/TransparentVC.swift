//
//  TransparentVC.swift
//  BLEApp
//
//  Created by Allegro on 3/5/25.
//

import UIKit
import ExternalAccessory

class TransparentVC: UIViewController {

    var selectedDevice: BLEDevice!
    var session: EASession?

    @IBOutlet weak var updatesLabel: UILabel!
    @IBOutlet weak var inputField: UITextField!
    @IBOutlet weak var responseView: UITextView!
    @IBOutlet weak var sendCommand: UIButton!
    
    override func viewDidLoad() {
            super.viewDidLoad()
            
            // Set up the send button
            sendCommand.addTarget(self, action: #selector(sendCommandTapped), for: .touchUpInside)
            
            // Connect to the selected device
            connectToDevice()
        }

        func connectToDevice() {
            guard let accessory = selectedDevice.accessory else {
                updatesLabel.text = "Device not connected."
                return
            }
            
            // Create a session with the selected device
            session = EASession(accessory: accessory, forProtocol: "com.microchip.spp")
            
            if session != nil {
                updatesLabel.text = "Connected to device!"
                startCommunication()
            } else {
                updatesLabel.text = "Failed to connect."
            }
        }

        func startCommunication() {
            guard let session = session else { return }

            let inputStream = session.inputStream
            let outputStream = session.outputStream

            // Open streams
            inputStream.open()
            outputStream.open()

            // Set up a timer to read data periodically
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                self.readData(from: inputStream)
            }
        }

        func readData(from inputStream: InputStream) {
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 1024)
            let bytesRead = inputStream.read(buffer, maxLength: 1024)
            
            if bytesRead > 0 {
                let receivedData = Data(bytes: buffer, count: bytesRead)
                let receivedText = String(data: receivedData, encoding: .utf8) ?? "Invalid data"
                
                // Update the UI on the main thread
                DispatchQueue.main.async {
                    self.responseView.text += "Received: \(receivedText)\n"
                }
            }
            
            buffer.deallocate()
        }

        @objc func sendCommandTapped() {
            guard let text = inputField.text, !text.isEmpty,
                  let data = text.data(using: .utf8),
                  let outputStream = session?.outputStream else {
                return
            }
            
            // Send data to the device
            outputStream.write(data)
            inputField.text = "" // Clear the input field
        }
    }
