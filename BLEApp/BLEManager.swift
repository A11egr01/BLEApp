//
//  BLEManager.swift
//  BLEApp
//
//  Created by Allegro on 2/21/25.
//

import CoreBluetooth
import UIKit

protocol BLEManagerDelegate: AnyObject {
    func didUpdateDevices(devices: [BLEDevice])
}

class BLEManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {

    var centralManager: CBCentralManager!
    var discoveredDevices: [BLEDevice] = []
    var connectedDevices: [BLEDevice] = []
    weak var delegate: BLEManagerDelegate?

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.global(qos: .background))
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            print("Bluetooth is ON. Scanning for devices...")
            centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        } else {
            print("Bluetooth is not available")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        
        var manufacturerName = "Unknown Manufacturer"
        var manufacturerCode = "N/A"

        // ✅ Extract Manufacturer Data (First 2 bytes = Manufacturer ID)
        if let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data {
            manufacturerCode = manufacturerData.prefix(2).map { String(format: "%02X", $0) }.joined(separator: " ")
            manufacturerName = knownManufacturers[manufacturerCode] ?? "Unknown Manufacturer"
        }

        // ✅ Check if it's an Apple device (AirPods, Beats, etc.)
        if manufacturerCode == "4C 00" {
            print("🎧 Apple AirPods nearby! Device: \(peripheral.name ?? "Unknown")")
        }

        // ✅ Check for an existing device in the list
        if let existingDevice = discoveredDevices.first(where: { $0.peripheral.identifier == peripheral.identifier }) {
            existingDevice.rssi = RSSI
            existingDevice.advertisementData = advertisementData
        } else {
            let newDevice = BLEDevice(
                peripheral: peripheral,
                rssi: RSSI,
                manufacturer: manufacturerName,
                manufacturerCode: manufacturerCode,
                advertisementData: advertisementData
            )
            discoveredDevices.append(newDevice)

            // ✅ Start connecting to fetch services for known devices
            centralManager.connect(peripheral, options: nil)
            peripheral.delegate = self
            
        }

        DispatchQueue.main.async {
            self.delegate?.didUpdateDevices(devices: self.discoveredDevices)
        }
    }

    
    func findLostDevice(peripheral: CBPeripheral, characteristic: CBCharacteristic) {
        let findMeCommand: [UInt8] = [0x01]  // Example: 0x01 = "Beep"
        let data = Data(findMeCommand)
        
        if characteristic.properties.contains(.write) {
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
            print("🔔 Sent 'Find Me' command to \(peripheral.name ?? "Device")")
        }
    }

    // ✅ Stops BLE scanning
    func stopScanning() {
        if centralManager.isScanning {
            centralManager.stopScan()
            print("🛑 Stopped scanning for BLE devices.")
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("✅ Connected to \(peripheral.name ?? "Unknown Device")")
        
        if let device = discoveredDevices.first(where: { $0.peripheral.identifier == peripheral.identifier }) {
            connectedDevices.append(device)
        }

        DispatchQueue.main.async {
            self.delegate?.didUpdateDevices(devices: self.discoveredDevices)
        }
        
        peripheral.discoverServices(nil)  // Discover all services
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
         print("❌ Disconnected from \(peripheral.name ?? "Unknown Device")")

         // ✅ Remove the device from connected devices list
         connectedDevices.removeAll { $0.peripheral.identifier == peripheral.identifier }

         DispatchQueue.main.async {
             self.delegate?.didUpdateDevices(devices: self.discoveredDevices)
         }
     }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("❌ Error discovering services: \(error)")
            return
        }

        guard let device = discoveredDevices.first(where: { $0.peripheral.identifier == peripheral.identifier }) else { return }

        if let discoveredServices = peripheral.services {
            device.services = discoveredServices
            print("🔍 Services found: \(discoveredServices.map { $0.uuid.uuidString })")

            for service in discoveredServices {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
        
        DispatchQueue.main.async {
            self.delegate?.didUpdateDevices(devices: self.discoveredDevices)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("❌ Error discovering characteristics: \(error)")
            return
        }

        guard let device = discoveredDevices.first(where: { $0.peripheral.identifier == peripheral.identifier }) else { return }

        if let characteristics = service.characteristics {
            device.addCharacteristics(for: service, characteristics: characteristics)
            print("🔍 Characteristics for \(service.uuid): \(characteristics.map { $0.uuid.uuidString })")
        }

        DispatchQueue.main.async {
            self.delegate?.didUpdateDevices(devices: self.discoveredDevices)
        }
    }
}

