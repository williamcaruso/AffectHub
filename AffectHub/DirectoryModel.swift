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
    
    
    var BHFilePath: URL?
    var BHCsvText: String = "heartRate,heartRateConfidence,breathingRate,breathingRateConfidence,heartRateVariability,activityLevel,batteryLevel,timestamp\n"
    
    var AffdexFilePath: URL?
    var AffdexJSON: String = "{"
    var AffdexCsvFilePath: URL?
    var AffdexCsvText: String = "timestamp,x,y,height,width,p1x,p2x,p3x,p4x,p4x,p6x,p7x,p8x,p9x,p10x,p11x,p12x,p13x,p14x,p15x,p16x,p17x,p18x,p19x,p20x,p21x,p22x,p23x,p24x,p25x,p26x,p27x,p28x,p29x,p30x,p31x,p32x,p33x,p34x,p1y,p2y,p3y,p4y,p4y,p6y,p7y,p8y,p9y,p10y,p11y,p12y,p13y,p14y,p15y,p16y,p17y,p18y,p19y,p20y,p21y,p22y,p23y,p24y,p25y,p26y,p27y,p28y,p29y,p30y,p31y,p32y,p33y,p34y\n"
    
    var leftE4FilePathGSR: URL?
    var leftE4FilePathACC: URL?
    var leftE4FilePathBVP: URL?
    var leftE4FilePathIBI: URL?
    var leftE4FilePathHR: URL?
    var leftE4FilePathTEMP: URL?
    var leftE4FilePathTAGS: URL?
    
    var leftE4CsvTextGSR: String = "timestamp,eda\n"
    var leftE4CsvTextACC: String = "timestamp,x,y,z\n"
    var leftE4CsvTextBVP: String = "timestamp,bvp\n"
    var leftE4CsvTextIBI: String = "timestamp,ibi\n"
    var leftE4CsvTextHR: String = "timestamp,hr\n"
    var leftE4CsvTextTEMP: String = "timestamp,temp\n"
    var leftE4CsvTextTAGS: String = "timestamp,tags\n"
    
    
    var rightE4FilePathGSR: URL?
    var rightE4FilePathACC: URL?
    var rightE4FilePathBVP: URL?
    var rightE4FilePathIBI: URL?
    var rightE4FilePathHR: URL?
    var rightE4FilePathTEMP: URL?
    var rightE4FilePathTAGS: URL?
    
    var rightE4CsvTextGSR: String = "timestamp,eda\n"
    var rightE4CsvTextACC: String = "timestamp,x,y,z\n"
    var rightE4CsvTextBVP: String = "timestamp,bvp\n"
    var rightE4CsvTextIBI: String = "timestamp,ibi\n"
    var rightE4CsvTextHR: String = "timestamp,hr\n"
    var rightE4CsvTextTEMP: String = "timestamp,temp\n"
    var rightE4CsvTextTAGS: String = "timestamp,tags\n"

    
    init() {
        self.rootDirectoryURL = URL.init(fileURLWithPath: "affectHubData", relativeTo: documentsURL)

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
        let filePath = subjectId + "_BH"
        self.BHFilePath = URL.init(fileURLWithPath: filePath + ".csv", relativeTo: subjectDirectoryURL)
        do {
            try BHCsvText.write(to: BHFilePath!, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("Failed to create BH csv file")
            print("\(error)")
        }
        self.BHCsvText = "timestamp,heartRate,heartRateConfidence,breathingRate,breathingRateConfidence,heartRateVariability,activityLevel,batteryLevel\n"
    }
    
    func saveE4File() {
        self.saveE4GSRleft()
        self.saveE4ACCleft()
        self.saveE4BVPleft()
        self.saveE4IBIleft()
        self.saveE4HRleft()
        self.saveE4TEMPleft()
        self.saveE4TAGSleft()
        
        self.saveE4GSRright()
        self.saveE4ACCright()
        self.saveE4BVPright()
        self.saveE4IBIright()
        self.saveE4HRright()
        self.saveE4TEMPright()
        self.saveE4TAGSright()
    }
    
    func saveAffdexFile() {
        AffdexJSON += "}"
        let filePath = subjectId + "_Affectiva"
        self.AffdexFilePath = URL.init(fileURLWithPath: filePath + ".json", relativeTo: subjectDirectoryURL)
        do {
            try AffdexJSON.write(to: AffdexFilePath!, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("Failed to create Affdex JSON file")
            print("\(error)")
        }
        
        let filePathCSV = subjectId + "_AffectivaFacePoints"
        self.AffdexCsvFilePath = URL.init(fileURLWithPath: filePathCSV + ".csv", relativeTo: subjectDirectoryURL)
        do {
            try AffdexCsvText.write(to: AffdexCsvFilePath!, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("Failed to create Affdex Face Point CSV file")
            print("\(error)")
        }

    }
    
    func resetCsvText() {
        self.BHCsvText = "timestamp,heartRateConfidence,breathingRate,breathingRateConfidence,heartRateVariability,activityLevel,batteryLevel\n"
    }
    
    func resetModel() {
        self.BHFilePath = nil
        self.AffdexFilePath = nil
        self.subjectDirectoryURL = nil
    }
    
    
    // Saving E4 Files
    func saveE4GSRleft() {
        let filePath = subjectId + "_E4_left_GSR"
        self.leftE4FilePathGSR = URL.init(fileURLWithPath: filePath + ".csv", relativeTo: subjectDirectoryURL)
        do {
            try leftE4CsvTextGSR.write(to: leftE4FilePathGSR!, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("Failed to create E4 left GSR csv file")
            print("\(error)")
        }
    }
    
    func saveE4ACCleft() {
        let filePath = subjectId + "_E4_left_ACC"
        self.leftE4FilePathACC = URL.init(fileURLWithPath: filePath + ".csv", relativeTo: subjectDirectoryURL)
        do {
            try leftE4CsvTextACC.write(to: leftE4FilePathACC!, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("Failed to create E4 ACC left csv file")
            print("\(error)")
        }
    }
    
    func saveE4BVPleft() {
        let filePath = subjectId + "_E4_left_BVP"
        self.leftE4FilePathBVP = URL.init(fileURLWithPath: filePath + ".csv", relativeTo: subjectDirectoryURL)
        do {
            try leftE4CsvTextBVP.write(to: leftE4FilePathBVP!, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("Failed to create E4 left BVP csv file")
            print("\(error)")
        }
    }
    
    
    func saveE4IBIleft() {
        let filePath = subjectId + "_E4_left_IBI"

        self.leftE4FilePathIBI = URL.init(fileURLWithPath: filePath + ".csv", relativeTo: subjectDirectoryURL)
        do {
            try leftE4CsvTextIBI.write(to: leftE4FilePathIBI!, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("Failed to create E4 left IBI csv file")
            print("\(error)")
        }
    }
    
    
    func saveE4HRleft() {
        let filePath = subjectId + "_E4_left_HR"

        self.leftE4FilePathHR = URL.init(fileURLWithPath: filePath + ".csv", relativeTo: subjectDirectoryURL)
        do {
            try leftE4CsvTextHR.write(to: leftE4FilePathHR!, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("Failed to create E4 left HR csv file")
            print("\(error)")
        }
    }
    
    
    func saveE4TEMPleft() {
        let filePath = subjectId + "_E4_left_TEMP"
        self.leftE4FilePathTEMP = URL.init(fileURLWithPath: filePath + ".csv", relativeTo: subjectDirectoryURL)
        do {
            try leftE4CsvTextTEMP.write(to: leftE4FilePathTEMP!, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("Failed to create E4 left TEMP csv file")
            print("\(error)")
        }
    }
    
    
    func saveE4TAGSleft() {
        let filePath = subjectId + "_E4_left_TAGS"
        self.leftE4FilePathTAGS = URL.init(fileURLWithPath: filePath + ".csv", relativeTo: subjectDirectoryURL)
        do {
            try leftE4CsvTextTAGS.write(to: leftE4FilePathTAGS!, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("Failed to create E4 left TAGS csv file")
            print("\(error)")
        }
    }
    
    func saveE4GSRright() {
        let filePath = subjectId + "_E4_right_GSR"
        self.rightE4FilePathGSR = URL.init(fileURLWithPath: filePath + ".csv", relativeTo: subjectDirectoryURL)
        do {
            try rightE4CsvTextGSR.write(to: rightE4FilePathGSR!, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("Failed to create E4 right GSR csv file")
            print("\(error)")
        }
    }
    
    func saveE4ACCright() {
        let filePath = subjectId + "_E4_right_ACC"
        self.rightE4FilePathACC = URL.init(fileURLWithPath: filePath + ".csv", relativeTo: subjectDirectoryURL)
        do {
            try rightE4CsvTextACC.write(to: rightE4FilePathACC!, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("Failed to create E4 ACC right csv file")
            print("\(error)")
        }
    }
    
    func saveE4BVPright() {
        let filePath = subjectId + "_E4_right_BVP"
        self.rightE4FilePathBVP = URL.init(fileURLWithPath: filePath + ".csv", relativeTo: subjectDirectoryURL)
        do {
            try rightE4CsvTextBVP.write(to: rightE4FilePathBVP!, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("Failed to create E4 right BVP csv file")
            print("\(error)")
        }
    }
    
    
    func saveE4IBIright() {
        let filePath = subjectId + "_E4_right_IBI"
        self.rightE4FilePathIBI = URL.init(fileURLWithPath: filePath + ".csv", relativeTo: subjectDirectoryURL)
        do {
            try rightE4CsvTextIBI.write(to: rightE4FilePathIBI!, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("Failed to create E4 right IBI csv file")
            print("\(error)")
        }
    }
    
    
    func saveE4HRright() {
        let filePath = subjectId + "_E4_right_HR"
        self.rightE4FilePathHR = URL.init(fileURLWithPath: filePath + ".csv", relativeTo: subjectDirectoryURL)
        do {
            try rightE4CsvTextHR.write(to: rightE4FilePathHR!, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("Failed to create E4 right HR csv file")
            print("\(error)")
        }
    }
    
    
    func saveE4TEMPright() {
        let filePath = subjectId + "_E4_right_TEMP"
        self.rightE4FilePathTEMP = URL.init(fileURLWithPath: filePath + ".csv", relativeTo: subjectDirectoryURL)
        do {
            try rightE4CsvTextTEMP.write(to: rightE4FilePathTEMP!, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("Failed to create E4 right TEMP csv file")
            print("\(error)")
        }
    }
    
    
    func saveE4TAGSright() {
        let filePath = subjectId + "_E4_right_TAGS"
        self.rightE4FilePathTAGS = URL.init(fileURLWithPath: filePath + ".csv", relativeTo: subjectDirectoryURL)
        do {
            try rightE4CsvTextTAGS.write(to: rightE4FilePathTAGS!, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("Failed to create E4 right TAGS csv file")
            print("\(error)")
        }
    }
    
    func getAllDocuments() -> [URL] {
        let fileManager = FileManager.default
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: self.rootDirectoryURL, includingPropertiesForKeys: nil)
            
            // process files
            return fileURLs
            print("File URLS: \(fileURLs)")
        } catch {
            print("Error while enumerating files \(documentsURL.path): \(error.localizedDescription)")
        }
        return []
    }
    
}

