
## 🔵 BLE Scanner & Device Manager  

A **Swift-based iOS app** that scans, connects, and interacts with **Bluetooth Low Energy (BLE) devices**. Built using **CoreBluetooth**, this app provides a smooth and interactive experience for discovering, filtering, and managing BLE devices, including UART communication and device details.

![Screenshot](https://github.com/A11egr01/BLEApp/blob/main/Screens/LogoBLE.JPG) 

## 📌 Features

✅ **Scan for BLE devices** and display them in a structured list  
✅ **Filter** devices based on name/type using a `UISegmentedControl`  
✅ **Connect to BLE devices**, including iPhones, Macs, and custom hardware  
✅ **View detailed device information** (advertisement data, services, characteristics)  
✅ **UART Communication** for interacting with supported devices  
✅ **Dynamic UI switching** between **UART console** and **Device Details**  
✅ **Smooth animations** for Bluetooth activity status  
✅ **Pull-to-refresh** for scanning again  

---

## 🛠️ Technologies Used

- **Swift & UIKit** – Core UI framework  
- **CoreBluetooth** – BLE scanning & connectivity  
- **Auto Layout & Storyboards** – Responsive UI  
- **GCD (Grand Central Dispatch)** – Background scanning & async updates  

---

## 🚀 Installation

### 1️⃣ Clone the Repository:
```bash
git clone https://github.com/A11egr01/BLE-Scanner.git
cd BLE-Scanner
```

### 2️⃣ Open in Xcode:
- Open `BLE-Scanner.xcodeproj` in Xcode.
- Make sure you **select a real iOS device** (BLE scanning doesn’t work on the simulator).

### 3️⃣ Run the App:
- Click **Run** ▶️ in Xcode.
- Grant **Bluetooth permissions** when prompted.

---

## 📸 Screenshots

| **Scanning for Devices** | **UART Console** | **GATT Details** |
|---|---|---|
| ![Scan](https://github.com/A11egr01/BLEApp/blob/main/Screens/Home.PNG) | ![UART](https://github.com/A11egr01/BLEApp/blob/main/Screens/UART.PNG) | ![GATT](https://github.com/A11egr01/BLEApp/blob/main/Screens/GATT.PNG) |

---

## 📖 How It Works

### 🔍 Scanning for Devices
- When the app launches, it starts scanning for BLE devices.
- Results are displayed in a `UITableView` with **signal strength (RSSI), manufacturer, and name**.

### 🎚 Filtering Devices
- The **Segmented Control** at the top lets you filter:
  - **Non-Apple devices**
  - **Unnamed devices**
  - **Apple devices (iPhone, iPad, Mac, etc.)**

### 🔗 Connecting to Devices
- Tap a device to connect.
- The app fetches **services & characteristics** and displays them in the **Device Details** view.

### 🖥 Switching Views (UART & GATT)
- The **Segmented Control** at the top allows you to **switch between UART communication and GATT details**.

---

## 🛠 Known Issues & Improvements
- [ ] Occasionally, duplicate devices appear due to different UUIDs.
- [ ] Improve reconnection behavior when a device disconnects.
- [ ] Add **custom commands** for supported devices in the UART console.

---

## 🙌 Contributing
Pull requests are welcome! If you find bugs or have suggestions, **open an issue** or contribute via a PR.  

---

## 🔐 Permissions & Privacy
- The app **requires Bluetooth permissions** (`NSBluetoothAlwaysUsageDescription`).
- No data is collected or transmitted outside the device.

---

## 📜 License
This project is open-source under the **MIT License**.

---


