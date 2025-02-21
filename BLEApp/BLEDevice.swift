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
    
    var batteryLevel: Int?  // ✅ Battery Level (0-100%)


    init(peripheral: CBPeripheral, rssi: NSNumber, manufacturer: String, manufacturerCode: String, advertisementData: [String: Any]) {
        self.peripheral = peripheral
        self.rssi = rssi
        self.manufacturer = manufacturer
        self.manufacturerCode = manufacturerCode
        self.advertisementData = advertisementData
    }
    
    // Helper to store discovered characteristics for a service
    func addCharacteristics(for service: CBService, characteristics: [CBCharacteristic]) {
        self.characteristics[service] = characteristics
    }
}
