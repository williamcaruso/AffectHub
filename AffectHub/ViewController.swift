//
//  ViewController.swift
//  AffectHub
//
//  Created by William Caruso on 6/6/18.
//  Copyright © 2018 wcaruso. All rights reserved.
//

import UIKit
import CoreData
import NotificationBannerSwift
import PKHUD
import MessageUI
import Zip

class ViewController: UIViewController {

    var participantName:String = "unknown"
    
    // Bluetooth Device Shared Controllers
    let bioHarness = BioHarness.sharedInstance
    let e4 = E4Controller.sharedInstance
    let affdex = AffdexController.sharedInstance
    let directory = DirectoryModel.sharedInstance

    var leftE4:String!
    var rightE4:String!
    
    // MARK: - Outlets
    @IBOutlet var leftE4Indicator: Circle!
    @IBOutlet var rightE4Indicator: Circle!
    @IBOutlet var bioIndicator: Circle!
    @IBOutlet var affIndicator: Circle!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var subtitleLabel: UILabel!
    
    @IBOutlet var startButton: UIButton!
    @IBOutlet var leftE4ConnectionLabel: UILabel!
    @IBOutlet var rightE4ConnectionLabel: UILabel!
    @IBOutlet var bioConnectionLabel: UILabel!
    
    @IBOutlet var affdexConnectionLabel: UILabel!
    // MARK: - Actions
    @IBAction func connectE4(_ sender: Any) {
        PKHUD.sharedHUD.contentView = PKHUDProgressView()
        PKHUD.sharedHUD.show()
        e4.connect()
    }
    
    @IBAction func connectBioHarness(_ sender: Any) {
        PKHUD.sharedHUD.contentView = PKHUDProgressView()
        PKHUD.sharedHUD.show()
        bioHarness.connect()
    }
    
    @IBAction func startAffdex(_ sender: Any) {
        affdex.start()
    }
    
