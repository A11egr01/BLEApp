//
//  BLEManager.swift
//  BLEApp
//
//  Created by Allegro on 2/21/25.
//

import CoreBluetooth
import UIKit

protocol BLEManagerDelegate: AnyObject {
    // Home page updates
    func didUpdateDevices(devices: [BLEDevice])
    
    // UART Device updates
    func didDiscoverServices(for peripheral: CBPeripheral, services: [CBService])
    func didDiscoverCharacteristics(for peripheral: CBPeripheral, characteristics: [CBCharacteristic])
    func didReceiveData(from characteristic: CBCharacteristic, data: String)
    func didReceiveDataError(_ errorMessage: String)
    func didUpdateBatteryLevel(for peripheral: CBPeripheral, level: Int)
    func didUpdateListeningCharacteristic(_ characteristic: CBCharacteristic?)
    func didDisconnectDevice(_ peripheral: CBPeripheral)
    
    func didStartRefreshingBLEData(for peripheral: CBPeripheral)
    func didFinishRefreshingBLEData(for peripheral: CBPeripheral)
    func didUpdateWritableCharacteristics(hasWritable: Bool)
}

class BLEManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {

    var centralManager: CBCentralManager!
    var discoveredDevices: [BLEDevice] = []
    var connectedDevices: [BLEDevice] = []
    var delegates = NSHashTable<AnyObject>.weakObjects() // ✅ Supports multiple delegates
    static let shared = BLEManager()
    
    var writeCharacteristics: [CBCharacteristic] = []
    var txCharacteristic: CBCharacteristic?
    var rxCharacteristic: CBCharacteristic? {
        didSet {
            notifyDelegates { $0.didUpdateListeningCharacteristic(rxCharacteristic) }
        }
    }

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
    
    func addDelegate(_ delegate: BLEManagerDelegate) {
          if !delegates.contains(delegate) {
              delegates.add(delegate)
          }
      }

      // ✅ Remove delegate
      func removeDelegate(_ delegate: BLEManagerDelegate) {
          delegates.remove(delegate)
      }

