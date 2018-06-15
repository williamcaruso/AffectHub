//
//  TableViewController.swift
//  AffectHub
//
//  Created by William Caruso on 6/15/18.
//  Copyright © 2018 wcaruso. All rights reserved.
//

import UIKit
import Zip
import MessageUI

class TableViewController: UITableViewController, MFMailComposeViewControllerDelegate  {

    let directory = DirectoryModel.sharedInstance
    
    var participants:[String] = []
    var urls:[URL] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        urls = directory.getAllDocuments()
        
        for url in urls {
            participants.append(url.lastPathComponent)
        }
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return participants.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "labelcell", for: indexPath) as! TableViewCell
        cell.title.text = participants[indexPath.row]
        return cell
    }
    

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        exportData(url: urls[indexPath.row], participantName: participants[indexPath.row])
    }
    
    
    
    func exportData(url:URL, participantName:String) {
        
        let paths = [url]
//        let paths:[URL] = [directory.BHFilePath!,
//                           directory.AffdexFilePath!,
//                           directory.leftE4FilePathACC!,
//                           directory.leftE4FilePathBVP!,
//                           directory.leftE4FilePathGSR!,
//                           directory.leftE4FilePathHR!,
//                           directory.leftE4FilePathTEMP!,
//                           directory.leftE4FilePathTAGS!,
//                           directory.leftE4FilePathIBI!,
//                           directory.rightE4FilePathACC!,
//                           directory.rightE4FilePathBVP!,
//                           directory.rightE4FilePathGSR!,
//                           directory.rightE4FilePathHR!,
//                           directory.rightE4FilePathTEMP!,
//                           directory.rightE4FilePathTAGS!,
//                           directory.rightE4FilePathIBI! ]
        
        
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
    
    
    public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}
