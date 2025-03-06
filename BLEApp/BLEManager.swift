//
//  BLEManager.swift
//  BLEApp
//
//  Created by Allegro on 2/21/25.
//

import CoreBluetooth
import ExternalAccessory
import UIKit

protocol BLEManagerDelegate: AnyObject {
    func didUpdateDevices(devices: [BLEDevice])
}

extension Notification.Name {
    static let deviceDisconnected = Notification.Name("DeviceDisconnected")
}

class BLEManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {

    var centralManager: CBCentralManager!
    var discoveredDevices: [BLEDevice] = []
    var connectedDevices: [BLEDevice] = []
    var classicDevices: [EAAccessory] = []

    weak var delegate: BLEManagerDelegate?
    
    var autoConnectDevices: [UUID] {
        get {
            let storedUUIDs = UserDefaults.standard.array(forKey: "AutoConnectDevices") as? [String] ?? []
            return storedUUIDs.compactMap { UUID(uuidString: $0) }
        }
        set {
            let uuidStrings = newValue.map { $0.uuidString }
            UserDefaults.standard.set(uuidStrings, forKey: "AutoConnectDevices")
        }
    }

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.global(qos: .background))
        classicDevices = EAAccessoryManager.shared().connectedAccessories
    }
    
    func getClassicDevice(named deviceName: String) -> EAAccessory? {
        return classicDevices.first { $0.name == deviceName }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            print("Bluetooth is ON. Scanning for devices...")
            centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
            
            classicDevices = EAAccessoryManager.shared().connectedAccessories // ✅ Refresh Bluetooth Classic devices

            // ✅ Attempt to Auto-Connect to saved devices
            autoReconnectDevices()

        } else {
            print("Bluetooth is not available")
        }
    }
    
    // Auto-Connect logic

    func autoReconnectDevices() {
        for deviceUUID in autoConnectDevices {
            if let device = discoveredDevices.first(where: { $0.peripheral.identifier == deviceUUID }) {
                if !connectedDevices.contains(where: { $0.peripheral.identifier == deviceUUID }) {
                    print("🔄 Auto-connecting to \(device.peripheral.name ?? "Unknown Device")...")
                    centralManager.connect(device.peripheral, options: nil)
                }
            }
        }
    }

    func addToAutoConnect(_ device: BLEDevice) {
        if !autoConnectDevices.contains(device.peripheral.identifier) {
            autoConnectDevices.append(device.peripheral.identifier)
        }
    }

    func removeFromAutoConnect(_ device: BLEDevice) {
        autoConnectDevices.removeAll { $0 == device.peripheral.identifier }
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
        
        // ✅ Auto-connect if the device is saved in UserDefaults
           if autoConnectDevices.contains(peripheral.identifier) {
               print("✅ Found Auto-Connect Device: \(peripheral.name ?? "Unknown"), attempting connection...")
               centralManager.connect(peripheral, options: nil)
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

        if Thread.isMainThread {
            self.delegate?.didUpdateDevices(devices: self.discoveredDevices)
        } else {
            DispatchQueue.main.async {
                self.delegate?.didUpdateDevices(devices: self.discoveredDevices)
            }
        }
        
        peripheral.discoverServices(nil)  // Discover all services
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("❌ Disconnected from \(peripheral.name ?? "Unknown Device")")
        
        // ✅ Remove the device from connected devices list
        connectedDevices.removeAll { $0.peripheral.identifier == peripheral.identifier }
        
        NotificationCenter.default.post(
               name: .deviceDisconnected,
               object: nil,
               userInfo: ["peripheral": peripheral]
           )

        
        // ✅ If the device is in the auto-connect list, attempt reconnect
        if autoConnectDevices.contains(peripheral.identifier) {
            print("🔄 Attempting to reconnect to \(peripheral.name ?? "Unknown Device") in 3 seconds...")
            DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
                self.centralManager.connect(peripheral, options: nil)
            }
        }
        
        DispatchQueue.main.async {
            self.delegate?.didUpdateDevices(devices: self.discoveredDevices)
        }
    }
    
//    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
//        print("❌ Disconnected from \(peripheral.name ?? "Unknown Device")")
//
//        // ✅ Attempt Reconnection Before Removing from `connectedDevices`
//        if shouldReconnect(to: peripheral) {
//            print("🔄 Attempting to reconnect to \(peripheral.name ?? "Unknown Device")...")
//
//            DispatchQueue.global().asyncAfter(deadline: .now() + 1) { // Wait 1 second before retrying
//                self.centralManager.connect(peripheral, options: nil)
//            }
//        } else {
//            // ✅ Remove if we are NOT reconnecting
//            connectedDevices.removeAll { $0.peripheral.identifier == peripheral.identifier }
//            print("🛑 Removed \(peripheral.name ?? "Unknown Device") from connectedDevices")
//        }
//
//        DispatchQueue.main.async {
//            self.delegate?.didUpdateDevices(devices: self.discoveredDevices)
//        }
//    }

    private func shouldReconnect(to peripheral: CBPeripheral) -> Bool {
        return discoveredDevices.contains(where: { $0.peripheral.identifier == peripheral.identifier })
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("🔹 [BLEManager] Services discovered for \(peripheral.name ?? "Unknown")")

        
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

extension BLEManager {
    func connectDevice(peripheral: CBPeripheral) {
        centralManager.connect(peripheral, options: nil)
    }

    func disconnectDevice(peripheral: CBPeripheral) {
        centralManager.cancelPeripheralConnection(peripheral)
    }
}
