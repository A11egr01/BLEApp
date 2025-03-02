//
//  knownManufacturers.swift
//  BLEApp
//
//  Created by Allegro on 2/21/25.
//

import Foundation
import CoreBluetooth

let knownManufacturers: [String: String] = [
    "4C 00": "Apple Inc.",             // AirPods, iPhones, MacBooks
    "2D 01": "Samsung Electronics",     // Galaxy Phones, Watches, SmartTags
    "00 1A": "Google",                  // Android devices, Google Nest
    "F0 02": "Bose Corporation",        // Bose QC35, QC45, SoundSport
    "00 0D": "Texas Instruments",       // IoT chips, industrial BLE devices
    "00 1B": "IBM",                     // IBM BLE devices
    "75 00": "Microsoft",               // Surface, Xbox controllers
    "D8 FE": "Fitbit",                  // Fitbit watches, trackers
    "00 03": "Sony",                    // PlayStation controllers, headphones
    "AC 8B": "Logitech",                // Mice, keyboards, gamepads
    "A4 C1": "Anker Innovations",       // Anker headphones, Soundcore
    "38 01": "Xiaomi",                  // Mi Band, smart devices
    "6D 62": "GoPro",                   // GoPro cameras, remote controls
    "A0 37": "Garmin",                  // Smartwatches, fitness devices
    "48 02": "Oculus VR",               // Oculus Quest, VR controllers
    "43 02": "Nintendo",                // Nintendo Switch controllers
    "D4 4E": "JBL",                     // Bluetooth speakers, headphones
    "9E 8B": "Tile Inc.",               // Tile Bluetooth trackers
    "EC FE": "OnePlus",                 // OnePlus phones, Buds
    "5A A5": "Beats by Dre",            // Beats Studio, Powerbeats
    "1A FE": "Amazon",                  // Echo devices, Alexa gadgets
]

/// 🔍 Known BLE Services and Their Names
let knownServices: [String: String] = [
    "180A": "📱 Device Information",
    "180F": "🔋 Battery Service",
    "180D": "❤️ Heart Rate Monitor",
    "1809": "🌡️ Temperature Sensor",
    "181A": "🌍 Environmental Sensor",
    "1814": "👟 Step Counter",
    "FEAA": "📍 iBeacon Service",
    "D0611E78-BBB4-4591-A5F8-487910AE4366": "🎧 AirPods Service"
]

/// 🔍 Known BLE Characteristics and Their Names
let knownCharacteristics: [String: String] = [
    "2A29": "🏭 Manufacturer Name",
    "2A24": "📦 Model Number",
    "2A25": "🔢 Serial Number",
    "2A26": "💽 Firmware Version",
    "2A27": "🛠 Hardware Version",
    "2A19": "🔋 Battery Level",
    "2A37": "❤️ Heart Rate Data",
    "2A1C": "🌡️ Body Temperature",
    "2A6E": "🌡️ Air Temperature",
    "2A67": "🏃 Speed Data",
    "2A6C": "🧭 Altitude Data",
    "2A53": "👟 Step Count",
    "2A68": "📏 Stride Length",
    "2A6B": "📍 GPS Coordinates",
    "2A07": "📡 TX Power",
    "2A00": "🎧 AirPods Name"
]

struct BLECharacteristic {
    let id: String
    let emoji: String
    let description: String
}

