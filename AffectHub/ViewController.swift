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

class ViewController: UIViewController {

    var participantName:String!
    
    // Bluetooth Device Shared Controllers
    let bioHarness = BioHarness.sharedInstance
    let e4 = E4Controller.sharedInstance
    let affdex = AffdexController.sharedInstance
    let directory = DirectoryModel.sharedInstance

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
        bioHarness.connect()
    }
    
    @IBAction func startAffdex(_ sender: Any) {
        affdex.start()
    }
    
    @IBAction func startNewSession(_ sender: Any) {
        
        if participantName == nil {
            newParticipant()
            startButton.titleLabel?.text = "Finish"
        } else {
            affdex.stop()
            bioHarness.disconnect()
            e4.disconnect()
            
            exportData()
        }
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // authenticate app with Empatica
        
        e4.delegate = self
        e4.connectDelegate = self
        
        bioHarness.delegate = self
        
        
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
        directory.subjectId = id
        _ = directory.createSubjectDirectory(directoryName: id)
    }
    
    func assignWrists() {
        let names = self.e4.e4.e4Names
        if names.count == 2 {
            let str1 = names.first!
            let str2 = names.last!
            let idx1 = str1.index(str1.endIndex, offsetBy: -6)
            let idx2 = str2.index(str2.endIndex, offsetBy: -6)
            let name1 = String(str1[idx1...])
            let name2 = String(str2[idx2...])
            
            let alert = UIAlertController(title: "Which is on the left?",
                                          message: "Select the Empatica E4 id located on your left wrist",
                                          preferredStyle: .alert)
            
            let action1 = UIAlertAction(title: name1,
                                           style: .default) {
                                            [unowned self] action in
                                            self.beginSavingE4(left: name1, right: name2)

                                            
            }
            
            let action2 = UIAlertAction(title: name2,
                                        style: .default) {
                                            [unowned self] action in
                                            self.beginSavingE4(left: name2, right: name1)
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
        // TODO: save files first, then export CSV
        let activityViewController = UIActivityViewController(activityItems: [directory.BHCsvText, directory.E4CsvText, directory.AffdexCsvText] , applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        self.present(activityViewController, animated: true, completion: nil)
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
                                        self.startButton.isHidden = true
                                        self.titleLabel.isHidden = false
                                        self.subtitleLabel.isHidden = false
                                        self.titleLabel.text = nameToSave
                                        let date = Date()
                                        self.subtitleLabel.text = date.description(with: Locale.current)
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
    
    func updateIcon(connected: Bool) {
        if connected {
            PKHUD.sharedHUD.contentView = PKHUDSuccessView()
            PKHUD.sharedHUD.hide()
            let names = e4.e4.e4Names
            let str1 = names.first!
            let str2 = names.last!
            let idx1 = str1.index(str1.endIndex, offsetBy: -6)
            let idx2 = str2.index(str2.endIndex, offsetBy: -6)
            let name1 = String(str1[idx1...])
            let name2 = String(str2[idx2...])
            
            let banner = NotificationBanner(title: "Empatica E4 Connected", subtitle: "\(name1) and \(name2)", style: .success)
            banner.show()
            self.assignWrists()
            leftE4Indicator.backgroundColor = .green
            rightE4Indicator.backgroundColor = .green
            
        } else {
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
    
}

extension ViewController: BHDelegate {
    
    func showAlert(alert: UIAlertController) {
        present(alert, animated: true)
    }
    
    func updateStatusCodes(codes: Dictionary<String, Any>) {
        
    }
    
    
}
