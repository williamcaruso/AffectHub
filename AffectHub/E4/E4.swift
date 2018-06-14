//
//  E4.swift
//  AffectHub
//
//  Created by William Caruso on 6/6/18.
//  Copyright © 2018 wcaruso. All rights reserved.
//
//  Created by John Politz on 4/26/17.
//  Copyright © 2017 Maurizio Garbarino. All rights reserved.
//

import Foundation

protocol E4Delegate: class {
    func didUpdateE4Status(status: String)
}

class E4:NSObject, EmpaticaDelegate, EmpaticaDeviceDelegate {
    
    let directoryModel = DirectoryModel.sharedInstance

    var e4status: String = ""
    weak var delegate: E4Delegate?
    var e4Names:[String] = []
    
    var left = ""
    var right = ""
    
    func didUpdate(_ status: DeviceStatus, forDevice device: EmpaticaDeviceManager!) {
        switch (status) {
        case kDeviceStatusDisconnected:
            e4status = "Disconnected"
            break;
        case kDeviceStatusConnecting:
            e4status = "Connecting"
            break;
        case kDeviceStatusConnected:
            e4status = "Connected"
            if !e4Names.contains(device.serialNumber) {
                e4Names.append(device.serialNumber)
            }
            break;
        case kDeviceStatusDisconnecting:
            e4status = "Disconnecting"
            break;
        default:
            break;
        }
        
        delegate?.didUpdateE4Status(status: e4status)
    }
    
    func didReceiveTag(atTimestamp timestamp: Double, fromDevice device: EmpaticaDeviceManager!) {
        if device.serialNumber == left {
            directoryModel.leftE4CsvTextTAGS += "\(Date().timeIntervalSince1970),0\n"
        } else if device.serialNumber == right {
            directoryModel.rightE4CsvTextTAGS += "\(Date().timeIntervalSince1970),0\n"
        }
    }
    
    func didReceiveGSR(_ gsr: Float, withTimestamp timestamp: Double, fromDevice device: EmpaticaDeviceManager!) {
        if device.serialNumber == left {
            directoryModel.leftE4CsvTextGSR += "\(Date().timeIntervalSince1970),\(String(describing: gsr))\n"
        } else if device.serialNumber == right {
            directoryModel.rightE4CsvTextGSR += "\(Date().timeIntervalSince1970),\(String(describing: gsr))\n"
        }
    }
    
    func didReceiveBVP(_ bvp: Float, withTimestamp timestamp: Double, fromDevice device: EmpaticaDeviceManager!) {
        if device.serialNumber == left {
            directoryModel.leftE4CsvTextBVP += "\(Date().timeIntervalSince1970),\(String(describing: bvp))\n"
        } else if device.serialNumber == right {
            directoryModel.rightE4CsvTextBVP += "\(Date().timeIntervalSince1970),\(String(describing: bvp))\n"
        }
    }
    
    func didReceiveTemperature(_ temp: Float, withTimestamp timestamp: Double, fromDevice device: EmpaticaDeviceManager!) {
        if device.serialNumber == left {
            directoryModel.leftE4CsvTextTEMP += "\(Date().timeIntervalSince1970),\(String(describing: temp))\n"
        } else if device.serialNumber == right {
            directoryModel.rightE4CsvTextTEMP += "\(Date().timeIntervalSince1970),\(String(describing: temp))\n"
        }
    }
    
    func didReceiveAccelerationX(_ x: Int8, y: Int8, z: Int8, withTimestamp timestamp: Double, fromDevice device: EmpaticaDeviceManager!) {
        if device.serialNumber == left {
            directoryModel.leftE4CsvTextACC += "\(Date().timeIntervalSince1970),\(String(describing: x)),\(String(describing: y)),\(String(describing: z))\n"
        } else if device.serialNumber == right {
            directoryModel.rightE4CsvTextACC += "\(Date().timeIntervalSince1970),\(String(describing: x)),\(String(describing: y)),\(String(describing: z))\n"
        }
    }
    
    func didReceiveIBI(_ ibi: Float, withTimestamp timestamp: Double, fromDevice device: EmpaticaDeviceManager!) {
        if device.serialNumber == left {
            directoryModel.leftE4CsvTextIBI += "\(Date().timeIntervalSince1970),\(String(describing: ibi))\n"
        } else if device.serialNumber == right {
            directoryModel.rightE4CsvTextIBI += "\(Date().timeIntervalSince1970),\(String(describing: ibi))\n"
        }
    }
    
    func didReceiveHR(_ hr: Float, withTimestamp timestamp: Double, fromDevice device: EmpaticaDeviceManager!) {
        if device.serialNumber == left {
            directoryModel.leftE4CsvTextHR += "\(Date().timeIntervalSince1970),\(String(describing: hr))\n"
        } else if device.serialNumber == right {
            directoryModel.rightE4CsvTextHR += "\(Date().timeIntervalSince1970),\(String(describing: hr))\n"
        }
    }
    
    func didReceiveBatteryLevel(_ level: Float, withTimestamp timestamp: Double, fromDevice device: EmpaticaDeviceManager!) {
        // TODO: update UI
    }
    
    func didDiscoverDevices(_ devices: [Any]!) {
        if (devices.count > 0) {
            // consomnect to multiple devices
            if let devices = devices as? [EmpaticaDeviceManager] {
                for device in devices {
                    print(device.serialNumber)
                    if !device.isFaulty && device.allowed {
                        device.connect(with: self)
                    }
                }
            }
        } else {
            print("No device found in range")
            delegate?.didUpdateE4Status(status: "Timeout")
        }
    }
    
    func didUpdate(_ status: BLEStatus) {
        //fix this for BLEStatus
    }
}