func getCharacteristicInfo(_ characteristicID: String) -> BLECharacteristic {
    let characteristicMapping: [String: BLECharacteristic] = [
        "2A19": BLECharacteristic(id: "2A19", emoji: "🔋", description: "Battery Level"),
        "2A37": BLECharacteristic(id: "2A37", emoji: "❤️", description: "Heart Rate Measurement"),
        "2A6E": BLECharacteristic(id: "2A6E", emoji: "🌡", description: "Temperature Measurement"),
        "2A98": BLECharacteristic(id: "2A98", emoji: "💪", description: "Weight Measurement"),
        "2A9D": BLECharacteristic(id: "2A9D", emoji: "🏃‍♂️", description: "Step Counter"),
        "2A56": BLECharacteristic(id: "2A56", emoji: "💨", description: "Humidity"),
        "2A58": BLECharacteristic(id: "2A58", emoji: "⏳", description: "Time Stamp"),
        "2A6D": BLECharacteristic(id: "2A6D", emoji: "☀️", description: "Light Intensity"),
        "2A05": BLECharacteristic(id: "2A05", emoji: "🚨", description: "Immediate Alert"),
        "2A69": BLECharacteristic(id: "2A69", emoji: "🧭", description: "Location"),
        "2A76": BLECharacteristic(id: "2A76", emoji: "⚡️", description: "Power Control"),
        "2A2A": BLECharacteristic(id: "2A2A", emoji: "🔐", description: "Security"),
        "2A63": BLECharacteristic(id: "2A63", emoji: "💉", description: "Blood Pressure"),
        "2A9E": BLECharacteristic(id: "2A9E", emoji: "🦶", description: "Step Counter"),
        "2A29": BLECharacteristic(id: "2A29", emoji: "🏭", description: "Manufacturer Name"),
        "2A26": BLECharacteristic(id: "2A26", emoji: "📦", description: "Firmware Revision"),
        "2A27": BLECharacteristic(id: "2A27", emoji: "🔄", description: "Hardware Revision"),
        "2A28": BLECharacteristic(id: "2A28", emoji: "🖥", description: "Software Revision"),
        "2A24": BLECharacteristic(id: "2A24", emoji: "📋", description: "Model Number"),
        "2A25": BLECharacteristic(id: "2A25", emoji: "🔖", description: "Serial Number"),
        "2A00": BLECharacteristic(id: "2A00", emoji: "🏷", description: "Device Name"),
        "2A01": BLECharacteristic(id: "2A01", emoji: "📏", description: "Appearance"),
        "2A04": BLECharacteristic(id: "2A04", emoji: "📶", description: "Connection Parameters"),
        "2A03": BLECharacteristic(id: "2A03", emoji: "🔑", description: "Reconnection Address"),
        "2A06": BLECharacteristic(id: "2A06", emoji: "🔔", description: "Alert Level"),
        "2A08": BLECharacteristic(id: "2A08", emoji: "⏰", description: "Date & Time"),
        "2A0D": BLECharacteristic(id: "2A0D", emoji: "🚴‍♂️", description: "Cycling Power"),
        "2A4D": BLECharacteristic(id: "2A4D", emoji: "🎤", description: "Audio Input"),
        "2A4E": BLECharacteristic(id: "2A4E", emoji: "🔈", description: "Audio Output"),
        "2A7E": BLECharacteristic(id: "2A7E", emoji: "🏋️", description: "Fitness Control"),
        "2A1C": BLECharacteristic(id: "2A1C", emoji: "🫁", description: "Respiratory Rate"),
        "2A40": BLECharacteristic(id: "2A40", emoji: "📡", description: "Location Speed"),
        "2A46": BLECharacteristic(id: "2A46", emoji: "📳", description: "Alert Notification"),
        "2A80": BLECharacteristic(id: "2A80", emoji: "👤", description: "User Profile"),
        "2A85": BLECharacteristic(id: "2A85", emoji: "🔘", description: "Button Pressed"),
        "2A90": BLECharacteristic(id: "2A90", emoji: "👂", description: "Hearing Aid"),
        "2A99": BLECharacteristic(id: "2A99", emoji: "🦵", description: "Body Composition"),
        "2AA7": BLECharacteristic(id: "2AA7", emoji: "🧠", description: "Cognitive Function"),
        "2AA9": BLECharacteristic(id: "2AA9", emoji: "🎮", description: "Game Controller"),
        "2ACD": BLECharacteristic(id: "2ACD", emoji: "🎛", description: "Control Point"),
    ]

    return characteristicMapping[characteristicID] ?? BLECharacteristic(id: characteristicID, emoji: "🔹", description: "Unknown Characteristic")
}

//func getEmojiForCharacteristic(_ characteristicID: String) -> String {
//    let emojiMapping: [String: String] = [
//        "2A19": "🔋", // Battery Level
//        "2A37": "❤️", // Heart Rate Measurement
//        "2A6E": "🌡", // Temperature Measurement
//        "2A98": "💪", // Weight Measurement
//        "2A9D": "🏃‍♂️", // Step Counter
//        "2A56": "💨", // Humidity
//        "2A58": "⏳", // Time Stamp
//        "2A6D": "☀️", // Light Intensity
//        "2A05": "🚨", // Immediate Alert
//        "2A69": "🧭", // Location
//        "2A76": "⚡️", // Power Control
//        "2A2A": "🔐", // Security
//        "2A63": "💉", // Blood Pressure
//        "2A9E": "🦶", // Step Counter
//        "2A29": "🏭", // Manufacturer Name
//        "2A26": "📦", // Firmware Revision
//        "2A27": "🔄", // Hardware Revision
//        "2A28": "🖥", // Software Revision
//        "2A24": "📋", // Model Number
//        "2A25": "🔖", // Serial Number
//        "2A00": "🏷", // Device Name
//        "2A01": "📏", // Appearance
//        "2A04": "📶", // Connection Parameters
//        "2A03": "🔑", // Reconnection Address
//        "2A06": "🔔", // Alert Level
//        "2A08": "⏰", // Date & Time
//        "2A0D": "🚴‍♂️", // Cycling Power
//        "2A4D": "🎤", // Audio Input
//        "2A4E": "🔈", // Audio Output
//        "2A7E": "🏋️", // Fitness Control
//        "2A1C": "🫁", // Respiratory Rate
//        "2A40": "📡", // Location Speed
//        "2A46": "📳", // Alert Notification
//        "2A80": "👤", // User Profile
//        "2A85": "🔘", // Button Pressed
//        "2A90": "👂", // Hearing Aid
//        "2A99": "🦵", // Body Composition
//        "2AA7": "🧠", // Cognitive Function
//        "2AA9": "🎮", // Game Controller
//        "2ACD": "🎛", // Control Point
//    ]
//
//    return emojiMapping[characteristicID] ?? "🔹" // Default Emoji
//}
 
func isUARTDevice(_ peripheral: CBPeripheral) -> Bool {
    let uartServices: Set<CBUUID> = [
        CBUUID(string: "0001"),
        CBUUID(string: "FFE0"),
        CBUUID(string: "49535343-FE7D-4AE5-8FA9-9FAFD205E455"),
        CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    ]
    
    let uartCharacteristics: Set<CBUUID> = [
        CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"),  // TX (Write)
        CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")   // RX (Notify)
    ]
    
    // ✅ First, check if it has a known UART service
    if let services = peripheral.services, services.contains(where: { uartServices.contains($0.uuid) }) {
        return true
    }
    
    // ✅ Then, check if it has both TX (write) and RX (notify) characteristics
    if let services = peripheral.services {
        for service in services {
            if let characteristics = service.characteristics,
               characteristics.contains(where: { uartCharacteristics.contains($0.uuid) }) {
                return true
            }
        }
    }
    
    return false
}

