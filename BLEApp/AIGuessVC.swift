//
//  AIGuessVC.swift
//  BLEApp
//
//  Created by Allegro on 3/3/25.
//

import UIKit

class AIGuessVC: UIViewController, UITableViewDataSource, UITableViewDelegate {

    
    @IBOutlet weak var findingsLabel: UITextView!
    @IBOutlet weak var deviceTitle: UILabel!
    @IBOutlet weak var signalTable: UITableView!
    
//    var signalTable: UITableView!
        
        var possibleSignals: [[String: String]] = []

        override func viewDidLoad() {
            super.viewDidLoad()
            
            // Make background partially transparent
            view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            
            // Initialize TableView programmatically
//            signalTable = UITableView()
            signalTable.translatesAutoresizingMaskIntoConstraints = false
            signalTable.dataSource = self
            signalTable.delegate = self
            signalTable.backgroundColor = .clear
            signalTable.separatorStyle = .none
            signalTable.rowHeight = UITableView.automaticDimension
            signalTable.estimatedRowHeight = 80
            signalTable.register(SignalCell.self, forCellReuseIdentifier: "SignalCell")
            
            // Add TableView to view
//            view.addSubview(signalTable)
            
            // Auto Layout Constraints for TableView
//            NSLayoutConstraint.activate([
//                signalTable.topAnchor.constraint(equalTo: deviceTitle.bottomAnchor, constant: 10),
//                signalTable.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 15),
//                signalTable.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
//                signalTable.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20)
//            ])
            
            // Example Data
//            possibleSignals = [
//                ["Command ID": "0x01", "Function": "Request Device Status", "Description": "Requests the current status of the device, including battery level and connection state."],
//                ["Command ID": "0x02", "Function": "Request Serial Number", "Description": "Retrieves the serial number of the device for identification."],
//                ["Command ID": "0x10", "Function": "Unlock Device", "Description": "Sends an unlock request to the device."],
//                ["Command ID": "0x11", "Function": "Lock Device", "Description": "Sends a lock request to the device."],
//                ["Command ID": "0x20", "Function": "Register RFID Card", "Description": "Registers a new RFID card for access control."],
//                ["Command ID": "0x22", "Function": "List Registered RFID Cards", "Description": "Retrieves a list of all registered RFID cards."],
//                ["Command ID": "0x30", "Function": "Request Remote Unlock Code", "Description": "Requests a one-time unlock code from the cloud or mobile app."]
//            ]
            signalTable.reloadData()
        }

        // MARK: - TableView DataSource
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return possibleSignals.count
        }

        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "SignalCell", for: indexPath) as? SignalCell else {
                return UITableViewCell()
            }

            let command = possibleSignals[indexPath.row]
            cell.configure(with: command)

            return cell
        }

        @IBAction func closeButtonTapped(_ sender: UIButton) {
            dismiss(animated: true, completion: nil)
        }
    }
