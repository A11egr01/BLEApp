//
//  BLEInfoVC.swift
//  BLEApp
//
//  Created by Allegro on 2/23/25.
//

import UIKit

class BLEInfoVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    let tableView = UITableView()
    
    let emojiMapping: [String: String] = [
        "2A19": "🔋 Battery Level",
        "2A37": "❤️ Heart Rate Measurement",
        "2A6E": "🌡 Temperature Measurement",
        "2A98": "💪 Weight Measurement",
        "2A9D": "🏃‍♂️ Step Counter",
        "2A56": "💨 Humidity",
        "2A58": "⏳ Time Stamp",
        "2A6D": "☀️ Light Intensity",
        "2A05": "🚨 Immediate Alert",
        "2A69": "🧭 Location",
        "2A76": "⚡️ Power Control",
        "2A2A": "🔐 Security",
        "2A63": "💉 Blood Pressure",
        "2A9E": "🦶 Step Counter",
        "2A29": "🏭 Manufacturer Name",
        "2A26": "📦 Firmware Revision",
        "2A27": "🔄 Hardware Revision",
        "2A28": "🖥 Software Revision",
        "2A24": "📋 Model Number",
        "2A25": "🔖 Serial Number",
        "2A00": "🏷 Device Name",
        "2A01": "📏 Appearance",
        "2A04": "📶 Connection Parameters",
        "2A03": "🔑 Reconnection Address",
        "2A06": "🔔 Alert Level",
        "2A08": "⏰ Date & Time",
        "2A0D": "🚴‍♂️ Cycling Power",
        "2A4D": "🎤 Audio Input",
        "2A4E": "🔈 Audio Output",
        "2A7E": "🏋️ Fitness Control",
        "2A1C": "🫁 Respiratory Rate",
        "2A40": "📡 Location Speed",
        "2A46": "📳 Alert Notification",
        "2A80": "👤 User Profile",
        "2A85": "🔘 Button Pressed",
        "2A90": "👂 Hearing Aid",
        "2A99": "🦵 Body Composition",
        "2AA7": "🧠 Cognitive Function",
        "2AA9": "🎮 Game Controller",
        "2ACD": "🎛 Control Point"
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "BLE Characteristic Info"
        view.backgroundColor = .white
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.frame = view.bounds
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        view.addSubview(tableView)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissScreen))
    }
    
    @objc func dismissScreen() {
        dismiss(animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return emojiMapping.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let key = Array(emojiMapping.keys)[indexPath.row]
        let value = emojiMapping[key] ?? "Unknown"
        cell.textLabel?.text = "\(key): \(value)"
        return cell
    }
}
