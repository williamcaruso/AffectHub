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
    
    func didUpdate(_ status: DeviceStatus, forDevice device: EmpaticaDeviceManager!) {
        switch (status) {
        case kDeviceStatusDisconnected:
            e4status = "Disconnected"
            print(e4status)
            break;
        case kDeviceStatusConnecting:
            e4status = "Connecting"
            print(e4status)
            break;
        case kDeviceStatusConnected:
            e4status = "Connected"
            print(e4status)
            if !e4Names.contains(device.name) {
                e4Names.append(device.name)
            }
            break;
        case kDeviceStatusDisconnecting:
            e4status = "Disconnecting"
            print(e4status)
            break;
        default:
            break;
        }
        
        delegate?.didUpdateE4Status(status: e4status)
    }
    
    func didReceiveTag(atTimestamp timestamp: Double, fromDevice device: EmpaticaDeviceManager!) {
        directoryModel.E4CsvText += "\(String(describing: timestamp)),tag,0\n"
    }
    
    func didReceiveGSR(_ gsr: Float, withTimestamp timestamp: Double, fromDevice device: EmpaticaDeviceManager!) {
        directoryModel.E4CsvText += "\(String(describing: timestamp)),gsr,\(String(describing: gsr))\n"
    }
    
    func didReceiveBVP(_ bvp: Float, withTimestamp timestamp: Double, fromDevice device: EmpaticaDeviceManager!) {
        directoryModel.E4CsvText += "\(String(describing: timestamp)),bvp,\(String(describing: bvp))\n"
    }
    
    func didReceiveTemperature(_ temp: Float, withTimestamp timestamp: Double, fromDevice device: EmpaticaDeviceManager!) {
        directoryModel.E4CsvText += "\(String(describing: timestamp)),temperature,\(String(describing: temp))\n"
        
    }
    
    func didReceiveAccelerationX(_ x: Int8, y: Int8, z: Int8, withTimestamp timestamp: Double, fromDevice device: EmpaticaDeviceManager!) {
        directoryModel.E4CsvText += "\(String(describing: timestamp)),x,\(String(describing: x))\n\(String(describing: timestamp)),y,\(String(describing: y))\n\(String(describing: timestamp)),z,\(String(describing: z))\n"
    }
    
    func didReceiveIBI(_ ibi: Float, withTimestamp timestamp: Double, fromDevice device: EmpaticaDeviceManager!) {
        directoryModel.E4CsvText += "\(String(describing: timestamp)),ibi,\(String(describing: ibi))\n"
    }
    
    func didReceiveHR(_ hr: Float, withTimestamp timestamp: Double, fromDevice device: EmpaticaDeviceManager!) {
        directoryModel.E4CsvText += "\(String(describing: timestamp)),hr,\(String(describing: hr))\n"
    }
    
    func didReceiveBatteryLevel(_ level: Float, withTimestamp timestamp: Double, fromDevice device: EmpaticaDeviceManager!) {
        directoryModel.E4CsvText += "\(String(describing: timestamp)),battery,\(String(describing: level))\n"
    }
    
    func didDiscoverDevices(_ devices: [Any]!) {
        if (devices.count > 0) {
            // consomnect to multiple devices
            if let devices = devices as? [EmpaticaDeviceManager] {
                for device in devices {
                    print(device.name)
                    if !device.isFaulty && device.allowed {
                        device.connect(with: self)
                    }
                }
            }
        } else {
            print("No device found in range")
        }
    }
    
    func didUpdate(_ status: BLEStatus) {
        //fix this for BLEStatus
    }
}




