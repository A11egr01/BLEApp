//
//  knownManufacturers.swift
//  BLEApp
//
//  Created by Allegro on 2/21/25.
//

import Foundation

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

func getEmojiForCharacteristic(_ characteristicID: String) -> String {
    let emojiMapping: [String: String] = [
        "2A19": "🔋", // Battery Level
        "2A37": "❤️", // Heart Rate Measurement
        "2A6E": "🌡", // Temperature Measurement
        "2A98": "💪", // Weight Measurement
        "2A9D": "🏃‍♂️", // Step Counter
        "2A56": "💨", // Humidity
        "2A58": "⏳", // Time Stamp
        "2A6D": "☀️", // Light Intensity
        "2A05": "🚨", // Immediate Alert
        "2A69": "🧭", // Location
        "2A76": "⚡️", // Power Control
        "2A2A": "🔐", // Security
        "2A63": "💉", // Blood Pressure
        "2A9E": "🦶", // Step Counter
        "2A29": "🏭", // Manufacturer Name
        "2A26": "📦", // Firmware Revision
        "2A27": "🔄", // Hardware Revision
        "2A28": "🖥", // Software Revision
        "2A24": "📋", // Model Number
        "2A25": "🔖", // Serial Number
        "2A00": "🏷", // Device Name
        "2A01": "📏", // Appearance
        "2A04": "📶", // Connection Parameters
        "2A03": "🔑", // Reconnection Address
        "2A06": "🔔", // Alert Level
        "2A08": "⏰", // Date & Time
        "2A0D": "🚴‍♂️", // Cycling Power
        "2A4D": "🎤", // Audio Input
        "2A4E": "🔈", // Audio Output
        "2A7E": "🏋️", // Fitness Control
        "2A1C": "🫁", // Respiratory Rate
        "2A40": "📡", // Location Speed
        "2A46": "📳", // Alert Notification
        "2A80": "👤", // User Profile
        "2A85": "🔘", // Button Pressed
        "2A90": "👂", // Hearing Aid
        "2A99": "🦵", // Body Composition
        "2AA7": "🧠", // Cognitive Function
        "2AA9": "🎮", // Game Controller
        "2ACD": "🎛", // Control Point
    ]

    return emojiMapping[characteristicID] ?? "🔹" // Default Emoji
}
