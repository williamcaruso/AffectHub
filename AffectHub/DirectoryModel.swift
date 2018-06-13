//
//  DirectoryModel.swift
//  Cardiac
//
//  Created by Eileen Guo on 3/29/17.
//  Copyright © 2017 Eileen Guo. All rights reserved.
//

import UIKit

class DirectoryModel {
    
    static let sharedInstance = DirectoryModel()
    var subjectId:String = "SUBJECT_ID"
    let documentsURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    var rootDirectoryURL: URL
    var subjectDirectoryURL: URL?
    
    // Times will be updated if video is recorded
    var trialStartTime = NSDate().timeIntervalSince1970
    var trialEndTime = NSDate().timeIntervalSince1970
    
    
    var E4FilePath: URL?
    var BHFilePath: URL?
    var AffdexFilePath: URL?

    var BHCsvText: String = "heartRate,heartRateConfidence,breathingRate,breathingRateConfidence,heartRateVariability,activityLevel,batteryLevel,timestamp\n"
    var E4CsvText: String = "timestamp,type,value\n"
    var AffdexCsvText: String = "timestamp,type,value\n"

    
    init() {
        self.rootDirectoryURL = URL.init(fileURLWithPath: "affectHubData", relativeTo: documentsURL)
        self.E4FilePath = URL.init(fileURLWithPath: "affectHubData", relativeTo: documentsURL)
        self.BHFilePath = URL.init(fileURLWithPath: "affectHubData", relativeTo: documentsURL)
        self.AffdexFilePath = URL.init(fileURLWithPath: "affectHubData", relativeTo: documentsURL)

        do {
            // Get the directory contents urls (including subfolders urls)
            let directoryContents = try FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil, options: [])
            if directoryContents.count == 0 {
                try FileManager.default.createDirectory(at: rootDirectoryURL, withIntermediateDirectories: true, attributes: nil)
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }
    
    
    //Creates subject's root directory (can overwrite previously created directories)
    func createSubjectDirectory(directoryName: String, overwriteExistingSession overwrite: Bool = false)
        -> (success: Bool, error: String)? {
            print("rootDirectoryURL" + rootDirectoryURL.path)
            let newURL = URL.init(fileURLWithPath: "affectHubData/" + directoryName, relativeTo: documentsURL)
            let subjectAlreadyExists = FileManager.default.fileExists(atPath: newURL.path)
            createDirectory: do {
                if subjectAlreadyExists {
                    if overwrite {
                        try FileManager.default.removeItem(at: newURL)
                    } else {
                        print("SubjectID has already been used. Using existing directory")
                        break createDirectory
                    }
                }
                try FileManager.default.createDirectory(at: newURL, withIntermediateDirectories: false, attributes: nil)
            } catch let error as NSError {
                print(error.localizedDescription)
                return (false, "Error creating/deleting directory")
            }
            
            self.subjectDirectoryURL = URL.init(fileURLWithPath: newURL.path)
            return nil
    }
    
    //Saving Subject's MetadataFile
    func finishSubjectSession() {
        resetModel()
    }
    
    
    func saveBHfile() {
        let filePath = subjectId + "BH"
        var version = 0
        repeat {
            version += 1
            self.BHFilePath = URL.init(fileURLWithPath: filePath + String(version) + ".csv", relativeTo: subjectDirectoryURL)
        } while FileManager.default.fileExists(atPath: self.BHFilePath!.path)
        do {
            try BHCsvText.write(to: BHFilePath!, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("Failed to create BH csv file")
            print("\(error)")
        }
        self.BHCsvText = "heartRate,heartRateConfidence,breathingRate,breathingRateConfidence,heartRateVariability,activityLevel,batteryLevel,timestamp\n"
    }
    
    func saveE4File() {
        let filePath = subjectId + "E4"
        var version = 0
        repeat {
            version += 1
            self.E4FilePath = URL.init(fileURLWithPath: filePath + String(version) + ".csv", relativeTo: subjectDirectoryURL)
        } while FileManager.default.fileExists(atPath: self.E4FilePath!.path)
        do {
            try E4CsvText.write(to: E4FilePath!, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("Failed to create E4 csv file")
            print("\(error)")
        }
        self.E4CsvText = "timestamp,type,value\n"
    }
    
    func saveAffdexFile() {
        let filePath = subjectId + "AFDX"
        var version = 0
        repeat {
            version += 1
            self.AffdexFilePath = URL.init(fileURLWithPath: filePath + String(version) + ".csv", relativeTo: subjectDirectoryURL)
        } while FileManager.default.fileExists(atPath: self.E4FilePath!.path)
        do {
            try AffdexCsvText.write(to: AffdexFilePath!, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("Failed to create Affdex csv file")
            print("\(error)")
        }
        self.AffdexCsvText = "timestamp,type,value\n"
    }
    
    func resetCsvText() {
        self.BHCsvText = "heartRateConfidence,breathingRate,breathingRateConfidence,heartRateVariability,activityLevel,batteryLevel,timestamp\n"
        self.E4CsvText = "timestamp,type,value\n"
    }
    
    func resetModel() {
        self.BHCsvText = "heartrate,heartRateConfidence,breathingRate,breathingRateConfidence,heartRateVariability,activityLevel,batteryLevel,timestamp\n"
        self.BHFilePath = nil
        self.E4CsvText = "timestamp,type,value\n"
        self.E4FilePath = nil
        self.AffdexCsvText = "timestamp,type,value\n"
        self.AffdexFilePath = nil
        self.subjectDirectoryURL = nil
    }
}

