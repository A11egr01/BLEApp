//
//  BLEDevice.swift
//  BLEApp
//
//  Created by Allegro on 2/21/25.
//

import CoreBluetooth

class BLEDevice {
    var peripheral: CBPeripheral
    var rssi: NSNumber
    var manufacturer: String
    var manufacturerCode: String
    var advertisementData: [String: Any]
    var services: [CBService] = []  // Stores discovered services
    var characteristics: [CBService: [CBCharacteristic]] = [:]  // Maps each service to its characteristics
    var uart = false
    var batteryLevel: Int?  // ✅ Battery Level (0-100%)
    var readValues: [CBUUID: String] = [:]  // ✅ Stores read characteristic values
    var lastSeenTimestamp: TimeInterval?  // ✅ Store kCBAdvDataTimestamp

    init(peripheral: CBPeripheral, rssi: NSNumber, manufacturer: String, manufacturerCode: String, advertisementData: [String: Any]) {
        self.peripheral = peripheral
        self.rssi = rssi
        self.manufacturer = manufacturer
        self.manufacturerCode = manufacturerCode
        self.advertisementData = advertisementData
        
        if let timestamp = advertisementData["kCBAdvDataTimestamp"] as? TimeInterval {
            self.lastSeenTimestamp = timestamp
        }
    }
    
    // Helper to store discovered characteristics for a service
    func addCharacteristics(for service: CBService, characteristics: [CBCharacteristic]) {
        self.characteristics[service] = characteristics
    }
    
}
