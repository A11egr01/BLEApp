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
