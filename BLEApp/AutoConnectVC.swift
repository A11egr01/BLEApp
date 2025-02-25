//
//  AutoConnectVC.swift
//  BLEApp
//
//  Created by Allegro on 2/25/25.
//

import UIKit

class AutoConnectVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var bleManager: BLEManager!
    var tableView = UITableView()
    var emptyLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Auto-Connect Devices"
        view.backgroundColor = .white
        setupTableView()
        setupEmptyLabel()

    }
    
    private func setupTableView() {
            tableView.frame = view.bounds
            tableView.dataSource = self
            tableView.delegate = self
            view.addSubview(tableView)
        }
        
        private func setupEmptyLabel() {
            emptyLabel.text = "No devices saved for Auto-Connect."
            emptyLabel.textColor = .gray
            emptyLabel.textAlignment = .center
            emptyLabel.numberOfLines = 0
            emptyLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
            emptyLabel.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(emptyLabel)
            
            NSLayoutConstraint.activate([
                emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
        }

        private func updateEmptyState() {
            emptyLabel.isHidden = !bleManager.autoConnectDevices.isEmpty
            tableView.isHidden = bleManager.autoConnectDevices.isEmpty
        }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        updateEmptyState()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bleManager.autoConnectDevices.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "AutoConnectCell")
        let deviceUUID = bleManager.autoConnectDevices[indexPath.row]

        let matchingDevice = bleManager.discoveredDevices.first { $0.peripheral.identifier == deviceUUID }
        cell.textLabel?.text = matchingDevice?.peripheral.name ?? "Unknown Device"
        cell.detailTextLabel?.text = deviceUUID.uuidString

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let deviceUUID = bleManager.autoConnectDevices[indexPath.row]

        let actionSheet = UIAlertController(title: "Auto-Connect Device", message: nil, preferredStyle: .actionSheet)

        actionSheet.addAction(UIAlertAction(title: "Remove from Auto-Connect", style: .destructive, handler: { _ in
            self.bleManager.autoConnectDevices.removeAll { $0 == deviceUUID }
            self.tableView.reloadData()
            self.updateEmptyState()
        }))

        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true)
    }
}
