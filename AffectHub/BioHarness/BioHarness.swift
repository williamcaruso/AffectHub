//
//  ViewController.swift
//  Zephyr BioHarness 3.0
//
//  Created by John Politz, Jr. in Spring 2017
//

import UIKit
import CoreBluetooth

class BioHarness: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    static let sharedInstance = BioHarness()
    let directoryModel = DirectoryModel.sharedInstance
    var delegate:BHDelegate?
    
    var zephyrConnected = false
    
    var centralManager:CBCentralManager!
    var zephyr:CBPeripheral?
    var zephyrCharacteristic:CBCharacteristic?
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    
    func connect() {
        print("Scanning for all devices....")
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }
    
    func disconnect() {
        if let sensorTag = self.zephyr {
            if let z = self.zephyrCharacteristic {
                sensorTag.setNotifyValue(false, for: z)
            }
            centralManager.cancelPeripheralConnection(sensorTag)
        }
        zephyrCharacteristic = nil
    }
    
    func logZephyr(_ data:Data) {
//        print(data)
        //dataArray for 8 bit values
        let dataLength8 = data.count / MemoryLayout<UInt8>.size
        var dataArray8 = [UInt8](repeating: 0, count: dataLength8)
        (data as NSData).getBytes(&dataArray8, length: dataLength8 * MemoryLayout<Int8>.size)
        
        //dataArray16 for 16 bit values
        let dataLength16 = data.count / MemoryLayout<UInt16>.size
        var dataArray16 = [UInt16](repeating: 0, count: dataLength16)
        (data as NSData).getBytes(&dataArray16, length: dataLength16 * MemoryLayout<Int16>.size)
        
        let time = Date().timeIntervalSince1970
        
        var dataDictionary: Dictionary<String, Any> = interpretStatusCode(firstByte: dataArray8[1])
        dataDictionary["heartRate"] = dataArray8[3]
        dataDictionary["heartRateConfidence"] = dataArray8[15]
        dataDictionary["breathingRate"] = dataArray16[2]
        dataDictionary["breathingRateConfidence"] = dataArray8[16]
        dataDictionary["heartRateVariability"] = dataArray16[6]
        dataDictionary["activityLevel"] = dataArray16[5]
        dataDictionary["batteryLevel"] = dataArray8[14]
        dataDictionary["timestamp"] = time
        
        let newLine = "\(String(describing: dataDictionary["timestamp"]!)),\(String(describing: dataDictionary["heartRate"]!)),\(String(describing: dataDictionary["heartRateConfidence"]!)),\(String(describing: dataDictionary["breathingRate"]!)),\(String(describing: dataDictionary["breathingRateConfidence"]!)),\(String(describing: dataDictionary["heartRateVariability"]!)),\(String(describing: dataDictionary["activityLevel"]!)),\(String(describing: dataDictionary["batteryLevel"]!))\n"
        
        directoryModel.BHCsvText += newLine
    }
    
    func interpretStatusCode(firstByte: UInt8) -> Dictionary<String, Any> {
        var results: Dictionary<String, Any> = [:]
        
        let and: UInt8 = 0b00000001
        var byte: UInt8 = firstByte
        var boolArray = [Bool]()
        for _ in 0...7 {
            let result: UInt8 = byte & and
            if(result == 0) {
                boolArray.append(false)
            }
            else {
                boolArray.append(true)
            }
            byte = byte >> 1
        }
        
        if boolArray[0] {
            if boolArray[1] {
                results["deviceWornDetectionLevel"] = "No Confidence"
            } else {
                results["deviceWornDetectionLevel"] = "Low Confidence"
            }
        } else {
            if boolArray[1] {
                results["deviceWornDetectionLevel"] = "High Confidence"
            } else {
                results["deviceWornDetectionLevel"] = "Full Confidence"
            }
        }
        
        if boolArray[4] {
            results["heartRateReliable"] = "No"
        } else {
            results["heartRateReliable"] = "Yes"
        }
        
        if boolArray[5] {
            results["breatingRateReliable"] = "No"
        } else {
            results["breatingRateReliable"] = "Yes"
        }
        
        if boolArray[7] {
            results["heartRateVariabilityReliable"] = "No"
        } else {
            results["heartRateVariabilityReliable"] = "Yes"
        }
        self.delegate?.updateStatusCodes(codes: results)
        return results
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        var showAlert = true
        var message = ""
        
        switch central.state {
        case .poweredOff:
            message = "Bluetooth on this device is currently powered off."
        case .unsupported:
            message = "This device does not support Bluetooth Low Energy."
        case .unauthorized:
            message = "This app is not authorized to use Bluetooth Low Energy."
        case .resetting:
            message = "The BLE Manager is resetting; a state update is pending."
        case .unknown:
            message = "The state of the BLE Manager is unknown."
        case .poweredOn:
            showAlert = false
            message = "Bluetooth LE is turned on and ready for communication."
        }
        
        if showAlert {
            self.delegate?.showAlert(message: message)
        }
    }
    
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
//        print("centralManager didDiscoverPeripheral - CBAdvertisementDataLocalNameKey is \"\(CBAdvertisementDataLocalNameKey)\"")
        
        if let peripheralName = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
//            print("NEXT PERIPHERAL NAME: \(peripheralName)")
//            print("NEXT PERIPHERAL UUID: \(peripheral.identifier.uuidString)")
            
            if peripheralName == BioHarnessDevice.sensorTagName {
//                print("SENSOR TAG FOUND! ADDING NOW!!!")
                
                zephyr = peripheral
                zephyr!.delegate = self
                
                centralManager.connect(zephyr!, options: nil)
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("**** SUCCESSFULLY CONNECTED TO SENSOR TAG!!!")
        zephyrConnected = true
        peripheral.discoverServices(nil)
        central.stopScan()
        self.delegate?.updateBioIcon(connected: true)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("**** CONNECTION TO SENSOR TAG FAILED!!!")
        zephyrConnected = false
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("**** DISCONNECTED FROM SENSOR TAG!!!")
        zephyrConnected = false
        if error != nil {
            print("****** DISCONNECTION DETAILS: \(error!.localizedDescription)")
        }
        zephyr = nil
        self.delegate?.updateBioIcon(connected: false)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error != nil {
            print("ERROR DISCOVERING SERVICES: \(String(describing: error?.localizedDescription))")
            return
        }

        if let services = peripheral.services {
            for service in services {
                if (service.uuid == CBUUID(string: BioHarnessDevice.ZUUID)) {
                    peripheral.discoverCharacteristics(nil, for: service)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if error != nil {
            print("ERROR DISCOVERING CHARACTERISTICS: \(String(describing: error?.localizedDescription))")
            return
        }
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                zephyrCharacteristic = characteristic
                zephyr?.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print("ERROR ON UPDATING VALUE FOR CHARACTERISTIC: \(characteristic) - \(String(describing: error?.localizedDescription))")
            return
        }
        if let dataBytes = characteristic.value {
            logZephyr(dataBytes)
        }
    }
}

protocol BHDelegate {
    func showAlert(message:String)
    func updateStatusCodes(codes: Dictionary<String, Any>)
    func updateBioIcon(connected: Bool)
}