    @IBAction func startNewSession(_ sender: Any) {
        
        if participantName == nil {
            startButton.setTitle("Stop", for: .normal)
            newParticipant()
        } else {
            affdex.stop()
            bioHarness.disconnect()
            e4.disconnect()
            print("trying to export...")
            exportData()
            startButton.setTitle("Start", for: .normal)
        }
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // authenticate app with Empatica
        
        e4.delegate = self
        e4.connectDelegate = self
        bioHarness.delegate = self
        affdex.delegate = self
        
        e4.authenticate()
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {

    }
    
    override func viewWillDisappear(_ animated: Bool) {

    }
    
    
    func newParticipant(withId id:String) {
        participantName = id
        directory.subjectId = id
        _ = directory.createSubjectDirectory(directoryName: id)
    }
    
    func assignWrists() {
        let names = self.e4.e4.e4Names
        if names.count == 2 {
            let name1 = names.first!
            let name2 = names.last!

            
            let alert = UIAlertController(title: "Which is on the left?",
                                          message: "Select the Empatica E4 ID located on your LEFT wrist",
                                          preferredStyle: .alert)
            
            let action1 = UIAlertAction(title: name1,
                                           style: .default) {
                                            [unowned self] action in
                                            self.beginSavingE4(left: name1, right: name2)
                                            self.leftE4 = name1
                                            self.rightE4 = name2
                                            self.e4.e4.left = name1
                                            self.e4.e4.right = name2
            }
            
            let action2 = UIAlertAction(title: name2,
                                        style: .default) {
                                            [unowned self] action in
                                            self.beginSavingE4(left: name2, right: name1)
                                            self.leftE4 = name2
                                            self.rightE4 = name1
                                            self.e4.e4.left = name2
                                            self.e4.e4.right = name1
            }

            alert.addAction(action1)
            alert.addAction(action2)
            present(alert, animated: true)
        }
    }
    
    func beginSavingE4(left: String, right: String) {
        self.leftE4ConnectionLabel.text = left
        self.rightE4ConnectionLabel.text = right
    }
    
    func exportData() {
        
        directory.saveBHfile()
        print("saved Bh")
        directory.saveE4File()
        print("saved e4")
        directory.saveAffdexFile()
        print("saved affdec")
        
        let paths:[URL] = [directory.BHFilePath!,
                           directory.AffdexFilePath!,
                           directory.leftE4FilePathACC!,
                           directory.leftE4FilePathBVP!,
                           directory.leftE4FilePathGSR!,
                           directory.leftE4FilePathHR!,
                           directory.leftE4FilePathTEMP!,
                           directory.leftE4FilePathTAGS!,
                           directory.leftE4FilePathIBI!,
                           directory.rightE4FilePathACC!,
                           directory.rightE4FilePathBVP!,
                           directory.rightE4FilePathGSR!,
                           directory.rightE4FilePathHR!,
                           directory.rightE4FilePathTEMP!,
                           directory.rightE4FilePathTAGS!,
                           directory.rightE4FilePathIBI! ]
        
        do {
            let zipFilePath = try Zip.quickZipFiles(paths, fileName: "\(participantName)_archive") // Zip
            
            if MFMailComposeViewController.canSendMail() {
                print("can send")
                let emailController = MFMailComposeViewController()
                emailController.mailComposeDelegate = self
                emailController.setToRecipients([])
                emailController.setSubject("AffectHub data export")
                emailController.setMessageBody("Hi,\n\nThe csv data export is attached in the .zip folder \n\n\nSent from the AffectHub app: github.com/williamcaruso/AffectHub", isHTML: false)
                
                
                if let zipdata = NSData(contentsOf: zipFilePath) {
                    emailController.addAttachmentData(zipdata as Data, mimeType: "zip", fileName: "\(participantName)_\(Date().description(with: Locale.current)).zip")
                }

                present(emailController, animated: true, completion: nil)
            } else {
                print("cannot send")
            }
            
        } catch {
            print("Error zipping files")
        }
    }

    
    func newParticipant() {
        let alert = UIAlertController(title: "New Participant",
                                      message: "Add the participant id to continue",
                                      preferredStyle: .alert)
        let saveAction = UIAlertAction(title: "Begin",
                                       style: .default) {
                                        [unowned self] action in
                                        guard let textField = alert.textFields?.first,
                                            let nameToSave = textField.text else {
                                                return
                                        }
                                        self.newParticipant(withId: nameToSave)
                                        self.titleLabel.isHidden = false
                                        self.titleLabel.text = nameToSave
                                        self.subtitleLabel.text = Date().description(with: Locale.current)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel",
                                         style: .default)
        
        alert.addTextField()
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
}

extension ViewController: E4ControllerDelegate, E4ConnectDelegate {
    
    func updateE4Icon(connected: Bool) {
        if connected {
            PKHUD.sharedHUD.contentView = PKHUDSuccessView()
            PKHUD.sharedHUD.hide()
            let names = e4.e4.e4Names
            
            self.assignWrists()
            leftE4Indicator.backgroundColor = .green
            rightE4Indicator.backgroundColor = .green
            
        } else {
            leftE4Indicator.backgroundColor = .red
            rightE4Indicator.backgroundColor = .red
            let banner = NotificationBanner(title: "Empatica E4 Disonnected", subtitle: "Please reconnect both sensors", style: .danger)
            banner.show()
        }
    }
    
    func authSuccess(authenticated: Bool) {
        if authenticated {
            let banner = NotificationBanner(title: "Empatica API Connected", subtitle: "You can now connect sensors associated with the developer account", style: .success)
            banner.show(queuePosition: .front, bannerPosition: .bottom, queue: .default, on: self)
        } else {
            let banner = NotificationBanner(title: "Empatica API Not Connected", subtitle: "Please contact Empatica support or Billy", style: .danger)
            banner.show()
            self.assignWrists()
        }
    }
    
    func E4timeout() {
        PKHUD.sharedHUD.hide()
    }
    
}

extension ViewController: BHDelegate {
    
    func showAlert(message: String) {
        let banner = NotificationBanner(title: "Error", subtitle:message, style: .danger)
        banner.show()
    }
    
    func updateStatusCodes(codes: Dictionary<String, Any>) {
//        print("Update status codes: \(codes)")
    }
    
    func updateBioIcon(connected: Bool) {
        if connected {
            PKHUD.sharedHUD.contentView = PKHUDSuccessView()
            PKHUD.sharedHUD.hide()
            bioIndicator.backgroundColor = .green
            bioConnectionLabel.text = BioHarnessDevice.sensorTagName
        } else {
            PKHUD.sharedHUD.hide()
            bioIndicator.backgroundColor = .red
        }
    }
}

extension ViewController: AffdexControllerDelegate {
    func startDetectedFace() {
        affIndicator.backgroundColor = .green
    }
    
    func stopDetectedFace() {
        affIndicator.backgroundColor = .red
    }
}

extension ViewController: MFMailComposeViewControllerDelegate {
    
}
