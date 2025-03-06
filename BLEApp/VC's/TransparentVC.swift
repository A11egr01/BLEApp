//
//  TransparentVC.swift
//  BLEApp
//
//  Created by Allegro on 3/5/25.
//

import UIKit
import ExternalAccessory

class TransparentVC: UIViewController, StreamDelegate {

    var selectedDevice: FM12Device!
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
            let accessory = selectedDevice.accessory
            
            // ✅ Ensure the protocol name matches your device's supported protocols
            session = EASession(accessory: accessory, forProtocol: "com.microchip.spp")

            if let session = session {
                updatesLabel.text = "✅ Connected to device!"
                startCommunication(session: session)
            } else {
                updatesLabel.text = "❌ Failed to connect."
            }
        }

        func startCommunication(session: EASession) {
            guard let inputStream = session.inputStream, let outputStream = session.outputStream else {
                updatesLabel.text = "❌ Failed to initialize streams."
                return
            }

            // ✅ Set delegates
            inputStream.delegate = self
            outputStream.delegate = self

            // ✅ Schedule and open streams
            inputStream.schedule(in: .current, forMode: .default)
            outputStream.schedule(in: .current, forMode: .default)
            inputStream.open()
            outputStream.open()

            print("📡 Streams opened for communication.")
        }

        func readData(from inputStream: InputStream) {
            let bufferSize = 1024
            var buffer = [UInt8](repeating: 0, count: bufferSize)

            while inputStream.hasBytesAvailable {
                let bytesRead = inputStream.read(&buffer, maxLength: bufferSize)
                if bytesRead > 0 {
                    let receivedData = Data(buffer.prefix(bytesRead))
                    let receivedText = String(data: receivedData, encoding: .utf8) ?? "Invalid data"
                    
                    // ✅ Update the UI on the main thread
                    DispatchQueue.main.async {
                        self.responseView.text += "\n📡 Received: \(receivedText)"
                        self.responseView.scrollRangeToVisible(NSMakeRange(self.responseView.text.count - 1, 1))
                    }
                }
            }
        }

        @objc func sendCommandTapped() {
            guard let text = inputField.text, !text.isEmpty,
                  let data = text.data(using: .utf8),
                  let outputStream = session?.outputStream else {
                return
            }
            
            // ✅ Send data to the device
            data.withUnsafeBytes { buffer in
                let bytesWritten = outputStream.write(buffer.bindMemory(to: UInt8.self).baseAddress!, maxLength: data.count)
                if bytesWritten > 0 {
                    print("🚀 Sent: \(text)")
                } else {
                    print("❌ Failed to send data")
                }
            }
            
            inputField.text = "" // ✅ Clear the input field
        }

        // ✅ Handle Stream Events
        func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
            switch eventCode {
            case .hasBytesAvailable:
                if aStream == session?.inputStream {
                    readData(from: aStream as! InputStream)
                }
            case .errorOccurred:
                print("❌ Stream error occurred")
            case .endEncountered:
                print("ℹ️ Stream ended")
            default:
                break
            }
        }
    }
