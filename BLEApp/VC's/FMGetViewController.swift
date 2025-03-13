//
//  FMGetViewController.swift
//  BLEApp
//
//  Created by Allegro on 3/13/25.
//

import UIKit
import CoreBluetooth

class FMGetViewController: UIViewController {
    
    var selectedCharacteristic: CBCharacteristic?
    var peripheral: CBPeripheral?
    var parentVC: UARTDeviceVC?
    
    private let startDatePicker = UIDatePicker()
    private let endDatePicker = UIDatePicker()
    private let dataModeSegment = UISegmentedControl(items: ["Unsent Data", "All Data"])
    private let sendButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Select Time Range"
        
        setupUI()
    }
    
    private func setupUI() {
        startDatePicker.datePickerMode = .dateAndTime
        endDatePicker.datePickerMode = .dateAndTime
        
        dataModeSegment.selectedSegmentIndex = 1
        
        sendButton.setTitle("Send Request", for: .normal)
        sendButton.addTarget(self, action: #selector(sendRequest), for: .touchUpInside)
        
        let stackView = UIStackView(arrangedSubviews: [
            createLabel(text: "Start Date:"), startDatePicker,
            createLabel(text: "End Date:"), endDatePicker,
            createLabel(text: "Data Mode:"), dataModeSegment,
            sendButton
        ])
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8)
        ])
    }
    
    private func createLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        return label
    }
    
    @objc private func sendRequest() {
        guard let characteristic = selectedCharacteristic, let peripheral = peripheral else {
            showAlert(title: "Error", message: "No characteristic selected!")
            return
        }

        let startGPS = convertToGPS(startDatePicker.date)
        let endGPS = convertToGPS(endDatePicker.date)
        let mode = dataModeSegment.selectedSegmentIndex == 1 ? "1" : "0"

        let command = "<GET, \(startGPS.week),\(startGPS.tow), \(endGPS.week),\(endGPS.tow),\(mode)>"

        if let data = command.data(using: .utf8) {
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
        }


            DispatchQueue.main.async {
                self.parentVC?.appendToResponseViewFM("🚀 Sent: \(command) ➡️ \(characteristic.uuid.uuidString)")
            }
        

        dismiss(animated: true)
    }

    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    private func convertToGPS(_ date: Date) -> (week: Int, tow: Int) {
        // Convert date to GPS Week & Time of Week (TOW) using GPS epoch (January 6, 1980)
        let gpsEpoch = Date(timeIntervalSince1970: 315964800) // GPS Epoch
        let secondsSinceGPS = Int(date.timeIntervalSince(gpsEpoch))
        let week = secondsSinceGPS / (7 * 24 * 3600)
        let tow = secondsSinceGPS % (7 * 24 * 3600)
        return (week, tow)
    }
}