      // ✅ Notify all delegates
      private func notifyDelegates(_ action: (BLEManagerDelegate) -> Void) {
          for delegate in delegates.allObjects {
              if let delegate = delegate as? BLEManagerDelegate {
                  action(delegate)
              }
          }
      }

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.global(qos: .background))
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            print("Bluetooth is ON. Scanning for devices...")
            centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
            
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
            self.notifyDelegates { $0.didUpdateDevices(devices: self.discoveredDevices) }
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
            self.notifyDelegates { $0.didUpdateDevices(devices: self.discoveredDevices) }
        } else {
            DispatchQueue.main.async {
                self.notifyDelegates { $0.didUpdateDevices(devices: self.discoveredDevices) }
            }
        }
        
        peripheral.discoverServices(nil)  // Discover all services
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("❌ Disconnected from \(peripheral.name ?? "Unknown Device")")
        
        // ✅ Remove the device from connected devices list
        connectedDevices.removeAll { $0.peripheral.identifier == peripheral.identifier }
        
        // ✅ If the device is in the auto-connect list, attempt reconnect
        if autoConnectDevices.contains(peripheral.identifier) {
            print("🔄 Attempting to reconnect to \(peripheral.name ?? "Unknown Device") in 3 seconds...")
            DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
                self.centralManager.connect(peripheral, options: nil)
            }
        }
        
        DispatchQueue.main.async {
            self.notifyDelegates { $0.didUpdateDevices(devices: self.discoveredDevices) }
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
        guard let services = peripheral.services else { return }

//        DispatchQueue.main.async {
            self.notifyDelegates { $0.didDiscoverServices(for: peripheral, services: services) }
//        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("❌ Error discovering characteristics: \(error)")
            return
        }

        // ✅ Find the corresponding device
        guard let device = discoveredDevices.first(where: { $0.peripheral.identifier == peripheral.identifier }) else { return }

        // ✅ Store characteristics in the device
        if let characteristics = service.characteristics {
            device.addCharacteristics(for: service, characteristics: characteristics)
            print("🔍 Characteristics for \(service.uuid): \(characteristics.map { $0.uuid.uuidString })")
        }

        guard let characteristics = service.characteristics else { return }
        writeCharacteristics.removeAll()
        var hasWritable = false  // ✅ Track if writable characteristics exist

        // ✅ Prepare lists for writable & notifiable characteristics
        var eligibleRxChars: [CBCharacteristic] = []

        for characteristic in characteristics {
            let foundMessage = "🔍 Found Characteristic: \(characteristic.uuid.uuidString)"
            print(foundMessage)

            // ✅ Prevent duplicates in writeCharacteristics
            if (characteristic.properties.contains(.writeWithoutResponse) || characteristic.properties.contains(.write)),
               !writeCharacteristics.contains(where: { $0.uuid == characteristic.uuid }) {
                writeCharacteristics.append(characteristic)
                let txMessage = "✅ Writable Characteristic: \(characteristic.uuid.uuidString)"
                print(txMessage)
            }

            // ✅ Prevent duplicates in eligibleRxChars
            if (characteristic.properties.contains(.notify) || characteristic.properties.contains(.indicate)),
               !eligibleRxChars.contains(where: { $0.uuid == characteristic.uuid }) {
                eligibleRxChars.append(characteristic)
            }

            // ✅ If readable, request a read
            if characteristic.properties.contains(.read) {
                print("📖 Requesting read for characteristic \(characteristic.uuid.uuidString)...")
                peripheral.readValue(for: characteristic)
            }
        }

        
        // ✅ Ensure `rxCharacteristic` is only set once
        if rxCharacteristic == nil, let firstEligible = eligibleRxChars.first {
            rxCharacteristic = firstEligible
            peripheral.setNotifyValue(true, for: firstEligible)
            let rxMessage = "✅ RX Characteristic Enabled: \(firstEligible.uuid.uuidString)"
            print(rxMessage)
        }

        // ✅ Notify all delegates (UARTDeviceVC)
        notifyDelegates { $0.didUpdateWritableCharacteristics(hasWritable: !writeCharacteristics.isEmpty) }

        notifyDelegates { $0.didDiscoverCharacteristics(for: peripheral, characteristics: characteristics) }
    }

    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            let errorMessage = "❌ Data Error: \(error.localizedDescription)"
            print(errorMessage)
            
            // Notify delegates about the error
            notifyDelegates { $0.didReceiveDataError(errorMessage) }
            return
        }

        guard let data = characteristic.value else { return }

        var translatedData = translateCharacteristicValue(data: data)

        // ✅ Check if the characteristic is Battery Level (UUID 2A19)
        if characteristic.uuid.uuidString.uppercased() == "2A19", data.count == 1 {
            let batteryLevel = Int(data[0])
            print("🔋 Battery Level Updated: \(batteryLevel)%")

            // ✅ Notify delegates about the battery update
            notifyDelegates { $0.didUpdateBatteryLevel(for: peripheral, level: batteryLevel) }
            return
        }

        let hexData = data.map { String(format: "%02X", $0) }.joined(separator: " ")

        // ✅ Extract last 4 characters of UUID
        let characteristicID = String(characteristic.uuid.uuidString.suffix(4))

        // ✅ Get associated emoji for the characteristic
        let characteristicEmoji = getEmojiForCharacteristic(characteristicID)
        let readMarker = characteristic.properties.contains(.read) ? "📖" : ""

        if translatedData == hexData {
            translatedData = "RAW: "
        }

        let receivedMessage = "📡 \(characteristicEmoji) \(readMarker) [\(characteristicID)] Received: \(translatedData) (\(hexData))"
        print(receivedMessage)

        // ✅ Notify delegates about received data
        notifyDelegates { $0.didReceiveData(from: characteristic, data: receivedMessage) }
    }

    @objc func handleDisconnection(for peripheral: CBPeripheral) {
        print("🔴 Device Disconnected: \(peripheral.name ?? "Unknown")")

        // ✅ Clear stored characteristics on disconnection
        writeCharacteristics.removeAll()
        rxCharacteristic = nil
        txCharacteristic = nil
        
        // ✅ Notify delegates about the disconnection
        notifyDelegates { $0.didDisconnectDevice(peripheral) }
    }
    
    func refreshBLEData(for peripheral: CBPeripheral) {
        print("🔄 Refreshing UART Services for \(peripheral.name ?? "Unknown")...")

        // ✅ Clear stored services & characteristics in the local device list
        if let device = discoveredDevices.first(where: { $0.peripheral.identifier == peripheral.identifier }) {
            device.services.removeAll()
            device.characteristics.removeAll()
        }

        // ✅ Clear local characteristic references
        writeCharacteristics.removeAll()
        rxCharacteristic = nil
        txCharacteristic = nil

        // ✅ Request fresh service discovery
        peripheral.discoverServices(nil)

        // ✅ Notify delegates that the refresh has started
        notifyDelegates { $0.didStartRefreshingBLEData(for: peripheral) }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.notifyDelegates { $0.didFinishRefreshingBLEData(for: peripheral) }
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
