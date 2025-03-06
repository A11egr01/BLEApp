//
//  BLEDevice.swift
//  BLEApp
//
//  Created by Allegro on 2/21/25.
//

import CoreBluetooth
import ExternalAccessory

class FM12Device {
    var accessory: EAAccessory  
    
    init(accessory: EAAccessory) {
        self.accessory = accessory
    }
    
    var name: String {
        return accessory.name
    }
}

class BLEDevice {
//    var accessory: EAAccessory? // For Bluetooth Classic
    var peripheral: CBPeripheral // For BLE
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

    // Initializer for BLE devices
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
    
    // Initializer for Bluetooth Classic devices
//    init(accessory: EAAccessory) {
//        self.accessory = accessory
//    }
    
    // Helper to store discovered characteristics for a service
    func addCharacteristics(for service: CBService, characteristics: [CBCharacteristic]) {
        self.characteristics[service] = characteristics
    }
}

